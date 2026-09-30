/* Run only with the Auth and Firestore emulators and a demo-* project. */
const assert = require('node:assert/strict');
const {randomUUID} = require('node:crypto');
const project = process.env.GCLOUD_PROJECT;
if (!project?.startsWith('demo-') || !process.env.FIRESTORE_EMULATOR_HOST || !process.env.FIREBASE_AUTH_EMULATOR_HOST) {
  throw new Error('This check requires a demo project and both Firebase emulators.');
}
const {admin, db} = require('../src/config/firebase');
const logger = require('firebase-functions/logger');
logger.error = (message, context) => console.error('TEST API ERROR:', context?.error?.stack || message);
const app = require('../src/app');

async function run() {
  const server = await new Promise((resolve) => {
    const instance = app.listen(0, '127.0.0.1', () => resolve(instance));
  });
  const base = `http://127.0.0.1:${server.address().port}`;
  const suffix = randomUUID().slice(0, 8);
  async function identity(label, superAdmin = false) {
    const email = `${label}-${suffix}@example.test`;
    const password = 'Emulator-test-only-123!';
    const account = await admin.auth().createUser({email, password});
    if (superAdmin) await admin.auth().setCustomUserClaims(account.uid, {superAdmin: true});
    const response = await fetch(`http://${process.env.FIREBASE_AUTH_EMULATOR_HOST}/identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=emulator-key`, {
      method: 'POST', signal: AbortSignal.timeout(20000), headers: {'Content-Type': 'application/json'}, body: JSON.stringify({email, password, returnSecureToken: true}),
    });
    const result = await response.json();
    assert.equal(response.status, 200, JSON.stringify(result));
    return {uid: account.uid, token: result.idToken};
  }
  async function api(identity, method, path, body, key, expected = 200) {
    const response = await fetch(`${base}/v1${path}`, {
      method, signal: AbortSignal.timeout(20000), headers: {'Content-Type': 'application/json', Authorization: `Bearer ${identity.token}`, ...(key ? {'Idempotency-Key': key} : {})},
      ...(body === undefined ? {} : {body: JSON.stringify(body)}),
    });
    const result = await response.json();
    assert.ok((Array.isArray(expected) ? expected : [expected]).includes(response.status), `${method} ${path} returned ${response.status}: ${JSON.stringify(result)}`);
    return result.data || result.error;
  }
  try {
    const owner = await identity('owner');
    const customer = await identity('customer');
    const reviewer = await identity('reviewer', true);
    for (const [user, role] of [[owner, 'owner'], [customer, 'customer']]) {
      await api(user, 'POST', '/me/onboarding', {displayName: `Test ${role}`, initialRole: role, acceptedTermsVersion: 'v1', acceptedPrivacyVersion: 'v1'}, undefined, 201);
    }
    const date = new Date(Date.now() + 2 * 86400000).toLocaleDateString('en-CA', {timeZone: 'Asia/Kolkata'});
    const payload = {
      name: 'Test Owner Wash', contactPhone: '+919876543210',
      address: {line1: '10 Test Road', area: 'Central', city: 'Bengaluru', state: 'Karnataka', postalCode: '560001', formattedAddress: '10 Test Road, Central, Bengaluru, Karnataka 560001'},
      location: {latitude: 12.9716, longitude: 77.5946}, categories: ['quick'],
      services: [{name: 'Owner Quick Wash', category: 'quick', priceMinor: 30000, durationMinutes: 30, active: true}],
      availability: [{date, slots: [{startAt: '10:00', endAt: '11:00', capacity: 2, enabled: true}]}],
    };
    const [first, concurrentReplay] = await Promise.all([1, 2].map(() => api(owner, 'POST', '/owner/car-washes/onboarding', payload, `create-${suffix}`, [200, 201])));
    assert.equal(first.carWash.id, concurrentReplay.carWash.id);
    const id = first.carWash.id;
    assert.equal(first.carWash.status, 'pending_review');
    const replay = await api(owner, 'POST', '/owner/car-washes/onboarding', payload, `create-${suffix}`);
    assert.equal(replay.carWash.id, id);
    assert.equal((await db.collection('carWashes').where('ownerUids', 'array-contains', owner.uid).get()).size, 1);
    await api(owner, 'POST', '/owner/car-washes/onboarding', {...payload, name: 'Changed'}, `create-${suffix}`, 409);
    await api(customer, 'GET', `/car-washes/${id}`, undefined, undefined, 404);
    let details = await api(reviewer, 'GET', `/admin/car-washes/${id}`);
    assert.equal(details.onboarding.complete, true);
    await api(reviewer, 'POST', `/admin/car-washes/${id}/review`, {decision: 'reject', reason: 'Please correct the shop name.'});
    const rejected = await api(owner, 'GET', `/owner/car-washes/${id}/onboarding`);
    assert.equal(rejected.carWash.review.reason, 'Please correct the shop name.');
    const corrected = await api(owner, 'PUT', `/owner/car-washes/${id}/onboarding`, {...payload, name: 'Corrected Owner Wash'}, `correct-${suffix}`);
    assert.equal(corrected.carWash.id, id);
    assert.equal(corrected.carWash.status, 'pending_review');
    details = await api(reviewer, 'GET', `/admin/car-washes/${id}`);
    await api(reviewer, 'POST', `/admin/car-washes/${id}/review`, {decision: 'approve', expectedUpdatedAt: {seconds: details.carWash.updatedAt._seconds, nanoseconds: details.carWash.updatedAt._nanoseconds}});
    const publicShop = await api(customer, 'GET', `/car-washes/${id}`);
    assert.equal(publicShop.carWash.name, 'Corrected Owner Wash');
    const nearby = await api(customer, 'GET', '/car-washes/nearby?latitude=12.9716&longitude=77.5946&radiusKm=5');
    assert.ok(nearby.carWashes.some((shop) => shop.id === id));
    const services = await api(owner, 'GET', `/owner/car-washes/${id}/services`);
    const booked = await api(customer, 'POST', '/bookings', {carWashId: id, serviceId: services.services[0].id, date, startAt: '10:00'}, `book-${suffix}`, 201);
    const queue = await api(owner, 'GET', `/owner/car-washes/${id}/bookings?date=${date}`);
    assert.ok(queue.bookings.some((booking) => booking.id === booked.booking.id));
    await api(owner, 'PUT', `/owner/car-washes/${id}/availability/${date}`, {slots: []}, undefined, 409);
    const legacy = await api(owner, 'POST', '/owner/car-washes', Object.fromEntries(Object.entries(payload).filter(([key]) => !['services', 'availability'].includes(key))), undefined, 201);
    const incomplete = await api(reviewer, 'GET', `/admin/car-washes/${legacy.carWash.id}`);
    assert.equal(incomplete.onboarding.complete, false);
    await api(reviewer, 'POST', `/admin/car-washes/${legacy.carWash.id}/review`, {decision: 'approve'}, undefined, 409);
    await api(customer, 'GET', `/owner/car-washes/${id}/onboarding`, undefined, undefined, 403);
    console.log('PASS: persisted onboarding, replay safety, rejection/correction, approval, discovery, customer booking, owner queue, reservation protection and incomplete-approval guard.');
  } finally {
    await new Promise((resolve) => server.close(resolve));
    await admin.app().delete();
  }
}
run().catch((error) => {console.error(error); process.exitCode = 1;});
