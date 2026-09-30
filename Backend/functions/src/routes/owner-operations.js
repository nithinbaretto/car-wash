const {Router} = require("express");
const {requireObject, rejectUnknownFields, requiredString, isValidDate, isValidTime} = require("../utils/validation");
const {requireShopOwner} = require("../middleware/authorization");
const {requireAuth} = require("../middleware/auth");
const {ApiError} = require("../utils/api-error");
const {asyncRoute} = require("../utils/async-route");
const {bookingSummary} = require("../serializers/bookings");
const {admin, db} = require("../config/firebase");

const router = Router();

router.get("/v1/owner/car-washes/:carWashId/services", requireAuth, asyncRoute(async (request, response) => {
  const shop = await requireShopOwner(request, request.params.carWashId);
  const services = await shop.ref.collection("services").orderBy("priceMinor", "asc").get();
  response.json({success: true, data: {services: services.docs.map((item) => ({id: item.id, ...item.data()}))}, requestId: request.requestId});
}));

router.get("/v1/owner/car-washes/:carWashId/availability", requireAuth, asyncRoute(async (request, response) => {
  const shop = await requireShopOwner(request, request.params.carWashId);
  const date = request.query.date;
  if (!isValidDate(date)) throw new ApiError(400, "VALIDATION_ERROR", "date must be YYYY-MM-DD");
  const availability = await shop.ref.collection("availability").doc(date).get();
  response.json({success: true, data: {date, slots: availability.exists ? (availability.data().slots || []).map((slot) => ({...slot, availableCapacity: Math.max(0, slot.capacity - slot.bookedCount)})) : []}, requestId: request.requestId});
}));

// Operational booking totals, not payment balances or settlements.
router.get("/v1/owner/car-washes/:carWashId/earnings", requireAuth, asyncRoute(async (request, response) => {
  await requireShopOwner(request, request.params.carWashId);
  const date = request.query.date;
  if (!isValidDate(date)) throw new ApiError(400, "VALIDATION_ERROR", "date must be YYYY-MM-DD");
  const dayStart = new Date(`${date}T00:00:00+05:30`);
  const dayEnd = new Date(dayStart.getTime() + 86_400_000);
  const weekStart = new Date(dayStart.getTime() - 6 * 86_400_000);
  const totals = async (start) => {
    const result = await db.collection("bookings")
      .where("carWashId", "==", request.params.carWashId)
      .where("status", "==", "completed")
      .where("completedAt", ">=", admin.firestore.Timestamp.fromDate(start))
      .where("completedAt", "<", admin.firestore.Timestamp.fromDate(dayEnd))
      .aggregate({amount: admin.firestore.AggregateField.sum("priceMinor"), count: admin.firestore.AggregateField.count()}).get();
    return result.data();
  };
  const [today, week] = await Promise.all([totals(dayStart), totals(weekStart)]);
  response.json({success: true, data: {earnings: {
    todayMinor: today.amount, weekMinor: week.amount, currency: "INR",
    completedToday: today.count, completedWeek: week.count,
  }}, requestId: request.requestId});
}));

router.post("/v1/owner/car-washes/:carWashId/walk-ins", requireAuth, asyncRoute(async (request, response) => {
  await requireShopOwner(request, request.params.carWashId);
  requireObject(request.body);
  rejectUnknownFields(request.body, ["customerName", "vehicle", "serviceId", "date", "startAt"]);
  const customerName = requiredString(request.body.customerName, "customerName", 2, 80);
  const vehicle = requiredString(request.body.vehicle, "vehicle", 2, 40);
  const serviceId = requiredString(request.body.serviceId, "serviceId", 1, 200);
  const {date, startAt} = request.body;
  const key = request.get("idempotency-key");
  if (!/^[A-Za-z0-9_-]{1,128}$/.test(key || "") || serviceId.includes("/") || !isValidDate(date) || !isValidTime(startAt)) {
    throw new ApiError(400, "VALIDATION_ERROR", "Valid service, date, startAt and Idempotency-Key are required.");
  }
  const carWashId = request.params.carWashId;
  const requestHash = JSON.stringify({carWashId, customerName, vehicle, serviceId, date, startAt});
  const idempotency = db.collection("users").doc(request.auth.uid).collection("walkInIdempotency").doc(key);
  const result = await db.runTransaction(async (tx) => {
    const existing = await tx.get(idempotency);
    if (existing.exists) {
      if (existing.data().requestHash !== requestHash) throw new ApiError(409, "IDEMPOTENCY_KEY_REUSED", "Idempotency key was used for a different request.");
      return {created: false, booking: await tx.get(db.collection("bookings").doc(existing.data().bookingId))};
    }
    const shopRef = db.collection("carWashes").doc(carWashId);
    const availabilityRef = shopRef.collection("availability").doc(date);
    const [shop, service, availability] = await Promise.all([
      tx.get(shopRef), tx.get(shopRef.collection("services").doc(serviceId)), tx.get(availabilityRef),
    ]);
    if (!shop.exists || !shop.data().ownerUids.includes(request.auth.uid)) throw new ApiError(403, "SHOP_ACCESS_DENIED", "You do not manage this car wash.");
    if (shop.data().status !== "active") throw new ApiError(409, "CAR_WASH_INACTIVE", "An active car wash is required.");
    if (!service.exists || !service.data().active) throw new ApiError(404, "SERVICE_NOT_FOUND", "Service was not found.");
    const slots = availability.exists ? availability.data().slots || [] : [];
    const index = slots.findIndex((slot) => slot.startAt === startAt && slot.enabled && slot.bookedCount < slot.capacity);
    if (index < 0) throw new ApiError(409, "SLOT_UNAVAILABLE", "Selected slot is unavailable.");
    const slot = slots[index];
    const minutes = (time) => Number(time.slice(0, 2)) * 60 + Number(time.slice(3));
    if (minutes(startAt) + service.data().durationMinutes > minutes(slot.endAt)) throw new ApiError(409, "SLOT_UNAVAILABLE", "Service does not fit in selected slot.");
    const now = admin.firestore.Timestamp.now();
    const bookingRef = db.collection("bookings").doc();
    const booking = {
      customerId: null, source: "walk_in", carWashId, serviceId, availabilityDate: date,
      slotStartAt: startAt, slotEndAt: slot.endAt,
      scheduledAt: admin.firestore.Timestamp.fromDate(new Date(`${date}T${startAt}:00+05:30`)),
      timezone: "Asia/Kolkata", status: "accepted", customerListTab: "ongoing",
      customerSnapshot: {displayName: customerName, phoneNumber: null},
      vehicleSnapshot: {registrationNumber: vehicle},
      serviceSnapshot: {name: service.data().name, category: service.data().category, priceMinor: service.data().priceMinor, durationMinutes: service.data().durationMinutes, currency: "INR"},
      carWashSnapshot: {name: shop.data().name, address: shop.data().address, coverImageUrl: shop.data().coverImageUrl || null},
      priceMinor: service.data().priceMinor, currency: "INR", createdAt: now, updatedAt: now, acceptedAt: now,
      statusUpdatedBy: {uid: request.auth.uid, role: "owner"},
    };
    slots[index] = {...slot, bookedCount: slot.bookedCount + 1};
    tx.update(availabilityRef, {slots, updatedAt: now});
    tx.create(bookingRef, booking);
    tx.create(idempotency, {requestHash, bookingId: bookingRef.id, createdAt: now});
    return {created: true, booking: {id: bookingRef.id, data: () => booking}};
  });
  response.status(result.created ? 201 : 200).json({success: true, data: {booking: bookingSummary(result.booking.id, result.booking.data())}, requestId: request.requestId});
}));

module.exports = router;
