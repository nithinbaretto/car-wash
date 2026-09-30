import {test} from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import {runInNewContext} from 'node:vm';
import ts from 'typescript';

const source = readFileSync(new URL('../src/api/client.ts', import.meta.url), 'utf8');

function client({currentUser, fetch}) {
  const auth = {currentUser};
  const module = {exports: {}};
  const compiled = ts.transpileModule(
    source.replace('import.meta.env.VITE_API_URL', JSON.stringify('https://api.example.test/')),
    {compilerOptions: {module: ts.ModuleKind.CommonJS, target: ts.ScriptTarget.ES2022}},
  ).outputText;
  runInNewContext(compiled, {
    module, exports: module.exports,
    require: (id) => {
      assert.equal(id, '../firebase');
      return {auth};
    },
    fetch, Headers, URLSearchParams, Intl,
  });
  return {...module.exports, auth};
}

const user = () => ({uid: 'admin-1', getIdToken: async () => 'valid-token'});
const json = (body, status = 200) => new Response(JSON.stringify(body), {status});

test('requires a signed-in account without calling the API', async () => {
  const {api} = client({currentUser: null, fetch: () => assert.fail('unexpected network request')});
  await assert.rejects(api('/v1/admin/me'), /Sign in is required/);
});

test('merges Headers and keeps authorization for a JSON mutation', async () => {
  const {api} = client({currentUser: user(), fetch: async (url, init) => {
    assert.equal(url, 'https://api.example.test/v1/admin/car-washes/shop-1/review');
    assert.equal(init.method, 'POST');
    assert.equal(init.headers.get('Authorization'), 'Bearer valid-token');
    assert.equal(init.headers.get('Content-Type'), 'application/json');
    assert.equal(init.headers.get('X-Correlation-Id'), 'test-request');
    assert.equal(init.body, '{"decision":"approve"}');
    return json({success: true, data: {status: 'active'}});
  }});
  assert.deepEqual(await api('/v1/admin/car-washes/shop-1/review', {
    method: 'POST', headers: new Headers({'X-Correlation-Id': 'test-request'}), body: '{"decision":"approve"}',
  }), {status: 'active'});
});

for (const status of [401, 403]) {
  test(`refreshes a token once after ${status} and returns server data`, async () => {
    const refreshes = [];
    let calls = 0;
    const {api} = client({currentUser: {uid: 'admin-1', getIdToken: async (force = false) => {
      refreshes.push(force);
      return force ? 'fresh-token' : 'old-token';
    }}, fetch: async (_url, init) => {
      calls += 1;
      if (calls === 1) return json({error: {code: 'SUPER_ADMIN_REQUIRED'}}, status);
      assert.equal(init.headers.get('Authorization'), 'Bearer fresh-token');
      return json({success: true, data: {admin: {uid: 'admin-1'}}});
    }});
    await api('/v1/admin/me');
    assert.deepEqual(refreshes, [false, true]);
    assert.equal(calls, 2);
  });
}

test('rejects a Hosting HTML fallback instead of reporting empty success', async () => {
  const {api} = client({currentUser: user(), fetch: async () => new Response('<html>App</html>')});
  await assert.rejects(api('/v1/admin/me'), /invalid response/);
});

test('rejects malformed success envelopes and preserves server error messages', async () => {
  const malformed = client({currentUser: user(), fetch: async () => json({hello: 'world'})});
  await assert.rejects(malformed.api('/v1/admin/me'), /invalid response/);
  const rejected = client({currentUser: user(), fetch: async () => json({error: {message: 'Shop details changed.'}}, 409)});
  await assert.rejects(rejected.api('/v1/admin/car-washes/1/review'), /Shop details changed/);
});

test('discards a response if the account changes while the request is running', async () => {
  const connection = client({currentUser: user(), fetch: async () => {
    connection.auth.currentUser = {uid: 'admin-2'};
    return json({success: true, data: {admin: {uid: 'admin-1'}}});
  }});
  await assert.rejects(connection.api('/v1/admin/me'), /account changed/);
});
