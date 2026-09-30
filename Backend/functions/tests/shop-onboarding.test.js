const test = require("node:test");
const assert = require("node:assert/strict");
const {db} = require("../src/config/firebase");
const {validateOnboarding, inspectOnboarding} = require("../src/services/shop-onboarding");
const router = require("../src/routes/shop-onboarding");
const adminRouter = require("../src/routes/admin");
const ownerRouter = require("../src/routes/owner-shops");
const date = new Date(Date.now() + 3 * 86400000).toISOString().slice(0, 10);
const body = () => ({name: "Clean Wash", contactPhone: "+919876543210", address: {line1: "Main street", area: "Centre", city: "Pune", state: "Maharashtra", postalCode: "411001", formattedAddress: "Main street, Pune"}, location: {latitude: 18.5, longitude: 73.8}, categories: ["quick"], services: [{name: "Quick wash", category: "quick", priceMinor: 15000, durationMinutes: 30}], availability: [{date, slots: [{startAt: "10:00", endAt: "11:00", capacity: 2, enabled: true}]}]});
function database(t) {
  let id = 0;
  const records = new Map([["users/owner", {roles: ["owner"], accountStatus: "active"}]]);
  const snapshot = (ref) => ({id: ref.id, ref, exists: records.has(ref.path), data: () => records.get(ref.path)});
  const query = (path, filters = [], max = Infinity) => ({path, filters, max,
    doc(value) {
      assert.ok(arguments.length === 0 || typeof value === "string", "Firestore doc expects no argument or a string path");
      return doc(`${path}/${arguments.length ? value : `id-${++id}`}`);
    },
    where: (field, op, value) => query(path, [...filters, [field, op, value]], max),
    limit: (value) => query(path, filters, value),
    get: async () => read(query(path, filters, max)),
  });
  const doc = (path) => ({path, id: path.split("/").at(-1), collection: (name) => query(`${path}/${name}`), get: async () => snapshot(doc(path))});
  const read = (ref) => ref.filters ? {docs: [...records.keys()].filter((key) => key.startsWith(`${ref.path}/`) && !key.slice(ref.path.length + 1).includes("/")).filter((key) => ref.filters.every(([field, op, value]) => op === ">=" ? records.get(key)[field] >= value : records.get(key)[field] === value)).slice(0, ref.max).map((key) => snapshot(doc(key)))} : snapshot(ref);
  t.mock.method(db, "collection", query);
  let failCommit = false;
  t.mock.method(db, "runTransaction", async (callback) => {
    const writes = [];
    const result = await callback({get: async (ref) => read(ref),
      set: (ref, value) => writes.push(() => records.set(ref.path, value)),
      create: (ref, value) => writes.push(() => {assert.ok(!records.has(ref.path)); records.set(ref.path, value);}),
      update: (ref, value) => writes.push(() => records.set(ref.path, {...records.get(ref.path), ...value})),
      delete: (ref) => writes.push(() => records.delete(ref.path)),
    });
    if (failCommit) throw new Error("commit failed");
    writes.forEach((write) => write()); return result;
  });
  return {records, fail(value) {failCommit = value;}};
}
async function invoke(target, method, path, {payload = {}, carWashId, key = "submission", superAdmin = false, uid = "owner"} = {}) {
  const route = target.stack.find((layer) => layer.route?.path === path && layer.route.methods[method]).route;
  let result; let error; let status = 200;
  await route.stack.at(-1).handle({auth: {uid, superAdmin}, params: {carWashId}, body: payload, requestId: "test", get: () => key}, {status(value) {status = value; return this;}, json(value) {result = value; return this;}}, (value) => {error = value;});
  return {result, error, status};
}
const create = (args) => invoke(router, "post", "/v1/owner/car-washes/onboarding", args);
const update = (args) => invoke(router, "put", "/v1/owner/car-washes/:carWashId/onboarding", args);

test("validates real coordinates, service prices/categories/duration and future usable availability", () => {
  assert.ok(validateOnboarding(body()));
  for (const change of [
    (x) => x.location.latitude = NaN,
    (x) => x.location.longitude = Infinity,
    (x) => x.services[0].priceMinor = 0,
    (x) => x.services[0].durationMinutes = 120,
    (x) => x.services[0].category = "premium",
    (x) => x.categories.push("interior"),
    (x) => x.availability[0].slots.push({startAt: "10:30", endAt: "11:30", capacity: 1}),
    (x) => x.services[0].active = false,
    (x) => x.availability[0].slots[0].enabled = false,
    (x) => x.availability[0].date = "2000-01-01",
    (x) => x.contactPhone = "not a phone",
  ]) {const input = body(); change(input); assert.throws(() => validateOnboarding(input));}
  const validated = validateOnboarding(body());
  assert.equal(inspectOnboarding(validated.shop, validated.services, validated.availability, new Date(`${date}T12:00:00+05:30`)).complete, false);
});

test("onboarding commits atomically, replays once, protects key reuse and retries failed commits", async (t) => {
  const dbState = database(t); const payload = body();
  dbState.fail(true);
  assert.match((await create({payload})).error.message, /commit failed/);
  assert.equal(dbState.records.size, 1);
  dbState.fail(false);
  const first = await create({payload}); assert.equal(first.error, undefined); assert.equal(first.status, 201);
  const shop = first.result.data.carWash;
  assert.equal(shop.status, "pending_review"); assert.equal(shop.location.latitude, 18.5);
  const again = await create({payload}); assert.equal(again.status, 200); assert.equal(again.result.data.carWash.id, shop.id);
  assert.equal([...dbState.records.keys()].filter((key) => /^carWashes\/[^/]+$/.test(key)).length, 1);
  assert.equal((await create({payload: {...payload, name: "Other Wash"}})).error.code, "IDEMPOTENCY_KEY_REUSED");
  assert.equal((await create({payload, key: ""})).error.code, "VALIDATION_ERROR");
});

test("rejected onboarding can be repaired once without duplicate services and cannot overwrite active/foreign shops", async (t) => {
  const {records} = database(t);
  const carWashId = (await create({payload: body()})).result.data.carWash.id;
  records.get(`carWashes/${carWashId}`).status = "rejected";
  records.get(`carWashes/${carWashId}`).review = {reason: "Fix details"};
  const detail = await invoke(router, "get", "/v1/owner/car-washes/:carWashId/onboarding", {carWashId});
  assert.equal(detail.result.data.carWash.review.reason, "Fix details"); assert.equal(detail.result.data.onboarding.complete, true);
  const payload = body(); payload.services[0].priceMinor = 20000;
  const updated = await update({payload, carWashId, key: "repair"}); assert.equal(updated.error, undefined);
  assert.equal(updated.result.data.carWash.status, "pending_review");
  assert.equal((await update({payload, carWashId, key: "repair"})).error, undefined);
  assert.equal([...records.keys()].filter((key) => key.startsWith(`carWashes/${carWashId}/services/`)).length, 1);
  records.get(`carWashes/${carWashId}`).status = "active";
  assert.equal((await update({payload, carWashId, key: "active-repair"})).error.code, "SHOP_ONBOARDING_LOCKED");
  records.get(`carWashes/${carWashId}`).ownerUids = ["other"];
  assert.equal((await update({payload, carWashId, key: "other-repair"})).error.code, "SHOP_ACCESS_DENIED");
});

test("approval and legacy resubmission reject incomplete shops; complete submissions approve", async (t) => {
  const {records} = database(t);
  const carWashId = (await create({payload: body()})).result.data.carWash.id;
  const serviceKey = [...records.keys()].find((key) => key.startsWith(`carWashes/${carWashId}/services/`));
  const service = records.get(serviceKey); records.delete(serviceKey);
  const review = (decision) => invoke(adminRouter, "post", "/v1/admin/car-washes/:carWashId/review", {carWashId, superAdmin: true, payload: {decision}});
  assert.equal((await review("approve")).error.code, "SHOP_ONBOARDING_INCOMPLETE");
  records.get(`carWashes/${carWashId}`).status = "rejected";
  assert.equal((await invoke(ownerRouter, "post", "/v1/owner/car-washes/:carWashId/resubmit", {carWashId})).error.code, "SHOP_ONBOARDING_INCOMPLETE");
  records.set(serviceKey, service);
  assert.equal((await invoke(ownerRouter, "post", "/v1/owner/car-washes/:carWashId/resubmit", {carWashId})).error, undefined);
  assert.equal((await review("approve")).error, undefined);
  assert.equal(records.get(`carWashes/${carWashId}`).status, "active");
});
