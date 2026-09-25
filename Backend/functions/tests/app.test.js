const test = require("node:test");
const assert = require("node:assert/strict");
const {once} = require("node:events");
const app = require("../src/app");

const expectedRoutes = [
  "post /v1/me/owner-enrollment",
  "delete /v1/me/devices/:installationId",
  "get /health",
  "post /v1/me/onboarding",
  "get /v1/me",
  "patch /v1/me",
  "put /v1/me/active-role",
  "post /v1/me/devices",
  "get /v1/categories",
  "get /v1/car-washes/nearby",
  "get /v1/car-washes/:carWashId/availability",
  "get /v1/car-washes/:carWashId",
  "get /v1/me/favourites",
  "put /v1/me/favourites/:carWashId",
  "delete /v1/me/favourites/:carWashId",
  "post /v1/bookings",
  "get /v1/me/bookings",
  "get /v1/bookings/:bookingId",
  "post /v1/bookings/:bookingId/cancel",
  "post /v1/owner/bookings/:bookingId/status",
  "get /v1/owner/car-washes/:carWashId/bookings",
  "get /v1/me/notifications",
  "post /v1/me/notifications/read",
  "get /v1/admin/dashboard",
  "get /v1/admin/me",
  "get /v1/admin/car-washes",
  "get /v1/admin/car-washes/:carWashId",
  "get /v1/admin/car-washes/:carWashId/services",
  "get /v1/admin/car-washes/:carWashId/availability",
  "post /v1/admin/car-washes/:carWashId/review",
  "get /v1/admin/bookings",
  "get /v1/admin/bookings/:bookingId",
  "get /v1/admin/users",
  "get /v1/admin/users/:uid",
  "patch /v1/admin/users/:uid/status",
  "get /v1/admin/audit-logs",
  "post /v1/owner/car-washes",
  "get /v1/owner/car-washes",
  "get /v1/owner/car-washes/:carWashId",
  "patch /v1/owner/car-washes/:carWashId",
  "post /v1/owner/car-washes/:carWashId/resubmit",
  "post /v1/owner/car-washes/:carWashId/services",
  "put /v1/owner/car-washes/:carWashId/availability/:date"
];

test("all existing HTTP routes remain registered exactly once", () => {
  const actual = [];
  function visit(stack) {
    for (const layer of stack) {
      if (layer.route) {
        for (const method of Object.keys(layer.route.methods)) actual.push(`${method} ${layer.route.path}`);
      } else if (layer.handle.stack) visit(layer.handle.stack);
    }
  }
  visit(app._router.stack);
  assert.deepEqual(actual.sort(), [...expectedRoutes].sort());
});

test("HTTP middleware and unauthenticated routes preserve their contracts", async (t) => {
  const server = app.listen(0, "127.0.0.1");
  t.after(() => { server.closeAllConnections(); server.close(); });
  await once(server, "listening");
  const base = `http://127.0.0.1:${server.address().port}`;
  const health = await fetch(`${base}/health`, {headers: {"x-correlation-id": "refactor-test"}});
  assert.equal(health.status, 200);
  assert.equal(health.headers.get("x-correlation-id"), "refactor-test");
  assert.equal((await health.json()).data.message, "Car Wash API is running");

  for (const route of expectedRoutes.filter((route) => !route.endsWith(" /health"))) {
    const [method, path] = route.split(" ");
    const response = await fetch(base + path.replace(/:\w+/g, "test-id"), {method: method.toUpperCase()});
    assert.equal(response.status, 401, route);
    assert.equal((await response.json()).error.code, "AUTH_MISSING", route);
  }
  const missing = await fetch(`${base}/missing`);
  assert.equal(missing.status, 404);
  assert.equal((await missing.json()).error.code, "NOT_FOUND");
  const malformed = await fetch(`${base}/v1/me/onboarding`, {
    method: "POST", headers: {"Content-Type": "application/json"}, body: "{",
  });
  assert.equal(malformed.status, 400);
  assert.equal((await malformed.json()).error.code, "INVALID_JSON");
});
