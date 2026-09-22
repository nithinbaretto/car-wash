const test = require("node:test");
const assert = require("node:assert/strict");
const {db} = require("../src/config/firebase");
const router = require("../src/routes/users");

test("owner enrollment preserves roles, repeats safely, and denies missing or suspended profiles", async (t) => {
  const route = router.stack.find((layer) => layer.route?.path === "/v1/me/owner-enrollment").route;
  const handler = route.stack.at(-1).handle;
  let current = {uid: "customer", roles: ["customer"], activeRole: "customer", accountStatus: "active"};
  let exists = true;
  t.mock.method(db, "runTransaction", async (callback) => callback({
    get: async () => ({exists, data: () => current}),
    update: (ref, updates) => { current = {...current, ...updates}; },
  }));
  async function invoke(body = {}) {
    let result;
    let error;
    await handler({auth: {uid: "customer"}, body, requestId: "test"},
      {json: (value) => { result = value; }}, (value) => { error = value; });
    return {result, error};
  }
  assert.deepEqual((await invoke()).result.data.user.roles, ["customer", "owner"]);
  assert.deepEqual((await invoke()).result.data.user.roles, ["customer", "owner"]);
  assert.equal(current.activeRole, "owner");
  assert.ok((await invoke({superAdmin: true})).error);
  current.accountStatus = "suspended";
  assert.equal((await invoke()).error.code, "ACCOUNT_SUSPENDED");
  exists = false;
  assert.equal((await invoke()).error.code, "PROFILE_NOT_FOUND");
});
