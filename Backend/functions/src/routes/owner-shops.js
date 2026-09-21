const {Router} = require("express");
const {requireObject, rejectUnknownFields, requiredString, optionalHttpsUrl, requiredInteger, isValidTime, isValidDate, validateAddress, validateLocation} = require("../utils/validation");
const {encodeGeohash} = require("../utils/geohash");
const {serializeShop} = require("../serializers/shops");
const {requireOwner, requireShopOwner} = require("../middleware/authorization");
const {requestId} = require("../middleware/request-id");
const {ApiError} = require("../utils/api-error");
const {asyncRoute} = require("../utils/async-route");
const {requireAuth} = require("../middleware/auth");
const {admin, db} = require("../config/firebase");
const {SERVICE_CATEGORIES} = require("../constants");

const router = Router();

router.post("/v1/owner/car-washes", requireAuth, asyncRoute(async (request, response) => {
  await requireOwner(request);
  requireObject(request.body);
  rejectUnknownFields(request.body, [
    "name", "contactPhone", "address", "location", "categories", "coverImageUrl",
  ]);
  const name = requiredString(request.body.name, "name", 2, 120);
  const contactPhone = requiredString(request.body.contactPhone, "contactPhone", 7, 20);
  const address = validateAddress(request.body.address);
  const location = validateLocation(request.body.location);
  if (!Array.isArray(request.body.categories) || request.body.categories.length === 0 ||
      request.body.categories.length > SERVICE_CATEGORIES.size ||
      request.body.categories.some((category) => !SERVICE_CATEGORIES.has(category))) {
    throw new ApiError(400, "VALIDATION_ERROR", "categories are invalid", {categories: "invalid"});
  }

  const reference = db.collection("carWashes").doc();
  const now = admin.firestore.Timestamp.now();
  const shop = {
    name,
    contactPhone,
    ownerUids: [request.auth.uid],
    status: "pending_review",
    address,
    location: new admin.firestore.GeoPoint(location.latitude, location.longitude),
    latitude: location.latitude,
    longitude: location.longitude,
    geohash: encodeGeohash(location.latitude, location.longitude),
    googlePlaceId: location.placeId,
    categories: [...new Set(request.body.categories)],
    coverImageUrl: optionalHttpsUrl(request.body.coverImageUrl, "coverImageUrl"),
    ratingAverage: 0,
    ratingCount: 0,
    minPriceMinor: null,
    currency: "INR",
    createdAt: now,
    updatedAt: now,
  };
  await reference.create(shop);
  response.status(201).json({
    success: true,
    data: {carWash: serializeShop(reference.id, shop)},
    requestId: request.requestId,
  });
}));

router.get("/v1/owner/car-washes", requireAuth, asyncRoute(async (request, response) => {
  await requireOwner(request);
  const shops = await db.collection("carWashes")
    .where("ownerUids", "array-contains", request.auth.uid)
    .orderBy("createdAt", "desc")
    .limit(50)
    .get();
  response.status(200).json({
    success: true,
    data: {carWashes: shops.docs.map((shop) => serializeShop(shop.id, shop.data()))},
    requestId: request.requestId,
  });
}));

router.get("/v1/owner/car-washes/:carWashId", requireAuth, asyncRoute(async (request, response) => {
  const shop = await requireShopOwner(request, request.params.carWashId);
  response.status(200).json({
    success: true,
    data: {carWash: serializeShop(shop.id, shop.data())},
    requestId: request.requestId,
  });
}));

router.patch("/v1/owner/car-washes/:carWashId", requireAuth, asyncRoute(async (request, response) => {
  const shop = await requireShopOwner(request, request.params.carWashId);
  requireObject(request.body);
  rejectUnknownFields(request.body, ["name", "contactPhone", "address", "location", "categories", "coverImageUrl"]);
  if (!Object.keys(request.body).length) {
    throw new ApiError(400, "VALIDATION_ERROR", "At least one editable field is required.");
  }
  const updates = {updatedAt: admin.firestore.Timestamp.now()};
  if (request.body.name !== undefined) updates.name = requiredString(request.body.name, "name", 2, 120);
  if (request.body.contactPhone !== undefined) updates.contactPhone = requiredString(request.body.contactPhone, "contactPhone", 7, 20);
  if (request.body.address !== undefined) updates.address = validateAddress(request.body.address);
  if (request.body.categories !== undefined) {
    if (!Array.isArray(request.body.categories) || request.body.categories.length === 0 ||
        request.body.categories.some((category) => !SERVICE_CATEGORIES.has(category))) {
      throw new ApiError(400, "VALIDATION_ERROR", "categories are invalid", {categories: "invalid"});
    }
    updates.categories = [...new Set(request.body.categories)];
  }
  if (request.body.coverImageUrl !== undefined) updates.coverImageUrl = optionalHttpsUrl(request.body.coverImageUrl, "coverImageUrl");
  if (request.body.location !== undefined) {
    const location = validateLocation(request.body.location);
    updates.location = new admin.firestore.GeoPoint(location.latitude, location.longitude);
    updates.latitude = location.latitude;
    updates.longitude = location.longitude;
    updates.geohash = encodeGeohash(location.latitude, location.longitude);
    updates.googlePlaceId = location.placeId;
  }
  await shop.ref.update(updates);
  response.status(200).json({
    success: true,
    data: {carWash: serializeShop(shop.id, (await shop.ref.get()).data())},
    requestId: request.requestId,
  });
}));

router.post("/v1/owner/car-washes/:carWashId/services", requireAuth, asyncRoute(async (request, response) => {
  const shop = await requireShopOwner(request, request.params.carWashId);
  requireObject(request.body);
  rejectUnknownFields(request.body, ["name", "category", "priceMinor", "durationMinutes", "active"]);
  const name = requiredString(request.body.name, "name", 2, 100);
  if (!SERVICE_CATEGORIES.has(request.body.category)) {
    throw new ApiError(400, "VALIDATION_ERROR", "category is invalid", {category: "invalid"});
  }
  const priceMinor = requiredInteger(request.body.priceMinor, "priceMinor", 1, 10_000_000);
  const durationMinutes = requiredInteger(request.body.durationMinutes, "durationMinutes", 5, 1_440);
  if (request.body.active !== undefined && typeof request.body.active !== "boolean") {
    throw new ApiError(400, "VALIDATION_ERROR", "active is invalid", {active: "invalid"});
  }
  const reference = shop.ref.collection("services").doc();
  const now = admin.firestore.Timestamp.now();
  const service = {
    name,
    category: request.body.category,
    priceMinor,
    durationMinutes,
    active: request.body.active !== false,
    createdAt: now,
    updatedAt: now,
  };
  await db.runTransaction(async (transaction) => {
    transaction.create(reference, service);
    const minPriceMinor = shop.data().minPriceMinor;
    if (minPriceMinor === null || priceMinor < minPriceMinor) {
      transaction.update(shop.ref, {minPriceMinor: priceMinor, updatedAt: now});
    }
  });
  response.status(201).json({success: true, data: {service: {id: reference.id, ...service}}, requestId: request.requestId});
}));

router.put("/v1/owner/car-washes/:carWashId/availability/:date", requireAuth, asyncRoute(async (request, response) => {
  const shop = await requireShopOwner(request, request.params.carWashId);
  const date = request.params.date;
  if (!isValidDate(date)) {
    throw new ApiError(400, "VALIDATION_ERROR", "date must be YYYY-MM-DD", {date: "invalid"});
  }
  requireObject(request.body);
  rejectUnknownFields(request.body, ["slots"]);
  if (!Array.isArray(request.body.slots) || request.body.slots.length === 0 || request.body.slots.length > 100) {
    throw new ApiError(400, "VALIDATION_ERROR", "slots are invalid", {slots: "invalid"});
  }
  const existingAvailability = await shop.ref.collection("availability").doc(date).get();
  const existingSlots = new Map((existingAvailability.exists ? existingAvailability.data().slots : [])
    .map((slot) => [slot.startAt, slot]));
  const slots = request.body.slots.map((slot, index) => {
    requireObject(slot);
    rejectUnknownFields(slot, ["startAt", "endAt", "capacity", "enabled"]);
    if (!isValidTime(slot.startAt) || !isValidTime(slot.endAt) || slot.startAt >= slot.endAt) {
      throw new ApiError(400, "VALIDATION_ERROR", "slot time is invalid", {[`slots.${index}`]: "invalid"});
    }
    const existing = existingSlots.get(slot.startAt);
    const capacity = requiredInteger(slot.capacity, `slots.${index}.capacity`, 1, 100);
    if (existing && (existing.endAt !== slot.endAt || capacity < existing.bookedCount)) {
      throw new ApiError(409, "AVAILABILITY_CONFLICT", "Reserved slots cannot be shortened or reduced below bookings.");
    }
    return {
      startAt: slot.startAt,
      endAt: slot.endAt,
      capacity,
      bookedCount: existing ? existing.bookedCount : 0,
      enabled: slot.enabled !== false,
    };
  });
  await shop.ref.collection("availability").doc(date).set({
    date,
    slots,
    updatedAt: admin.firestore.Timestamp.now(),
  });
  response.status(200).json({success: true, data: {date, slots}, requestId: request.requestId});
}));

module.exports = router;
