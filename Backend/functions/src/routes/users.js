const {Router} = require("express");
const {requireObject, rejectUnknownFields, requiredString} = require("../utils/validation");
const {serializeUser} = require("../serializers/users");
const {requestId} = require("../middleware/request-id");
const {ApiError} = require("../utils/api-error");
const {asyncRoute} = require("../utils/async-route");
const {requireAuth} = require("../middleware/auth");
const {admin, db} = require("../config/firebase");
const {ROLES, PLATFORMS} = require("../constants");

const router = Router();

// Enrollment enables owner onboarding, not shop approval or administrator access.
router.post("/v1/me/owner-enrollment", requireAuth, asyncRoute(async (request, response) => {
  requireObject(request.body);
  rejectUnknownFields(request.body, []);
  const reference = db.collection("users").doc(request.auth.uid);
  const user = await db.runTransaction(async (transaction) => {
    const snapshot = await transaction.get(reference);
    if (!snapshot.exists) throw new ApiError(404, "PROFILE_NOT_FOUND", "Complete onboarding first.");
    const current = snapshot.data();
    if (current.accountStatus === "suspended") {
      throw new ApiError(403, "ACCOUNT_SUSPENDED", "This account is suspended.");
    }
    const updates = {
      roles: [...new Set([...current.roles, "owner"])],
      activeRole: "owner",
      updatedAt: admin.firestore.Timestamp.now(),
    };
    transaction.update(reference, updates);
    return {...current, ...updates};
  });
  response.json({success: true, data: {user: serializeUser(user)}, requestId: request.requestId});
}));

router.delete("/v1/me/devices/:installationId", requireAuth, asyncRoute(async (request, response) => {
  const installationId = requiredString(request.params.installationId, "installationId", 1, 200);
  if (!/^[A-Za-z0-9_-]+$/.test(installationId)) {
    throw new ApiError(400, "VALIDATION_ERROR", "installationId must contain only letters, digits, underscores or hyphens.");
  }
  await db.collection("users").doc(request.auth.uid).collection("devices").doc(installationId).delete();
  response.status(204).send();
}));

router.post("/v1/me/onboarding", requireAuth, asyncRoute(async (request, response) => {
  requireObject(request.body);
  rejectUnknownFields(request.body, [
    "displayName", "initialRole", "acceptedTermsVersion", "acceptedPrivacyVersion",
  ]);
  const displayName = requiredString(request.body.displayName, "displayName", 2, 80);
  const initialRole = request.body.initialRole;
  const acceptedTermsVersion = requiredString(
    request.body.acceptedTermsVersion, "acceptedTermsVersion", 1, 40,
  );
  const acceptedPrivacyVersion = requiredString(
    request.body.acceptedPrivacyVersion, "acceptedPrivacyVersion", 1, 40,
  );
  if (!ROLES.has(initialRole)) {
    throw new ApiError(400, "VALIDATION_ERROR", "initialRole must be customer or owner", {
      initialRole: "invalid",
    });
  }

  const reference = db.collection("users").doc(request.auth.uid);
  const result = await db.runTransaction(async (transaction) => {
    const snapshot = await transaction.get(reference);
    if (snapshot.exists) {
      const user = snapshot.data();
      if (user.displayName !== displayName || user.activeRole !== initialRole) {
        throw new ApiError(409, "PROFILE_ALREADY_ONBOARDED", "Profile already exists. Update it instead.");
      }
      return {created: false, user};
    }

    const now = admin.firestore.Timestamp.now();
    const user = {
      uid: request.auth.uid,
      displayName,
      phoneNumber: request.auth.phone_number || null,
      email: request.auth.email || null,
      normalizedPhone: request.auth.phone_number ? request.auth.phone_number.replace(/\s/g, "") : null,
      normalizedEmail: request.auth.email ? request.auth.email.trim().toLowerCase() : null,
      photoUrl: request.auth.picture || null,
      authProviders: (request.auth.firebase && request.auth.firebase.sign_in_provider) ?
        [request.auth.firebase.sign_in_provider] : [],
      roles: [initialRole],
      activeRole: initialRole,
      accountStatus: "active",
      terms: {version: acceptedTermsVersion, acceptedAt: now},
      privacy: {version: acceptedPrivacyVersion, acceptedAt: now},
      createdAt: now,
      updatedAt: now,
    };
    transaction.create(reference, user);
    return {created: true, user};
  });

  response.status(result.created ? 201 : 200).json({
    success: true,
    data: {user: serializeUser(result.user)},
    requestId: request.requestId,
  });
}));

router.get("/v1/me", requireAuth, asyncRoute(async (request, response) => {
  const snapshot = await db.collection("users").doc(request.auth.uid).get();
  if (!snapshot.exists) {
    throw new ApiError(404, "PROFILE_NOT_FOUND", "Complete onboarding first.");
  }
  response.status(200).json({
    success: true,
    data: {user: serializeUser(snapshot.data())},
    requestId: request.requestId,
  });
}));

router.patch("/v1/me", requireAuth, asyncRoute(async (request, response) => {
  requireObject(request.body);
  rejectUnknownFields(request.body, ["displayName", "photoUrl"]);
  if (!Object.keys(request.body).length) {
    throw new ApiError(400, "VALIDATION_ERROR", "At least one editable field is required.");
  }

  const reference = db.collection("users").doc(request.auth.uid);
  const snapshot = await reference.get();
  if (!snapshot.exists) {
    throw new ApiError(404, "PROFILE_NOT_FOUND", "Complete onboarding first.");
  }
  const updates = {updatedAt: admin.firestore.Timestamp.now()};
  if (request.body.displayName !== undefined) {
    updates.displayName = requiredString(request.body.displayName, "displayName", 2, 80);
  }
  if (request.body.photoUrl !== undefined) {
    if (request.body.photoUrl !== null && (typeof request.body.photoUrl !== "string" ||
      request.body.photoUrl.length > 2_048 || !request.body.photoUrl.startsWith("https://"))) {
      throw new ApiError(400, "VALIDATION_ERROR", "photoUrl must be an HTTPS URL", {photoUrl: "invalid"});
    }
    updates.photoUrl = request.body.photoUrl;
  }
  await reference.update(updates);
  response.status(200).json({
    success: true,
    data: {user: serializeUser((await reference.get()).data())},
    requestId: request.requestId,
  });
}));

router.put("/v1/me/active-role", requireAuth, asyncRoute(async (request, response) => {
  requireObject(request.body);
  rejectUnknownFields(request.body, ["activeRole"]);
  const activeRole = request.body.activeRole;
  if (!ROLES.has(activeRole)) {
    throw new ApiError(400, "VALIDATION_ERROR", "activeRole must be customer or owner", {activeRole: "invalid"});
  }
  const reference = db.collection("users").doc(request.auth.uid);
  const snapshot = await reference.get();
  if (!snapshot.exists) {
    throw new ApiError(404, "PROFILE_NOT_FOUND", "Complete onboarding first.");
  }
  if (!snapshot.data().roles.includes(activeRole)) {
    throw new ApiError(403, "ROLE_NOT_GRANTED", "This role is not available for this account.");
  }
  await reference.update({activeRole, updatedAt: admin.firestore.Timestamp.now()});
  response.status(200).json({
    success: true,
    data: {user: serializeUser((await reference.get()).data())},
    requestId: request.requestId,
  });
}));

router.post("/v1/me/devices", requireAuth, asyncRoute(async (request, response) => {
  requireObject(request.body);
  rejectUnknownFields(request.body, ["installationId", "fcmToken", "platform"]);
  const installationId = requiredString(request.body.installationId, "installationId", 1, 200);
  if (!/^[A-Za-z0-9_-]+$/.test(installationId)) {
    throw new ApiError(400, "VALIDATION_ERROR", "installationId must contain only letters, digits, underscores or hyphens.");
  }
  const fcmToken = requiredString(request.body.fcmToken, "fcmToken", 1, 4_096);
  if (!PLATFORMS.has(request.body.platform)) {
    throw new ApiError(400, "VALIDATION_ERROR", "platform must be android, ios, or web", {platform: "invalid"});
  }
  const profile = await db.collection("users").doc(request.auth.uid).get();
  if (!profile.exists) {
    throw new ApiError(404, "PROFILE_NOT_FOUND", "Complete onboarding first.");
  }
  await profile.ref.collection("devices").doc(installationId).set({
    fcmToken,
    platform: request.body.platform,
    updatedAt: admin.firestore.Timestamp.now(),
  }, {merge: true});
  response.status(200).json({success: true, data: {installationId}, requestId: request.requestId});
}));

module.exports = router;
