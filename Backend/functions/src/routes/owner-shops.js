const {Router} = require("express");
const {requireObject, rejectUnknownFields, requiredString, optionalHttpsUrl, requiredInteger, isValidTime, isValidDate, validateAddress, validateLocation} = require("../utils/validation");
const {mergeAvailability} = require("../services/availability");
const {encodeGeohash} = require("../utils/geohash");
const {serializeShop} = require("../serializers/shops");
const {requireOwner, requireShopOwner} = require("../middleware/authorization");
const {requestId} = require("../middleware/request-id");
const {ApiError} = require("../utils/api-error");
const {asyncRoute} = require("../utils/async-route");
const {requireAuth} = require("../middleware/auth");
const {admin, db} = require("../config/firebase");
const {SERVICE_CATEGORIES} = require("../constants");

const {readOnboarding, onboardingData} = require("../services/shop-onboarding");

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

router.post("/v1/owner/car-washes/:carWashId/resubmit", requireAuth, asyncRoute(async (request, response) => {
  const shop = await requireShopOwner(request, request.params.carWashId);
  requireObject(request.body);
  rejectUnknownFields(request.body, []);
  if (shop.data().status !== "rejected") {
    throw new ApiError(409, "SHOP_RESUBMISSION_INVALID", "Only rejected car washes can be resubmitted.");
  }
  const now = admin.firestore.Timestamp.now();
  await db.runTransaction(async (transaction) => {
    const latest = await transaction.get(shop.ref);
    if (!latest.exists || latest.data().status !== "rejected") {
      throw new ApiError(409, "SHOP_RESUBMISSION_INVALID", "Only rejected car washes can be resubmitted.");
    }
    if (!latest.data().ownerUids.includes(request.auth.uid)) throw new ApiError(403, "SHOP_ACCESS_DENIED", "You do not manage this car wash.");
    const readiness = onboardingData(latest.data(), await readOnboarding(shop.ref, transaction)).onboarding;
    if (!readiness.complete) throw new ApiError(409, "SHOP_ONBOARDING_INCOMPLETE", readiness.issues.join(" "), {issues: readiness.issues});
    transaction.update(shop.ref, {
      status: "pending_review",
      review: {stateChangedAt: now, stateChangedBy: request.auth.uid, decision: "resubmit", reason: null},
      updatedAt: now,
    });
    transaction.create(db.collection("auditLogs").doc(), {
      actorUid: request.auth.uid, action: "car_wash.resubmit", resourceType: "carWash",
      resourceId: shop.ref.id, requestId: request.requestId,
      details: {beforeStatus: "rejected", afterStatus: "pending_review"}, createdAt: now,
    });
  });
  response.status(200).json({success: true, data: {carWashId: shop.ref.id, status: "pending_review"}, requestId: request.requestId});
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
    const currentShop = await transaction.get(shop.ref);
    transaction.create(reference, service);
    const minPriceMinor = currentShop.data().minPriceMinor;
    transaction.update(shop.ref, {
      minPriceMinor: service.active && (minPriceMinor == null || priceMinor < minPriceMinor) ? priceMinor : minPriceMinor ?? null,
      updatedAt: now,
    });
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
  const reference = shop.ref.collection("availability").doc(date);
  const slots = await db.runTransaction(async (transaction) => {
    const latestShop = await transaction.get(shop.ref);
    if (!latestShop.exists || !latestShop.data().ownerUids.includes(request.auth.uid)) throw new ApiError(403, "SHOP_ACCESS_DENIED", "You do not manage this car wash.");
    const existing = await transaction.get(reference);
    const merged = mergeAvailability(request.body.slots, existing.exists ? existing.data().slots || [] : []);
    const now = admin.firestore.Timestamp.now();
    transaction.set(reference, {date, slots: merged, updatedAt: now});
    transaction.update(shop.ref, {updatedAt: now});
    return merged;
  });
  response.status(200).json({success: true, data: {date, slots}, requestId: request.requestId});
}));

module.exports = router;
