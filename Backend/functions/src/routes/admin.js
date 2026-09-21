const {Router} = require("express");
const {requireObject, rejectUnknownFields} = require("../utils/validation");
const {serializeShop} = require("../serializers/shops");
const {auditRecord} = require("../services/audit");
const {requireSuperAdmin} = require("../middleware/authorization");
const {requestId} = require("../middleware/request-id");
const {ApiError} = require("../utils/api-error");
const {asyncRoute} = require("../utils/async-route");
const {requireAuth} = require("../middleware/auth");
const {admin, db} = require("../config/firebase");

const router = Router();

router.get("/v1/admin/dashboard", requireAuth, asyncRoute(async (request, response) => {
  await requireSuperAdmin(request);
  const count = async (query) => (await query.count().get()).data().count;
  const [users, pendingShops, activeShops, suspendedShops, pendingBookings, completedBookings] = await Promise.all([
    count(db.collection("users")), count(db.collection("carWashes").where("status", "==", "pending_review")),
    count(db.collection("carWashes").where("status", "==", "active")), count(db.collection("carWashes").where("status", "==", "suspended")),
    count(db.collection("bookings").where("status", "==", "pending")), count(db.collection("bookings").where("status", "==", "completed")),
  ]);
  response.status(200).json({success: true, data: {users, shops: {pendingReview: pendingShops, active: activeShops, suspended: suspendedShops}, bookings: {pending: pendingBookings, completed: completedBookings}, generatedAt: admin.firestore.Timestamp.now()}, requestId: request.requestId});
}));

router.get("/v1/admin/car-washes", requireAuth, asyncRoute(async (request, response) => {
  await requireSuperAdmin(request); const status = request.query.status; const limit = Number(request.query.limit || 20);
  if (status !== undefined && !["pending_review", "active", "rejected", "suspended"].includes(status) || !Number.isInteger(limit) || limit < 1 || limit > 100) throw new ApiError(400, "VALIDATION_ERROR", "Car-wash query is invalid.");
  let query = db.collection("carWashes"); if (status) query = query.where("status", "==", status);
  const shops = await query.orderBy("createdAt", "desc").limit(limit).get();
  response.status(200).json({success: true, data: {carWashes: shops.docs.map((shop) => ({...serializeShop(shop.id, shop.data()), ownerUids: shop.data().ownerUids, review: shop.data().review || null}))}, requestId: request.requestId});
}));

router.post("/v1/admin/car-washes/:carWashId/review", requireAuth, asyncRoute(async (request, response) => {
  await requireSuperAdmin(request); requireObject(request.body); rejectUnknownFields(request.body, ["decision", "reason"]);
  const {decision, reason} = request.body; const statusByDecision = {approve: "active", reject: "rejected", suspend: "suspended", reactivate: "active"};
  if (!statusByDecision[decision] || (decision !== "approve" && typeof reason !== "string") || (reason !== undefined && (typeof reason !== "string" || reason.trim().length < 2 || reason.trim().length > 500))) throw new ApiError(400, "VALIDATION_ERROR", "Review decision is invalid.");
  const reference = db.collection("carWashes").doc(request.params.carWashId);
  await db.runTransaction(async (tx) => { const shop = await tx.get(reference); if (!shop.exists) throw new ApiError(404, "CAR_WASH_NOT_FOUND", "Car wash was not found."); const previousStatus = shop.data().status;
    if ((decision === "approve" && previousStatus !== "pending_review") || (decision === "reactivate" && previousStatus !== "suspended")) throw new ApiError(409, "SHOP_REVIEW_INVALID", "This shop cannot transition with that decision.");
    const now = admin.firestore.Timestamp.now(); const nextStatus = statusByDecision[decision]; tx.update(reference, {status: nextStatus, review: {stateChangedAt: now, stateChangedBy: request.auth.uid, decision, reason: reason ? reason.trim() : null}, updatedAt: now});
    tx.create(db.collection("auditLogs").doc(), auditRecord(request, `car_wash.${decision}`, "carWash", reference.id, {beforeStatus: previousStatus, afterStatus: nextStatus, reason: reason ? reason.trim() : null})); });
  response.status(200).json({success: true, data: {carWashId: reference.id, status: statusByDecision[decision]}, requestId: request.requestId});
}));

router.patch("/v1/admin/users/:uid/status", requireAuth, asyncRoute(async (request, response) => {
  await requireSuperAdmin(request); requireObject(request.body); rejectUnknownFields(request.body, ["status", "reason"]); const {status, reason} = request.body;
  if (!["active", "suspended"].includes(status) || typeof reason !== "string" || reason.trim().length < 2 || reason.trim().length > 500) throw new ApiError(400, "VALIDATION_ERROR", "User status update is invalid.");
  const reference = db.collection("users").doc(request.params.uid); await db.runTransaction(async (tx) => { const user = await tx.get(reference); if (!user.exists) throw new ApiError(404, "USER_NOT_FOUND", "User was not found."); const now = admin.firestore.Timestamp.now(); tx.update(reference, {accountStatus: status, updatedAt: now}); tx.create(db.collection("auditLogs").doc(), auditRecord(request, `user.${status}`, "user", reference.id, {reason: reason.trim()})); });
  if (status === "suspended") await admin.auth().revokeRefreshTokens(request.params.uid);
  response.status(200).json({success: true, data: {uid: reference.id, accountStatus: status}, requestId: request.requestId});
}));

// Owner shop setup. The location is selected in the mobile app using Google
// Maps; this API validates and stores both coordinates and a Firestore GeoPoint.

module.exports = router;
