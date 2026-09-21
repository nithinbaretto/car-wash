const {Router} = require("express");
const {requireObject, rejectUnknownFields, isValidTime, isValidDate} = require("../utils/validation");
const {bookingSummary} = require("../serializers/bookings");
const {bookingState, notificationForStatus} = require("../services/bookings");
const {requireOwner, requireOnboarded, requireShopOwner} = require("../middleware/authorization");
const {requestId} = require("../middleware/request-id");
const {ApiError} = require("../utils/api-error");
const {asyncRoute} = require("../utils/async-route");
const {requireAuth} = require("../middleware/auth");
const {admin, db} = require("../config/firebase");

const router = Router();

router.post("/v1/bookings", requireAuth, asyncRoute(async (request, response) => {
  const user = await requireOnboarded(request);
  if (!user.roles.includes("customer")) throw new ApiError(403, "CUSTOMER_ROLE_REQUIRED", "A customer role is required.");
  requireObject(request.body); rejectUnknownFields(request.body, ["carWashId", "serviceId", "date", "startAt"]);
  const {carWashId, serviceId, date, startAt} = request.body;
  const key = request.get("idempotency-key");
  if (!/^[A-Za-z0-9_-]{1,128}$/.test(key || "")) throw new ApiError(400, "VALIDATION_ERROR", "A valid Idempotency-Key is required.");
  if (typeof carWashId !== "string" || typeof serviceId !== "string" || !isValidDate(date) || !isValidTime(startAt)) throw new ApiError(400, "VALIDATION_ERROR", "Booking details are invalid.");
  const requestHash = `${carWashId}|${serviceId}|${date}|${startAt}`;
  const idempotency = db.collection("users").doc(request.auth.uid).collection("bookingIdempotency").doc(key);
  const result = await db.runTransaction(async (tx) => {
    const existing = await tx.get(idempotency);
    if (existing.exists) {
      if (existing.data().requestHash !== requestHash) throw new ApiError(409, "IDEMPOTENCY_KEY_REUSED", "Idempotency key was used for a different request.");
      return {created: false, booking: await tx.get(db.collection("bookings").doc(existing.data().bookingId))};
    }
    const shopRef = db.collection("carWashes").doc(carWashId); const serviceRef = shopRef.collection("services").doc(serviceId); const availabilityRef = shopRef.collection("availability").doc(date);
    const [shop, service, availability] = await Promise.all([tx.get(shopRef), tx.get(serviceRef), tx.get(availabilityRef)]);
    if (!shop.exists || shop.data().status !== "active") throw new ApiError(404, "CAR_WASH_NOT_FOUND", "Car wash was not found.");
    if (!service.exists || !service.data().active) throw new ApiError(404, "SERVICE_NOT_FOUND", "Service was not found.");
    if (!availability.exists) throw new ApiError(409, "SLOT_UNAVAILABLE", "Selected slot is unavailable.");
    const slots = availability.data().slots || []; const slotIndex = slots.findIndex((slot) => slot.startAt === startAt && slot.enabled && slot.bookedCount < slot.capacity);
    if (slotIndex < 0) throw new ApiError(409, "SLOT_UNAVAILABLE", "Selected slot is unavailable.");
    const slot = slots[slotIndex]; const [hours, minutes] = startAt.split(":").map(Number); const endMinutes = hours * 60 + minutes + service.data().durationMinutes;
    const slotEndMinutes = Number(slot.endAt.slice(0, 2)) * 60 + Number(slot.endAt.slice(3));
    if (endMinutes > slotEndMinutes) throw new ApiError(409, "SLOT_UNAVAILABLE", "Service does not fit in selected slot.");
    const now = admin.firestore.Timestamp.now(); const bookingRef = db.collection("bookings").doc();
    const booking = {customerId: request.auth.uid, carWashId, serviceId, availabilityDate: date, slotStartAt: startAt, slotEndAt: slot.endAt,
      scheduledAt: admin.firestore.Timestamp.fromDate(new Date(`${date}T${startAt}:00+05:30`)), timezone: "Asia/Kolkata", status: "pending", customerListTab: "ongoing",
      customerSnapshot: {displayName: user.displayName, phoneNumber: user.phoneNumber}, serviceSnapshot: {name: service.data().name, category: service.data().category, priceMinor: service.data().priceMinor, durationMinutes: service.data().durationMinutes, currency: "INR"},
      carWashSnapshot: {name: shop.data().name, address: {area: shop.data().address.area, city: shop.data().address.city, formattedAddress: shop.data().address.formattedAddress}, coverImageUrl: shop.data().coverImageUrl || null},
      priceMinor: service.data().priceMinor, currency: "INR", createdAt: now, updatedAt: now, statusUpdatedBy: {uid: request.auth.uid, role: "customer"}};
    slots[slotIndex] = {...slot, bookedCount: slot.bookedCount + 1}; tx.update(availabilityRef, {slots, updatedAt: now}); tx.create(bookingRef, booking); tx.create(idempotency, {requestHash, bookingId: bookingRef.id, createdAt: now});
    return {created: true, booking: {id: bookingRef.id, data: () => booking}};
  });
  response.status(result.created ? 201 : 200).json({success: true, data: {booking: bookingSummary(result.booking.id, result.booking.data())}, requestId: request.requestId});
}));

router.get("/v1/me/bookings", requireAuth, asyncRoute(async (request, response) => {
  await requireOnboarded(request); const tab = request.query.tab || "ongoing"; const limit = Number(request.query.limit || 20);
  if (!["ongoing", "completed"].includes(tab) || !Number.isInteger(limit) || limit < 1 || limit > 50) throw new ApiError(400, "VALIDATION_ERROR", "Booking query is invalid.");
  const order = tab === "ongoing" ? "asc" : "desc"; const field = tab === "ongoing" ? "scheduledAt" : "completedAt";
  const snapshots = await db.collection("bookings").where("customerId", "==", request.auth.uid).where("customerListTab", "==", tab).orderBy(field, order).limit(limit).get();
  response.status(200).json({success: true, data: {bookings: snapshots.docs.map((item) => bookingSummary(item.id, item.data()))}, requestId: request.requestId});
}));

router.get("/v1/bookings/:bookingId", requireAuth, asyncRoute(async (request, response) => {
  await requireOnboarded(request); const booking = await db.collection("bookings").doc(request.params.bookingId).get();
  if (!booking.exists || booking.data().customerId !== request.auth.uid) throw new ApiError(404, "BOOKING_NOT_FOUND", "Booking was not found.");
  response.status(200).json({success: true, data: {booking: bookingSummary(booking.id, booking.data())}, requestId: request.requestId});
}));

router.post("/v1/bookings/:bookingId/cancel", requireAuth, asyncRoute(async (request, response) => {
  await requireOnboarded(request); const bookingRef = db.collection("bookings").doc(request.params.bookingId);
  const booking = await db.runTransaction(async (tx) => {
    const current = await tx.get(bookingRef); if (!current.exists || current.data().customerId !== request.auth.uid) throw new ApiError(404, "BOOKING_NOT_FOUND", "Booking was not found.");
    const data = current.data(); if (data.status !== "pending") throw new ApiError(409, "BOOKING_TRANSITION_INVALID", "Only pending bookings can be cancelled.");
    const availabilityRef = db.collection("carWashes").doc(data.carWashId).collection("availability").doc(data.availabilityDate); const availability = await tx.get(availabilityRef); if (!availability.exists) throw new ApiError(409, "SLOT_UNAVAILABLE", "Booking slot is unavailable.");
    const slots = availability.data().slots || []; const i = slots.findIndex((slot) => slot.startAt === data.slotStartAt); if (i >= 0) slots[i] = {...slots[i], bookedCount: Math.max(0, slots[i].bookedCount - 1)};
    const now = admin.firestore.Timestamp.now(); const updates = {status: "cancelled", customerListTab: "cancelled", cancelledAt: now, updatedAt: now, statusUpdatedBy: {uid: request.auth.uid, role: "customer"}};
    tx.update(availabilityRef, {slots, updatedAt: now}); tx.update(bookingRef, updates); return {...data, ...updates};
  });
  response.status(200).json({success: true, data: {booking: bookingSummary(bookingRef.id, booking)}, requestId: request.requestId});
}));

router.post("/v1/owner/bookings/:bookingId/status", requireAuth, asyncRoute(async (request, response) => {
  await requireOwner(request); requireObject(request.body); rejectUnknownFields(request.body, ["status"]); const target = request.body.status;
  if (!["accepted", "rejected", "in_progress", "completed"].includes(target)) throw new ApiError(400, "VALIDATION_ERROR", "Booking status is invalid.");
  const bookingRef = db.collection("bookings").doc(request.params.bookingId);
  const booking = await db.runTransaction(async (tx) => {
    const current = await tx.get(bookingRef); if (!current.exists) throw new ApiError(404, "BOOKING_NOT_FOUND", "Booking was not found."); const data = current.data();
    const shop = await tx.get(db.collection("carWashes").doc(data.carWashId)); if (!shop.exists || !shop.data().ownerUids.includes(request.auth.uid)) throw new ApiError(403, "SHOP_ACCESS_DENIED", "You do not manage this booking.");
    const allowed = (data.status === "pending" && ["accepted", "rejected"].includes(target)) || (data.status === "accepted" && target === "in_progress") || (data.status === "in_progress" && target === "completed");
    if (!allowed) throw new ApiError(409, "BOOKING_TRANSITION_INVALID", "Booking cannot transition to that status."); const now = admin.firestore.Timestamp.now(); const updates = {status: target, customerListTab: bookingState(target), updatedAt: now, statusUpdatedBy: {uid: request.auth.uid, role: "owner"}, [`${target}At`]: now};
    if (target === "rejected") { const availabilityRef = shop.ref.collection("availability").doc(data.availabilityDate); const availability = await tx.get(availabilityRef); const slots = availability.data().slots || []; const i = slots.findIndex((slot) => slot.startAt === data.slotStartAt); if (i >= 0) slots[i] = {...slots[i], bookedCount: Math.max(0, slots[i].bookedCount - 1)}; tx.update(availabilityRef, {slots, updatedAt: now}); }
    tx.update(bookingRef, updates); tx.create(db.collection("notifications").doc(), {...notificationForStatus(target, {id: bookingRef.id, carWashSnapshot: data.carWashSnapshot}), recipientUid: data.customerId}); return {...data, ...updates};
  });
  response.status(200).json({success: true, data: {booking: bookingSummary(bookingRef.id, booking)}, requestId: request.requestId});
}));

router.get("/v1/owner/car-washes/:carWashId/bookings", requireAuth, asyncRoute(async (request, response) => {
  await requireShopOwner(request, request.params.carWashId);
  const date = request.query.date; const status = request.query.status; const limit = Number(request.query.limit || 50);
  if (!isValidDate(date) ||
      (status !== undefined && !["pending", "accepted", "rejected", "in_progress", "completed", "cancelled"].includes(status)) ||
      !Number.isInteger(limit) || limit < 1 || limit > 50) throw new ApiError(400, "VALIDATION_ERROR", "Booking queue query is invalid.");
  let query = db.collection("bookings").where("carWashId", "==", request.params.carWashId).where("availabilityDate", "==", date);
  if (status) query = query.where("status", "==", status);
  const bookings = await query.orderBy("scheduledAt", "asc").limit(limit).get();
  response.status(200).json({success: true, data: {bookings: bookings.docs.map((item) => bookingSummary(item.id, item.data()))}, requestId: request.requestId});
}));

module.exports = router;
