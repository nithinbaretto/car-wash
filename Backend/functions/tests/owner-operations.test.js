const test = require("node:test");
const assert = require("node:assert/strict");
const {db} = require("../src/config/firebase");
const {mergeAvailability} = require("../src/services/availability");
const operations = require("../src/routes/owner-operations");
const bookings = require("../src/routes/bookings");
const ownerShops = require("../src/routes/owner-shops");
const slot = {startAt: "10:00", endAt: "11:00", capacity: 2, bookedCount: 1, enabled: true};
const inputSlot = {startAt: "10:00", endAt: "11:00", capacity: 2, enabled: true};

test("availability preserves reservations and validates slot replacement", () => {
  assert.equal(mergeAvailability([inputSlot], [slot])[0].bookedCount, 1);
  for (const input of [[], [{...inputSlot, capacity: 1}]]) {
    assert.throws(() => mergeAvailability(input, [{...slot, bookedCount: 2}]), {code: "AVAILABILITY_CONFLICT"});
  }
  assert.throws(() => mergeAvailability([{...inputSlot, endAt: "10:30"}], [slot]), {code: "AVAILABILITY_CONFLICT"});
  assert.throws(() => mergeAvailability([inputSlot, inputSlot], []), {code: "VALIDATION_ERROR"});
  assert.throws(() => mergeAvailability([{...inputSlot, enabled: "yes"}], []), {code: "VALIDATION_ERROR"});
  assert.deepEqual(mergeAvailability([], [{...slot, bookedCount: 0}]), []);
});

function fakeDatabase(t) {
  let sequence = 0;
  const records = new Map([
    ["users/owner", {roles: ["owner"], accountStatus: "active"}],
    ["carWashes/shop", {name: "Wash", status: "active", ownerUids: ["owner"], address: {area: "Centre", city: "Pune"}}],
    ["carWashes/shop/services/service", {name: "Quick", category: "quick", priceMinor: 15000, durationMinutes: 30, active: true}],
    ["carWashes/shop/availability/2026-09-30", {slots: [{...slot}]}],
  ]);
  const snapshot = (ref) => ({ref, id: ref.id, exists: records.has(ref.path), data: () => records.get(ref.path)});
  const collection = (path) => ({doc: (id = `generated-${++sequence}`) => doc(`${path}/${id}`)});
  const doc = (path) => ({path, id: path.split("/").at(-1), collection: (name) => collection(`${path}/${name}`), get: async () => snapshot(doc(path))});
  t.mock.method(db, "collection", collection);
  t.mock.method(db, "runTransaction", async (callback) => {
    const writes = [];
    const result = await callback({get: async (ref) => snapshot(ref),
      update: (ref, value) => writes.push(() => records.set(ref.path, {...records.get(ref.path), ...value})),
      create: (ref, value) => writes.push(() => {assert.ok(!records.has(ref.path)); records.set(ref.path, value);}),
      set: (ref, value) => writes.push(() => records.set(ref.path, value)),
    });
    writes.forEach((write) => write()); return result;
  });
  return records;
}
async function invoke(router, path, {body = {}, params = {carWashId: "shop"}, query = {}, key = "walkin-1"} = {}) {
  const handler = router.stack.find((layer) => layer.route?.path === path).route.stack.at(-1).handle;
  let result; let error; let status = 200;
  const response = {status(value) {status = value; return this;}, json(value) {result = value; return this;}};
  await handler({auth: {uid: "owner"}, body, params, query, get: () => key, requestId: "test"}, response, (value) => {error = value;});
  return {result, error, status};
}
const walkInPath = "/v1/owner/car-washes/:carWashId/walk-ins";
const walkInBody = {customerName: "Guest", vehicle: "MH12 AB1234", serviceId: "service", date: "2026-09-30", startAt: "10:00"};

test("walk-ins reserve once, reject key reuse/full capacity and complete without guest notifications", async (t) => {
  const records = fakeDatabase(t);
  const created = await invoke(operations, walkInPath, {body: walkInBody});
  assert.equal(created.error, undefined); assert.equal(created.status, 201);
  assert.equal(created.result.data.booking.status, "accepted");
  assert.equal(created.result.data.booking.customer.displayName, "Guest");
  assert.equal(created.result.data.booking.vehicle.registrationNumber, "MH12 AB1234");
  const repeated = await invoke(operations, walkInPath, {body: walkInBody});
  assert.equal(repeated.status, 200); assert.equal(repeated.result.data.booking.id, created.result.data.booking.id);
  assert.equal(records.get("carWashes/shop/availability/2026-09-30").slots[0].bookedCount, 2);
  assert.equal((await invoke(operations, walkInPath, {body: {...walkInBody, customerName: "Other"}})).error.code, "IDEMPOTENCY_KEY_REUSED");
  assert.equal((await invoke(operations, walkInPath, {body: walkInBody, key: "second"})).error.code, "SLOT_UNAVAILABLE");
  for (const status of ["in_progress", "completed"]) {
    const updated = await invoke(bookings, "/v1/owner/bookings/:bookingId/status", {params: {bookingId: created.result.data.booking.id}, body: {status}});
    assert.equal(updated.error, undefined); assert.equal(updated.result.data.booking.status, status);
  }
  assert.ok(![...records.keys()].some((key) => key.startsWith("notifications/")));
});

test("owner operations enforce ownership and validate walk-in requests", async (t) => {
  const records = fakeDatabase(t);
  assert.equal((await invoke(operations, walkInPath, {body: walkInBody, key: ""})).error.code, "VALIDATION_ERROR");
  assert.equal((await invoke(operations, walkInPath, {body: {...walkInBody, serviceId: "bad/id"}})).error.code, "VALIDATION_ERROR");
  records.get("carWashes/shop").ownerUids = ["another-owner"];
  for (const path of [walkInPath, "/v1/owner/car-washes/:carWashId/services", "/v1/owner/car-washes/:carWashId/availability", "/v1/owner/car-washes/:carWashId/earnings"]) {
    assert.equal((await invoke(operations, path, {body: walkInBody, query: {date: "2026-09-30"}})).error.code, "SHOP_ACCESS_DENIED");
  }
});

test("availability route retains booked counts transactionally and rejects reserved removal", async (t) => {
  const records = fakeDatabase(t);
  const params = {carWashId: "shop", date: "2026-09-30"};
  const path = "/v1/owner/car-washes/:carWashId/availability/:date";
  const response = await invoke(ownerShops, path, {params, body: {slots: [inputSlot]}});
  assert.equal(response.error, undefined); assert.equal(response.result.data.slots[0].bookedCount, 1);
  assert.equal((await invoke(ownerShops, path, {params, body: {slots: []}})).error.code, "AVAILABILITY_CONFLICT");
  assert.equal(records.get("carWashes/shop/availability/2026-09-30").slots[0].bookedCount, 1);
});

test("earnings use IST completion-day boundaries and a trailing seven-day aggregate", async (t) => {
  const filters = [];
  t.mock.method(db, "collection", (name) => {
    if (name !== "bookings") return {doc: () => ({get: async () => ({exists: true, data: () => name === "users" ? {roles: ["owner"]} : {ownerUids: ["owner"]}})})};
    const clauses = []; filters.push(clauses);
    const query = {where(...args) {clauses.push(args); return this;}, aggregate() {return {get: async () => ({data: () => ({amount: clauses[2][2].toDate().getUTCDate() === 29 ? 1000 : 3000, count: 2})})};}};
    return query;
  });
  const result = await invoke(operations, "/v1/owner/car-washes/:carWashId/earnings", {query: {date: "2026-09-30"}});
  assert.equal(result.error, undefined); assert.equal(result.result.data.earnings.todayMinor, 1000); assert.equal(result.result.data.earnings.weekMinor, 3000);
  assert.deepEqual(filters[0].slice(0, 2), [["carWashId", "==", "shop"], ["status", "==", "completed"]]);
  assert.equal(filters[0][2][2].toDate().toISOString(), "2026-09-29T18:30:00.000Z");
  assert.equal(filters[0][3][2].toDate().toISOString(), "2026-09-30T18:30:00.000Z");
  assert.equal(filters[1][2][2].toDate().toISOString(), "2026-09-23T18:30:00.000Z");
});

test("admin dashboard returns actual seven-day scheduled counts", async (t) => {
  const adminRouter = require("../src/routes/admin");
  t.mock.method(db, "collection", () => {
    const query = {
      doc: () => ({get: async () => ({exists: false})}),
      where(field, operator, value) {
        if (field === "availabilityDate") return {count: () => ({get: async () => ({data: () => ({count: Number(value.slice(-2))})})})};
        return query;
      },
      count: () => ({get: async () => ({data: () => ({count: 5})})}),
    };
    return query;
  });
  const handler = adminRouter.stack.find((layer) => layer.route?.path === "/v1/admin/dashboard").route.stack.at(-1).handle;
  let result; let error;
  await handler({auth: {uid: "admin", superAdmin: true}, requestId: "test"}, {json: (value) => {result = value;}}, (value) => {error = value;});
  assert.equal(error, undefined);
  assert.equal(result.data.weeklyBookings.length, 7);
  const today = new Date().toLocaleDateString("en-CA", {timeZone: "Asia/Kolkata"});
  assert.equal(result.data.weeklyBookings.at(-1).date, today);
  assert.equal(result.data.todayBookings, Number(today.slice(-2)));
  for (const item of result.data.weeklyBookings) assert.equal(item.bookings, Number(item.date.slice(-2)));
});
