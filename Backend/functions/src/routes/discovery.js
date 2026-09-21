const {Router} = require("express");
const {isValidDate} = require("../utils/validation");
const {publicShopCard} = require("../serializers/shops");
const {requireOnboarded} = require("../middleware/authorization");
const {requestId} = require("../middleware/request-id");
const {ApiError} = require("../utils/api-error");
const {asyncRoute} = require("../utils/async-route");
const {requireAuth} = require("../middleware/auth");
const {db} = require("../config/firebase");
const {SERVICE_CATEGORIES} = require("../constants");
const geofire = require("geofire-common");

const router = Router();

router.get("/v1/categories", requireAuth, asyncRoute(async (request, response) => {
  await requireOnboarded(request);
  response.status(200).json({
    success: true,
    data: {categories: [
      {id: "quick", label: "Quick"},
      {id: "interior", label: "Interior"},
      {id: "complete", label: "Complete"},
      {id: "premium", label: "Premium"},
    ]},
    requestId: request.requestId,
  });
}));

router.get("/v1/car-washes/nearby", requireAuth, asyncRoute(async (request, response) => {
  await requireOnboarded(request);
  const latitude = Number(request.query.latitude);
  const longitude = Number(request.query.longitude);
  const radiusKm = request.query.radiusKm === undefined ? 5 : Number(request.query.radiusKm);
  const limit = request.query.limit === undefined ? 20 : Number(request.query.limit);
  const category = request.query.category;
  if (!Number.isFinite(latitude) || latitude < -90 || latitude > 90 ||
      !Number.isFinite(longitude) || longitude < -180 || longitude > 180 ||
      !Number.isFinite(radiusKm) || radiusKm <= 0 || radiusKm > 10 ||
      !Number.isInteger(limit) || limit < 1 || limit > 50 ||
      (category !== undefined && !SERVICE_CATEGORIES.has(category))) {
    throw new ApiError(400, "VALIDATION_ERROR", "Nearby search parameters are invalid.");
  }

  const bounds = geofire.geohashQueryBounds([latitude, longitude], radiusKm * 1_000);
  const baseQuery = db.collection("carWashes").where("status", "==", "active");
  const queries = bounds.map(([startAt, endAt]) => {
    let query = baseQuery;
    if (category) query = query.where("categories", "array-contains", category);
    return query.orderBy("geohash").startAt(startAt).endAt(endAt).limit(200).get();
  });
  const snapshots = await Promise.all(queries);
  const candidates = new Map();
  snapshots.forEach((snapshot) => snapshot.docs.forEach((shop) => candidates.set(shop.id, shop)));

  const carWashes = [...candidates.values()]
    .map((shop) => {
      const data = shop.data();
      const distanceKm = geofire.distanceBetween(
        [latitude, longitude], [data.latitude, data.longitude],
      );
      return {shop, distanceKm};
    })
    .filter(({distanceKm}) => distanceKm <= radiusKm)
    .sort((first, second) => first.distanceKm - second.distanceKm ||
      second.shop.data().ratingAverage - first.shop.data().ratingAverage ||
      first.shop.id.localeCompare(second.shop.id))
    .slice(0, limit)
    .map(({shop, distanceKm}) => publicShopCard(shop.id, shop.data(), distanceKm));

  response.status(200).json({
    success: true,
    data: {carWashes, search: {latitude, longitude, radiusKm}},
    requestId: request.requestId,
  });
}));

router.get("/v1/car-washes/:carWashId/availability", requireAuth, asyncRoute(async (request, response) => {
  await requireOnboarded(request);
  const date = request.query.date;
  if (!isValidDate(date)) {
    throw new ApiError(400, "VALIDATION_ERROR", "date must be YYYY-MM-DD", {date: "invalid"});
  }
  const shop = await db.collection("carWashes").doc(request.params.carWashId).get();
  if (!shop.exists || shop.data().status !== "active") {
    throw new ApiError(404, "CAR_WASH_NOT_FOUND", "Car wash was not found.");
  }
  const availability = await shop.ref.collection("availability").doc(date).get();
  const slots = availability.exists ? (availability.data().slots || [])
    .filter((slot) => slot.enabled && slot.bookedCount < slot.capacity)
    .map((slot) => ({
      startAt: slot.startAt,
      endAt: slot.endAt,
      capacity: slot.capacity,
      availableCapacity: slot.capacity - slot.bookedCount,
    })) : [];
  response.status(200).json({success: true, data: {date, slots}, requestId: request.requestId});
}));

router.get("/v1/car-washes/:carWashId", requireAuth, asyncRoute(async (request, response) => {
  await requireOnboarded(request);
  const shop = await db.collection("carWashes").doc(request.params.carWashId).get();
  if (!shop.exists || shop.data().status !== "active") {
    throw new ApiError(404, "CAR_WASH_NOT_FOUND", "Car wash was not found.");
  }
  const services = await shop.ref.collection("services")
    .where("active", "==", true)
    .orderBy("priceMinor", "asc")
    .get();
  response.status(200).json({
    success: true,
    data: {
      carWash: {
        ...publicShopCard(shop.id, shop.data()),
        contactPhone: shop.data().contactPhone,
        services: services.docs.map((service) => ({
          id: service.id,
          name: service.data().name,
          category: service.data().category,
          priceMinor: service.data().priceMinor,
          durationMinutes: service.data().durationMinutes,
        })),
      },
    },
    requestId: request.requestId,
  });
}));

module.exports = router;
