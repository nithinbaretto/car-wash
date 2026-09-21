const {Router} = require("express");
const {requireObject, rejectUnknownFields} = require("../utils/validation");
const {requireOnboarded} = require("../middleware/authorization");
const {requestId} = require("../middleware/request-id");
const {ApiError} = require("../utils/api-error");
const {asyncRoute} = require("../utils/async-route");
const {requireAuth} = require("../middleware/auth");
const {admin, db} = require("../config/firebase");

const router = Router();

router.get("/v1/me/notifications", requireAuth, asyncRoute(async (request, response) => {
  await requireOnboarded(request); const type = request.query.type || "all"; const unreadOnly = request.query.unreadOnly === "true"; const limit = Number(request.query.limit || 20);
  if (!["all", "booking", "offer", "update"].includes(type) || !Number.isInteger(limit) || limit < 1 || limit > 50) throw new ApiError(400, "VALIDATION_ERROR", "Notification query is invalid.");
  let query = db.collection("notifications").where("recipientUid", "==", request.auth.uid);
  if (type !== "all") query = query.where("type", "==", type);
  if (unreadOnly) query = query.where("isRead", "==", false);
  const notifications = await query.orderBy("createdAt", "desc").limit(limit).get();
  response.status(200).json({success: true, data: {notifications: notifications.docs.map((item) => ({id: item.id, type: item.data().type, title: item.data().title, body: item.data().body, bookingId: item.data().bookingId || null, isRead: item.data().isRead, createdAt: item.data().createdAt}))}, requestId: request.requestId});
}));

router.post("/v1/me/notifications/read", requireAuth, asyncRoute(async (request, response) => {
  await requireOnboarded(request); requireObject(request.body); rejectUnknownFields(request.body, ["notificationIds", "markAll"]);
  const markAll = request.body.markAll === true; const ids = request.body.notificationIds;
  if ((!markAll && (!Array.isArray(ids) || !ids.length || ids.length > 100)) || (markAll && ids !== undefined)) throw new ApiError(400, "VALIDATION_ERROR", "Provide notificationIds or markAll.");
  let documents;
  if (markAll) documents = (await db.collection("notifications").where("recipientUid", "==", request.auth.uid).where("isRead", "==", false).limit(500).get()).docs;
  else documents = await db.getAll(...ids.map((id) => db.collection("notifications").doc(id)));
  const batch = db.batch(); let marked = 0;
  documents.forEach((item) => { if (item.exists && item.data().recipientUid === request.auth.uid && !item.data().isRead) { batch.update(item.ref, {isRead: true, readAt: admin.firestore.Timestamp.now()}); marked += 1; } });
  if (marked) await batch.commit();
  response.status(200).json({success: true, data: {marked}, requestId: request.requestId});
}));

module.exports = router;
