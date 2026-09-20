#!/usr/bin/env node

const admin = require("firebase-admin");

const uid = process.argv[2];
if (!uid || !/^[A-Za-z0-9_-]{1,128}$/.test(uid)) {
  throw new Error("Usage: node scripts/set-super-admin.js <firebase-auth-uid>");
}

admin.initializeApp();

async function main() {
  const user = await admin.auth().getUser(uid);
  await admin.auth().setCustomUserClaims(uid, {
    ...(user.customClaims || {}),
    superAdmin: true,
  });
  await admin.auth().revokeRefreshTokens(uid);

  const now = admin.firestore.Timestamp.now();
  await admin.firestore().collection("adminProfiles").doc(uid).set({
    uid,
    displayName: user.displayName || null,
    email: user.email || null,
    permissions: ["super_admin"],
    updatedAt: now,
    createdAt: now,
  }, {merge: true});
  await admin.firestore().collection("auditLogs").add({
    actorUid: uid,
    action: "super_admin.bootstrap",
    resourceType: "adminProfile",
    resourceId: uid,
    requestId: "local-bootstrap",
    details: {},
    createdAt: now,
  });

  console.log(`Super-admin access granted to ${uid}. Sign out and sign in again to refresh the ID token.`);
}

main().catch((error) => {
  console.error(error.message);
  process.exitCode = 1;
});
