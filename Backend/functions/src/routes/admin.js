const {Router} = require("express");
const {requireObject, rejectUnknownFields, isValidDate} = require("../utils/validation");
const {adminUser, adminShop, adminBooking} = require("../serializers/admin");
const {auditRecord} = require("../services/audit");
const {requireSuperAdmin} = require("../middleware/authorization");
const {ApiError} = require("../utils/api-error");
const {asyncRoute} = require("../utils/async-route");
const {requireAuth} = require("../middleware/auth");
const {admin, db} = require("../config/firebase");

const router = Router();
const shopStatuses = ["pending_review", "active", "rejected", "suspended"];
const bookingStatuses = ["pending", "accepted", "rejected", "in_progress", "completed", "cancelled"];
const protect = (handler) => [requireAuth, asyncRoute(async (req, res) => { await requireSuperAdmin(req); return handler(req, res); })];
const limit = (value, fallback = 25) => { const n = Number(value || fallback); if (!Number.isInteger(n) || n < 1 || n > 100) throw new ApiError(400, "VALIDATION_ERROR", "limit is invalid."); return n; };

function pagination(request) {
  const pageSize = limit(request.query.limit);
  let offset = 0;
  if (request.query.cursor) {
    try { offset = Number(Buffer.from(request.query.cursor, "base64url").toString("utf8")); } catch (_) { offset = -1; }
    if (!Number.isInteger(offset) || offset < 0) throw new ApiError(400, "VALIDATION_ERROR", "cursor is invalid.");
  }
  return {pageSize, offset};
}
function result(docs, serializer, pageSize, offset, key) {
  const items = docs.slice(offset, offset + pageSize).map((doc) => serializer(doc.id, doc.data()));
  const next = offset + pageSize < docs.length ? Buffer.from(String(offset + pageSize)).toString("base64url") : null;
  return {[key]: items, hasMore: Boolean(next), nextCursor: next};
}

router.get("/v1/admin/me", ...protect(async (req, res) => {
  const profile = await db.collection("adminProfiles").doc(req.auth.uid).get();
  res.json({success: true, data: {admin: {uid: req.auth.uid, email: req.auth.email || null, displayName: profile.exists ? profile.data().displayName || null : null, permissions: ["super_admin"]}}, requestId: req.requestId});
}));

router.get("/v1/admin/dashboard", ...protect(async (req, res) => {
  const count = (query) => query.count().get().then((x) => x.data().count);
  const today = new Date().toLocaleDateString("en-CA", {timeZone: "Asia/Kolkata"});
  const values = await Promise.all([count(db.collection("users")), ...shopStatuses.map((s) => count(db.collection("carWashes").where("status", "==", s))), ...bookingStatuses.map((s) => count(db.collection("bookings").where("status", "==", s))), count(db.collection("bookings").where("availabilityDate", "==", today))]);
  res.json({success: true, data: {users: values[0], shops: Object.fromEntries(shopStatuses.map((s, i) => [s, values[i + 1]])), bookings: Object.fromEntries(bookingStatuses.map((s, i) => [s, values[i + 1 + shopStatuses.length]])), todayBookings: values.at(-1), generatedAt: admin.firestore.Timestamp.now()}, requestId: req.requestId});
}));

router.get("/v1/admin/car-washes", ...protect(async (req, res) => {
  const {status, ownerUid, id} = req.query;
  if (status && !shopStatuses.includes(status)) throw new ApiError(400, "VALIDATION_ERROR", "Car-wash status is invalid.");
  if (id) { const doc = await db.collection("carWashes").doc(id).get(); return res.json({success: true, data: {carWashes: doc.exists ? [adminShop(doc.id, doc.data())] : [], hasMore: false, nextCursor: null}, requestId: req.requestId}); }
  let query = db.collection("carWashes"); if (status) query = query.where("status", "==", status); if (ownerUid) query = query.where("ownerUids", "array-contains", ownerUid);
  const {pageSize, offset} = pagination(req); const docs = (await query.orderBy("createdAt", "desc").get()).docs;
  res.json({success: true, data: result(docs, adminShop, pageSize, offset, "carWashes"), requestId: req.requestId});
}));

router.get("/v1/admin/car-washes/:carWashId", ...protect(async (req, res) => {
  const shop = await db.collection("carWashes").doc(req.params.carWashId).get(); if (!shop.exists) throw new ApiError(404, "CAR_WASH_NOT_FOUND", "Car wash was not found.");
  const ownerDocs = await Promise.all((shop.data().ownerUids || []).map((uid) => db.collection("users").doc(uid).get()));
  res.json({success: true, data: {carWash: adminShop(shop.id, shop.data()), owners: ownerDocs.filter((x) => x.exists).map((x) => adminUser(x.id, x.data()))}, requestId: req.requestId});
}));
router.get("/v1/admin/car-washes/:carWashId/services", ...protect(async (req, res) => {
  const services = await db.collection("carWashes").doc(req.params.carWashId).collection("services").orderBy("createdAt", "desc").limit(limit(req.query.limit, 100)).get();
  res.json({success: true, data: {services: services.docs.map((x) => ({id: x.id, ...x.data()}))}, requestId: req.requestId});
}));
router.get("/v1/admin/car-washes/:carWashId/availability", ...protect(async (req, res) => {
  if (!isValidDate(req.query.date)) throw new ApiError(400, "VALIDATION_ERROR", "date must be YYYY-MM-DD."); const doc = await db.collection("carWashes").doc(req.params.carWashId).collection("availability").doc(req.query.date).get();
  res.json({success: true, data: {date: req.query.date, slots: doc.exists ? doc.data().slots || [] : []}, requestId: req.requestId});
}));

router.post("/v1/admin/car-washes/:carWashId/review", ...protect(async (req, res) => {
  requireObject(req.body); rejectUnknownFields(req.body, ["decision", "reason", "expectedUpdatedAt"]); const {decision, reason, expectedUpdatedAt} = req.body; const to = {approve: "active", reject: "rejected", suspend: "suspended", reactivate: "active"};
  if (!to[decision] || (decision !== "approve" && (typeof reason !== "string" || reason.trim().length < 2 || reason.trim().length > 500))) throw new ApiError(400, "VALIDATION_ERROR", "Review decision is invalid.");
  const ref = db.collection("carWashes").doc(req.params.carWashId); await db.runTransaction(async (tx) => { const doc = await tx.get(ref); if (!doc.exists) throw new ApiError(404, "CAR_WASH_NOT_FOUND", "Car wash was not found."); const shop = doc.data();
    if (expectedUpdatedAt && (!shop.updatedAt || shop.updatedAt.seconds !== expectedUpdatedAt.seconds || shop.updatedAt.nanoseconds !== (expectedUpdatedAt.nanoseconds || 0))) throw new ApiError(409, "SHOP_REVIEW_STALE", "Shop details changed. Reload before reviewing.");
    const valid = ((decision === "approve" || decision === "reject") && shop.status === "pending_review") || (decision === "suspend" && shop.status === "active") || (decision === "reactivate" && shop.status === "suspended"); if (!valid) throw new ApiError(409, "SHOP_REVIEW_INVALID", "This shop cannot transition with that decision.");
    const now = admin.firestore.Timestamp.now(); tx.update(ref, {status: to[decision], review: {stateChangedAt: now, stateChangedBy: req.auth.uid, decision, reason: reason ? reason.trim() : null}, updatedAt: now}); tx.create(db.collection("auditLogs").doc(), auditRecord(req, `car_wash.${decision}`, "carWash", ref.id, {beforeStatus: shop.status, afterStatus: to[decision], reason: reason ? reason.trim() : null}));
  }); res.json({success: true, data: {carWashId: ref.id, status: to[decision]}, requestId: req.requestId});
}));

router.get("/v1/admin/bookings", ...protect(async (req, res) => {
  const {status, carWashId, customerId, dateFrom, dateTo, id} = req.query; if (status && !bookingStatuses.includes(status) || dateFrom && !isValidDate(dateFrom) || dateTo && !isValidDate(dateTo)) throw new ApiError(400, "VALIDATION_ERROR", "Booking query is invalid.");
  if (id) { const doc = await db.collection("bookings").doc(id).get(); return res.json({success: true, data: {bookings: doc.exists ? [adminBooking(doc.id, doc.data())] : [], hasMore: false, nextCursor: null}, requestId: req.requestId}); }
  let query = db.collection("bookings"); if (status) query = query.where("status", "==", status); if (carWashId) query = query.where("carWashId", "==", carWashId); if (customerId) query = query.where("customerId", "==", customerId); if (dateFrom) query = query.where("availabilityDate", ">=", dateFrom); if (dateTo) query = query.where("availabilityDate", "<=", dateTo);
  const {pageSize, offset} = pagination(req); const docs = (await query.orderBy("scheduledAt", "desc").get()).docs; res.json({success: true, data: result(docs, adminBooking, pageSize, offset, "bookings"), requestId: req.requestId});
}));
router.get("/v1/admin/bookings/:bookingId", ...protect(async (req, res) => { const doc = await db.collection("bookings").doc(req.params.bookingId).get(); if (!doc.exists) throw new ApiError(404, "BOOKING_NOT_FOUND", "Booking was not found."); res.json({success: true, data: {booking: adminBooking(doc.id, doc.data())}, requestId: req.requestId}); }));

router.get("/v1/admin/users", ...protect(async (req, res) => {
  const {role, status, uid, email, phone} = req.query; if (role && !["customer", "owner"].includes(role) || status && !["active", "suspended"].includes(status)) throw new ApiError(400, "VALIDATION_ERROR", "User query is invalid.");
  if (uid) { const doc = await db.collection("users").doc(uid).get(); return res.json({success: true, data: {users: doc.exists ? [adminUser(doc.id, doc.data())] : [], hasMore: false, nextCursor: null}, requestId: req.requestId}); }
  let query = db.collection("users"); if (role) query = query.where("roles", "array-contains", role); if (status) query = query.where("accountStatus", "==", status); if (email) query = query.where("normalizedEmail", "==", String(email).trim().toLowerCase()); if (phone) query = query.where("normalizedPhone", "==", String(phone).replace(/\s/g, "")); const {pageSize, offset} = pagination(req); const docs = (await query.orderBy("createdAt", "desc").get()).docs; res.json({success: true, data: result(docs, adminUser, pageSize, offset, "users"), requestId: req.requestId});
}));
router.get("/v1/admin/users/:uid", ...protect(async (req, res) => { const user = await db.collection("users").doc(req.params.uid).get(); if (!user.exists) throw new ApiError(404, "USER_NOT_FOUND", "User was not found."); const [shops, bookings] = await Promise.all([db.collection("carWashes").where("ownerUids", "array-contains", user.id).get(), db.collection("bookings").where("customerId", "==", user.id).orderBy("scheduledAt", "desc").limit(25).get()]); res.json({success: true, data: {user: adminUser(user.id, user.data()), ownedCarWashes: shops.docs.map((x) => adminShop(x.id, x.data())), bookings: bookings.docs.map((x) => adminBooking(x.id, x.data()))}, requestId: req.requestId}); }));
router.patch("/v1/admin/users/:uid/status", ...protect(async (req, res) => { requireObject(req.body); rejectUnknownFields(req.body, ["status", "reason"]); const {status, reason} = req.body; if (!["active", "suspended"].includes(status) || typeof reason !== "string" || reason.trim().length < 2 || reason.trim().length > 500) throw new ApiError(400, "VALIDATION_ERROR", "User status update is invalid."); const authUser = await admin.auth().getUser(req.params.uid).catch(() => null); if (authUser && authUser.customClaims && authUser.customClaims.superAdmin) throw new ApiError(403, "SUPER_ADMIN_PROTECTED", "Super-admin accounts are managed through provisioning."); const ref = db.collection("users").doc(req.params.uid); await db.runTransaction(async (tx) => { const doc = await tx.get(ref); if (!doc.exists) throw new ApiError(404, "USER_NOT_FOUND", "User was not found."); const now = admin.firestore.Timestamp.now(); tx.update(ref, {accountStatus: status, updatedAt: now}); tx.create(db.collection("auditLogs").doc(), auditRecord(req, `user.${status}`, "user", ref.id, {beforeStatus: doc.data().accountStatus || "active", afterStatus: status, reason: reason.trim()})); }); if (status === "suspended") await admin.auth().revokeRefreshTokens(req.params.uid); res.json({success: true, data: {uid: ref.id, accountStatus: status}, requestId: req.requestId}); }));
router.get("/v1/admin/audit-logs", ...protect(async (req, res) => { let query = db.collection("auditLogs"); if (req.query.actorUid) query = query.where("actorUid", "==", req.query.actorUid); if (req.query.resourceType) query = query.where("resourceType", "==", req.query.resourceType); if (req.query.resourceId) query = query.where("resourceId", "==", req.query.resourceId); const docs = await query.orderBy("createdAt", "desc").limit(limit(req.query.limit)).get(); res.json({success: true, data: {auditLogs: docs.docs.map((x) => ({id: x.id, ...x.data()})), hasMore: false, nextCursor: null}, requestId: req.requestId}); }));

module.exports = router;
