const {createHash} = require("node:crypto");
const {Router} = require("express");
const {admin, db} = require("../config/firebase");
const {requireAuth} = require("../middleware/auth");
const {requireOwner, requireShopOwner} = require("../middleware/authorization");
const {asyncRoute} = require("../utils/async-route");
const {ApiError} = require("../utils/api-error");
const {encodeGeohash} = require("../utils/geohash");
const {serializeShop} = require("../serializers/shops");
const {validateOnboarding, readOnboarding, onboardingData} = require("../services/shop-onboarding");
const router = Router();

router.get("/v1/owner/car-washes/:carWashId/onboarding", requireAuth, asyncRoute(async (req, res) => {
  const shop = await requireShopOwner(req, req.params.carWashId);
  const data = onboardingData(shop.data(), await readOnboarding(shop.ref));
  res.json({success: true, data: {carWash: serializeShop(shop.id, shop.data()), ...data}, requestId: req.requestId});
}));

async function submit(req, res) {
  await requireOwner(req);
  const key = req.get("idempotency-key");
  if (!/^[A-Za-z0-9_-]{1,128}$/.test(key || "")) throw new ApiError(400, "VALIDATION_ERROR", "A valid Idempotency-Key is required.");
  // Hash the supplied payload before time-sensitive validation so a delayed retry
  // can recover its committed result even after its availability has expired.
  const requestHash = createHash("sha256").update(JSON.stringify({carWashId: req.params.carWashId || null, body: req.body})).digest("hex");
  const receiptRef = db.collection("users").doc(req.auth.uid).collection("shopOnboardingIdempotency").doc(key);
  const shops = db.collection("carWashes");
  const shopRef = req.params.carWashId ? shops.doc(req.params.carWashId) : shops.doc();
  const result = await db.runTransaction(async (tx) => {
    const receipt = await tx.get(receiptRef);
    if (receipt.exists) {
      if (receipt.data().requestHash !== requestHash) throw new ApiError(409, "IDEMPOTENCY_KEY_REUSED", "This key was used for another onboarding request.");
      const existing = await tx.get(db.collection("carWashes").doc(receipt.data().carWashId));
      if (!existing.exists || !existing.data().ownerUids.includes(req.auth.uid)) throw new ApiError(403, "SHOP_ACCESS_DENIED", "You do not manage this car wash.");
      return {created: false, id: existing.id, shop: existing.data()};
    }
    const input = validateOnboarding(req.body);
    let current; let previous = {services: [], availability: []};
    if (req.params.carWashId) {
      current = await tx.get(shopRef);
      if (!current.exists) throw new ApiError(404, "CAR_WASH_NOT_FOUND", "Car wash was not found.");
      if (!current.data().ownerUids.includes(req.auth.uid)) throw new ApiError(403, "SHOP_ACCESS_DENIED", "You do not manage this car wash.");
      if (!["pending_review", "rejected"].includes(current.data().status)) throw new ApiError(409, "SHOP_ONBOARDING_LOCKED", "Only pending or rejected shops can replace their onboarding submission.");
      previous = await readOnboarding(shopRef, tx);
      if (previous.services.length > 100 || previous.availability.length > 100) throw new ApiError(409, "SHOP_ONBOARDING_LOCKED", "This shop must be updated through its service and availability settings.");
      if (previous.availability.some((doc) => (doc.data().slots || []).some((slot) => slot.bookedCount > 0))) throw new ApiError(409, "AVAILABILITY_CONFLICT", "A shop with reservations cannot replace onboarding availability.");
    }
    const now = admin.firestore.Timestamp.now();
    const {location, ...fields} = input.shop;
    const shop = {...(current ? current.data() : {ownerUids: [req.auth.uid], ratingAverage: 0, ratingCount: 0, createdAt: now}),
      ...fields, location: new admin.firestore.GeoPoint(location.latitude, location.longitude),
      latitude: location.latitude, longitude: location.longitude, googlePlaceId: location.placeId,
      geohash: encodeGeohash(location.latitude, location.longitude), status: "pending_review",
      minPriceMinor: Math.min(...input.services.filter((item) => item.active).map((item) => item.priceMinor)), currency: "INR",
      onboarding: {completedAt: now, availabilityDates: input.availability.map((day) => day.date)},
      review: {stateChangedAt: now, stateChangedBy: req.auth.uid, decision: current ? "resubmit" : "submit", reason: null}, updatedAt: now};
    for (const doc of previous.services) tx.delete(doc.ref);
    const replacementDates = new Set(input.availability.map((day) => day.date));
    for (const doc of previous.availability) if (!replacementDates.has(doc.id)) tx.delete(doc.ref);
    tx.set(shopRef, shop);
    for (const service of input.services) tx.create(shopRef.collection("services").doc(), {...service, createdAt: now, updatedAt: now});
    for (const day of input.availability) tx.set(shopRef.collection("availability").doc(day.date), {...day, updatedAt: now});
    tx.create(receiptRef, {requestHash, carWashId: shopRef.id, createdAt: now});
    tx.create(db.collection("auditLogs").doc(), {actorUid: req.auth.uid, action: current ? "car_wash.onboarding_resubmit" : "car_wash.onboarding_submit", resourceType: "carWash", resourceId: shopRef.id, requestId: req.requestId, details: {beforeStatus: current?.data().status || null, afterStatus: "pending_review"}, createdAt: now});
    return {created: !current, id: shopRef.id, shop};
  });
  res.status(result.created ? 201 : 200).json({success: true, data: {carWash: serializeShop(result.id, result.shop)}, requestId: req.requestId});
}
router.post("/v1/owner/car-washes/onboarding", requireAuth, asyncRoute(submit));
router.put("/v1/owner/car-washes/:carWashId/onboarding", requireAuth, asyncRoute(submit));
module.exports = router;
