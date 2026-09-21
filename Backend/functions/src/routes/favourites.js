const {Router} = require("express");
const {publicShopCard} = require("../serializers/shops");
const {requireOnboarded} = require("../middleware/authorization");
const {requestId} = require("../middleware/request-id");
const {ApiError} = require("../utils/api-error");
const {asyncRoute} = require("../utils/async-route");
const {requireAuth} = require("../middleware/auth");
const {admin, db} = require("../config/firebase");

const router = Router();

router.get("/v1/me/favourites", requireAuth, asyncRoute(async (request, response) => {
  await requireOnboarded(request);
  const limit = request.query.limit === undefined ? 20 : Number(request.query.limit);
  if (!Number.isInteger(limit) || limit < 1 || limit > 50) {
    throw new ApiError(400, "VALIDATION_ERROR", "limit must be between 1 and 50", {limit: "invalid"});
  }
  const favourites = await db.collection("users").doc(request.auth.uid).collection("favourites")
    .orderBy("createdAt", "desc")
    .limit(limit)
    .get();
  const shopReferences = favourites.docs.map((favourite) =>
    db.collection("carWashes").doc(favourite.data().carWashId));
  const shopSnapshots = shopReferences.length ? await db.getAll(...shopReferences) : [];
  const shopsById = new Map(shopSnapshots.filter((shop) => shop.exists && shop.data().status === "active")
    .map((shop) => [shop.id, shop]));
  const carWashes = favourites.docs
    .map((favourite) => shopsById.get(favourite.data().carWashId))
    .filter(Boolean)
    .map((shop) => publicShopCard(shop.id, shop.data(), null, true));
  response.status(200).json({success: true, data: {carWashes}, requestId: request.requestId});
}));

router.put("/v1/me/favourites/:carWashId", requireAuth, asyncRoute(async (request, response) => {
  await requireOnboarded(request);
  const shop = db.collection("carWashes").doc(request.params.carWashId);
  const favourite = db.collection("users").doc(request.auth.uid).collection("favourites").doc(shop.id);
  await db.runTransaction(async (transaction) => {
    const [shopSnapshot, favouriteSnapshot] = await Promise.all([
      transaction.get(shop), transaction.get(favourite),
    ]);
    if (!shopSnapshot.exists || shopSnapshot.data().status !== "active") {
      throw new ApiError(404, "CAR_WASH_NOT_FOUND", "Car wash was not found.");
    }
    if (!favouriteSnapshot.exists) {
      transaction.create(favourite, {carWashId: shop.id, createdAt: admin.firestore.Timestamp.now()});
    }
  });
  response.status(200).json({
    success: true,
    data: {carWashId: shop.id, isFavourite: true},
    requestId: request.requestId,
  });
}));

router.delete("/v1/me/favourites/:carWashId", requireAuth, asyncRoute(async (request, response) => {
  await requireOnboarded(request);
  await db.collection("users").doc(request.auth.uid).collection("favourites")
    .doc(request.params.carWashId).delete();
  response.status(204).send();
}));

module.exports = router;
