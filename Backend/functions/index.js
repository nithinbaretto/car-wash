const express = require("express");
const cors = require("cors");
const {onRequest} = require("firebase-functions/v2/https");
const logger = require("firebase-functions/logger");
const admin = require("firebase-admin");
const geofire = require("geofire-common");

admin.initializeApp();

const db = admin.firestore();
const app = express();
const ROLES = new Set(["customer", "owner"]);
const PLATFORMS = new Set(["android", "ios", "web"]);
const SERVICE_CATEGORIES = new Set(["quick", "interior", "complete", "premium"]);

class ApiError extends Error {
  constructor(status, code, message, fields) {
    super(message);
    this.status = status;
    this.code = code;
    this.fields = fields;
  }
}

function asyncRoute(handler) {
  return (request, response, next) => Promise.resolve(handler(request, response, next)).catch(next);
}

function requireObject(body) {
  if (!body || typeof body !== "object" || Array.isArray(body)) {
    throw new ApiError(400, "VALIDATION_ERROR", "A JSON object is required");
  }
}

function rejectUnknownFields(body, allowed) {
  const unknown = Object.keys(body).filter((key) => !allowed.includes(key));
  if (unknown.length) {
    throw new ApiError(400, "VALIDATION_ERROR", "Unsupported fields were provided", {
      fields: unknown.join(", "),
    });
  }
}

function requiredString(value, field, minLength, maxLength) {
  if (typeof value !== "string") {
    throw new ApiError(400, "VALIDATION_ERROR", `${field} is required`, {[field]: "required"});
  }
  const trimmed = value.trim();
  if (trimmed.length < minLength || trimmed.length > maxLength) {
    throw new ApiError(400, "VALIDATION_ERROR", `${field} is invalid`, {[field]: "invalid"});
  }
  return trimmed;
}

function requestId(request) {
  const incoming = request.get("x-correlation-id") || request.get("x-request-id");
  return incoming && /^[A-Za-z0-9_-]{1,128}$/.test(incoming) ? incoming : crypto.randomUUID();
}

function serializeUser(user) {
  return {
    uid: user.uid,
    displayName: user.displayName,
    phoneNumber: user.phoneNumber || null,
    email: user.email || null,
    photoUrl: user.photoUrl || null,
    roles: user.roles,
    activeRole: user.activeRole,
    terms: user.terms,
    privacy: user.privacy,
    createdAt: user.createdAt,
    updatedAt: user.updatedAt,
  };
}

function optionalHttpsUrl(value, field) {
  if (value === undefined || value === null) {
    return null;
  }
  if (typeof value !== "string" || value.length > 2_048 || !value.startsWith("https://")) {
    throw new ApiError(400, "VALIDATION_ERROR", `${field} must be an HTTPS URL`, {[field]: "invalid"});
  }
  return value;
}

function requiredInteger(value, field, minimum, maximum) {
  if (!Number.isInteger(value) || value < minimum || value > maximum) {
    throw new ApiError(400, "VALIDATION_ERROR", `${field} is invalid`, {[field]: "invalid"});
  }
  return value;
}

function isValidTime(value) {
  if (typeof value !== "string" || !/^\d{2}:\d{2}$/.test(value)) return false;
  const [hours, minutes] = value.split(":").map(Number);
  return hours >= 0 && hours <= 23 && minutes >= 0 && minutes <= 59;
}

function isValidDate(value) {
  if (typeof value !== "string" || !/^\d{4}-\d{2}-\d{2}$/.test(value)) return false;
  const [year, month, day] = value.split("-").map(Number);
  const parsed = new Date(Date.UTC(year, month - 1, day));
  return parsed.getUTCFullYear() === year && parsed.getUTCMonth() === month - 1 && parsed.getUTCDate() === day;
}

function encodeGeohash(latitude, longitude, precision = 9) {
  const alphabet = "0123456789bcdefghjkmnpqrstuvwxyz";
  let minLatitude = -90;
  let maxLatitude = 90;
  let minLongitude = -180;
  let maxLongitude = 180;
  let hash = "";
  let bit = 0;
  let character = 0;
  let longitudeBit = true;

  while (hash.length < precision) {
    const midpoint = longitudeBit ?
      (minLongitude + maxLongitude) / 2 : (minLatitude + maxLatitude) / 2;
    const value = longitudeBit ? longitude : latitude;
    if (value >= midpoint) {
      character = (character << 1) + 1;
      if (longitudeBit) minLongitude = midpoint;
      else minLatitude = midpoint;
    } else {
      character <<= 1;
      if (longitudeBit) maxLongitude = midpoint;
      else maxLatitude = midpoint;
    }
    longitudeBit = !longitudeBit;
    bit += 1;
    if (bit === 5) {
      hash += alphabet[character];
      bit = 0;
      character = 0;
    }
  }
  return hash;
}

function validateAddress(address) {
  requireObject(address);
  rejectUnknownFields(address, ["line1", "area", "city", "state", "postalCode", "formattedAddress"]);
  return {
    line1: requiredString(address.line1, "address.line1", 2, 200),
    area: requiredString(address.area, "address.area", 2, 100),
    city: requiredString(address.city, "address.city", 2, 100),
    state: requiredString(address.state, "address.state", 2, 100),
    postalCode: requiredString(address.postalCode, "address.postalCode", 4, 12),
    formattedAddress: requiredString(address.formattedAddress, "address.formattedAddress", 2, 300),
  };
}

function validateLocation(location) {
  requireObject(location);
  rejectUnknownFields(location, ["latitude", "longitude", "placeId"]);
  if (typeof location.latitude !== "number" || location.latitude < -90 || location.latitude > 90 ||
      typeof location.longitude !== "number" || location.longitude < -180 || location.longitude > 180) {
    throw new ApiError(400, "VALIDATION_ERROR", "location coordinates are invalid", {location: "invalid"});
  }
  if (location.placeId !== undefined && (typeof location.placeId !== "string" || location.placeId.length > 300)) {
    throw new ApiError(400, "VALIDATION_ERROR", "location.placeId is invalid", {"location.placeId": "invalid"});
  }
  return {
    latitude: location.latitude,
    longitude: location.longitude,
    placeId: location.placeId || null,
  };
}

async function requireOwner(request) {
  const profile = await db.collection("users").doc(request.auth.uid).get();
  if (!profile.exists) {
    throw new ApiError(404, "PROFILE_NOT_FOUND", "Complete onboarding first.");
  }
  if (profile.data().accountStatus === "suspended") {
    throw new ApiError(403, "ACCOUNT_SUSPENDED", "This account is suspended.");
  }
  if (!profile.data().roles.includes("owner")) {
    throw new ApiError(403, "OWNER_ROLE_REQUIRED", "An owner profile is required.");
  }
  return profile.data();
}

async function requireOnboarded(request) {
  const profile = await db.collection("users").doc(request.auth.uid).get();
  if (!profile.exists) {
    throw new ApiError(404, "PROFILE_NOT_FOUND", "Complete onboarding first.");
  }
  if (profile.data().accountStatus === "suspended") {
    throw new ApiError(403, "ACCOUNT_SUSPENDED", "This account is suspended.");
  }
  return profile.data();
}

async function requireSuperAdmin(request) {
  if (request.auth.superAdmin !== true) {
    throw new ApiError(403, "SUPER_ADMIN_REQUIRED", "Super-admin access is required.");
  }
}

function auditRecord(request, action, resourceType, resourceId, details = {}) {
  return {
    actorUid: request.auth.uid, action, resourceType, resourceId,
    requestId: request.requestId, details, createdAt: admin.firestore.Timestamp.now(),
  };
}

async function requireShopOwner(request, carWashId) {
  await requireOwner(request);
  const shop = await db.collection("carWashes").doc(carWashId).get();
  if (!shop.exists) {
    throw new ApiError(404, "CAR_WASH_NOT_FOUND", "Car wash was not found.");
  }
  if (!shop.data().ownerUids.includes(request.auth.uid)) {
    throw new ApiError(403, "SHOP_ACCESS_DENIED", "You do not manage this car wash.");
  }
  return shop;
}

function serializeShop(id, shop) {
  return {
    id,
    name: shop.name,
    contactPhone: shop.contactPhone,
    address: shop.address,
    location: shop.location,
    status: shop.status,
    categories: shop.categories,
    coverImageUrl: shop.coverImageUrl || null,
    createdAt: shop.createdAt,
    updatedAt: shop.updatedAt,
  };
}

function publicShopCard(id, shop, distanceKm = null, isFavourite = false) {
  return {
    id,
    name: shop.name,
    address: {
      area: shop.address.area,
      city: shop.address.city,
      formattedAddress: shop.address.formattedAddress,
    },
    location: {latitude: shop.latitude, longitude: shop.longitude},
    categories: shop.categories,
    coverImageUrl: shop.coverImageUrl || null,
    rating: {average: shop.ratingAverage, count: shop.ratingCount},
    startingPriceMinor: shop.minPriceMinor,
    currency: shop.currency,
    distanceKm: distanceKm === null ? null : Number(distanceKm.toFixed(2)),
    isFavourite,
  };
}

function bookingState(status) {
  if (["pending", "accepted", "in_progress"].includes(status)) return "ongoing";
  if (status === "completed") return "completed";
  return "cancelled";
}

function bookingSummary(id, booking) {
  return {id, carWashId: booking.carWashId, status: booking.status, scheduledDate: booking.availabilityDate,
    startAt: booking.slotStartAt, endAt: booking.slotEndAt, priceMinor: booking.priceMinor, currency: booking.currency,
    carWash: booking.carWashSnapshot, service: booking.serviceSnapshot, vehicle: booking.vehicleSnapshot || null,
    createdAt: booking.createdAt, updatedAt: booking.updatedAt};
}

function notificationForStatus(status, booking) {
  const content = {accepted: ["Booking accepted", `${booking.carWashSnapshot.name} accepted your booking.`],
    rejected: ["Booking rejected", `${booking.carWashSnapshot.name} could not accept your booking.`],
    in_progress: ["Your car wash is in progress", `Your vehicle is being washed at ${booking.carWashSnapshot.name}.`],
    completed: ["Wash completed", `Your car wash is completed at ${booking.carWashSnapshot.name}.`],
    cancelled: ["Booking cancelled", "Your booking has been cancelled."]}[status];
  return content ? {type: "booking", title: content[0], body: content[1], bookingId: booking.id,
    isRead: false, createdAt: admin.firestore.Timestamp.now()} : null;
}

app.use(cors({origin: true}));
app.use((request, response, next) => {
  request.requestId = requestId(request);
  response.set("x-correlation-id", request.requestId);
  next();
});
app.use(express.json({limit: "32kb"}));
app.use((error, _request, _response, next) => {
  if (error instanceof SyntaxError && error.status === 400 && "body" in error) {
    next(new ApiError(400, "INVALID_JSON", "Request body must be valid JSON."));
    return;
  }
  next(error);
});

const requireAuth = asyncRoute(async (request, _response, next) => {
  const authorization = request.get("authorization") || "";
  const match = authorization.match(/^Bearer\s+(.+)$/i);
  if (!match) {
    throw new ApiError(401, "AUTH_MISSING", "Authentication is required.");
  }

  try {
    request.auth = await admin.auth().verifyIdToken(match[1], true);
  } catch (error) {
    logger.warn("Firebase token verification failed", {requestId: request.requestId, code: error.code});
    throw new ApiError(401, "AUTH_INVALID", "Authentication is invalid or expired.");
  }
  next();
});

app.get("/health", (request, response) => {
  response.status(200).json({
    success: true,
    data: {message: "Car Wash API is running", timestamp: new Date().toISOString()},
    requestId: request.requestId,
  });
});

// Firebase Authentication owns Phone OTP, Google, and Apple authentication.
// This route creates a Firestore profile after authentication succeeds.
app.post("/v1/me/onboarding", requireAuth, asyncRoute(async (request, response) => {
  requireObject(request.body);
  rejectUnknownFields(request.body, [
    "displayName", "initialRole", "acceptedTermsVersion", "acceptedPrivacyVersion",
  ]);
  const displayName = requiredString(request.body.displayName, "displayName", 2, 80);
  const initialRole = request.body.initialRole;
  const acceptedTermsVersion = requiredString(
    request.body.acceptedTermsVersion, "acceptedTermsVersion", 1, 40,
  );
  const acceptedPrivacyVersion = requiredString(
    request.body.acceptedPrivacyVersion, "acceptedPrivacyVersion", 1, 40,
  );
  if (!ROLES.has(initialRole)) {
    throw new ApiError(400, "VALIDATION_ERROR", "initialRole must be customer or owner", {
      initialRole: "invalid",
    });
  }

  const reference = db.collection("users").doc(request.auth.uid);
  const result = await db.runTransaction(async (transaction) => {
    const snapshot = await transaction.get(reference);
    if (snapshot.exists) {
      const user = snapshot.data();
      if (user.displayName !== displayName || user.activeRole !== initialRole) {
        throw new ApiError(409, "PROFILE_ALREADY_ONBOARDED", "Profile already exists. Update it instead.");
      }
      return {created: false, user};
    }

    const now = admin.firestore.Timestamp.now();
    const user = {
      uid: request.auth.uid,
      displayName,
      phoneNumber: request.auth.phone_number || null,
      email: request.auth.email || null,
      photoUrl: request.auth.picture || null,
      authProviders: (request.auth.firebase && request.auth.firebase.sign_in_provider) ?
        [request.auth.firebase.sign_in_provider] : [],
      roles: [initialRole],
      activeRole: initialRole,
      accountStatus: "active",
      terms: {version: acceptedTermsVersion, acceptedAt: now},
      privacy: {version: acceptedPrivacyVersion, acceptedAt: now},
      createdAt: now,
      updatedAt: now,
    };
    transaction.create(reference, user);
    return {created: true, user};
  });

  response.status(result.created ? 201 : 200).json({
    success: true,
    data: {user: serializeUser(result.user)},
    requestId: request.requestId,
  });
}));

app.get("/v1/me", requireAuth, asyncRoute(async (request, response) => {
  const snapshot = await db.collection("users").doc(request.auth.uid).get();
  if (!snapshot.exists) {
    throw new ApiError(404, "PROFILE_NOT_FOUND", "Complete onboarding first.");
  }
  response.status(200).json({
    success: true,
    data: {user: serializeUser(snapshot.data())},
    requestId: request.requestId,
  });
}));

app.patch("/v1/me", requireAuth, asyncRoute(async (request, response) => {
  requireObject(request.body);
  rejectUnknownFields(request.body, ["displayName", "photoUrl"]);
  if (!Object.keys(request.body).length) {
    throw new ApiError(400, "VALIDATION_ERROR", "At least one editable field is required.");
  }

  const reference = db.collection("users").doc(request.auth.uid);
  const snapshot = await reference.get();
  if (!snapshot.exists) {
    throw new ApiError(404, "PROFILE_NOT_FOUND", "Complete onboarding first.");
  }
  const updates = {updatedAt: admin.firestore.Timestamp.now()};
  if (request.body.displayName !== undefined) {
    updates.displayName = requiredString(request.body.displayName, "displayName", 2, 80);
  }
  if (request.body.photoUrl !== undefined) {
    if (request.body.photoUrl !== null && (typeof request.body.photoUrl !== "string" ||
      request.body.photoUrl.length > 2_048 || !request.body.photoUrl.startsWith("https://"))) {
      throw new ApiError(400, "VALIDATION_ERROR", "photoUrl must be an HTTPS URL", {photoUrl: "invalid"});
    }
    updates.photoUrl = request.body.photoUrl;
  }
  await reference.update(updates);
  response.status(200).json({
    success: true,
    data: {user: serializeUser((await reference.get()).data())},
    requestId: request.requestId,
  });
}));

app.put("/v1/me/active-role", requireAuth, asyncRoute(async (request, response) => {
  requireObject(request.body);
  rejectUnknownFields(request.body, ["activeRole"]);
  const activeRole = request.body.activeRole;
  if (!ROLES.has(activeRole)) {
    throw new ApiError(400, "VALIDATION_ERROR", "activeRole must be customer or owner", {activeRole: "invalid"});
  }
  const reference = db.collection("users").doc(request.auth.uid);
  const snapshot = await reference.get();
  if (!snapshot.exists) {
    throw new ApiError(404, "PROFILE_NOT_FOUND", "Complete onboarding first.");
  }
  if (!snapshot.data().roles.includes(activeRole)) {
    throw new ApiError(403, "ROLE_NOT_GRANTED", "This role is not available for this account.");
  }
  await reference.update({activeRole, updatedAt: admin.firestore.Timestamp.now()});
  response.status(200).json({
    success: true,
    data: {user: serializeUser((await reference.get()).data())},
    requestId: request.requestId,
  });
}));

app.post("/v1/me/devices", requireAuth, asyncRoute(async (request, response) => {
  requireObject(request.body);
  rejectUnknownFields(request.body, ["installationId", "fcmToken", "platform"]);
  const installationId = requiredString(request.body.installationId, "installationId", 1, 200);
  const fcmToken = requiredString(request.body.fcmToken, "fcmToken", 1, 4_096);
  if (!PLATFORMS.has(request.body.platform)) {
    throw new ApiError(400, "VALIDATION_ERROR", "platform must be android, ios, or web", {platform: "invalid"});
  }
  const profile = await db.collection("users").doc(request.auth.uid).get();
  if (!profile.exists) {
    throw new ApiError(404, "PROFILE_NOT_FOUND", "Complete onboarding first.");
  }
  await profile.ref.collection("devices").doc(installationId).set({
    fcmToken,
    platform: request.body.platform,
    updatedAt: admin.firestore.Timestamp.now(),
  }, {merge: true});
  response.status(200).json({success: true, data: {installationId}, requestId: request.requestId});
}));

app.get("/v1/categories", requireAuth, asyncRoute(async (request, response) => {
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

app.get("/v1/car-washes/nearby", requireAuth, asyncRoute(async (request, response) => {
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

app.get("/v1/car-washes/:carWashId/availability", requireAuth, asyncRoute(async (request, response) => {
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

app.get("/v1/car-washes/:carWashId", requireAuth, asyncRoute(async (request, response) => {
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

app.get("/v1/me/favourites", requireAuth, asyncRoute(async (request, response) => {
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

app.put("/v1/me/favourites/:carWashId", requireAuth, asyncRoute(async (request, response) => {
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

app.delete("/v1/me/favourites/:carWashId", requireAuth, asyncRoute(async (request, response) => {
  await requireOnboarded(request);
  await db.collection("users").doc(request.auth.uid).collection("favourites")
    .doc(request.params.carWashId).delete();
  response.status(204).send();
}));

app.post("/v1/bookings", requireAuth, asyncRoute(async (request, response) => {
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

app.get("/v1/me/bookings", requireAuth, asyncRoute(async (request, response) => {
  await requireOnboarded(request); const tab = request.query.tab || "ongoing"; const limit = Number(request.query.limit || 20);
  if (!["ongoing", "completed"].includes(tab) || !Number.isInteger(limit) || limit < 1 || limit > 50) throw new ApiError(400, "VALIDATION_ERROR", "Booking query is invalid.");
  const order = tab === "ongoing" ? "asc" : "desc"; const field = tab === "ongoing" ? "scheduledAt" : "completedAt";
  const snapshots = await db.collection("bookings").where("customerId", "==", request.auth.uid).where("customerListTab", "==", tab).orderBy(field, order).limit(limit).get();
  response.status(200).json({success: true, data: {bookings: snapshots.docs.map((item) => bookingSummary(item.id, item.data()))}, requestId: request.requestId});
}));

app.get("/v1/bookings/:bookingId", requireAuth, asyncRoute(async (request, response) => {
  await requireOnboarded(request); const booking = await db.collection("bookings").doc(request.params.bookingId).get();
  if (!booking.exists || booking.data().customerId !== request.auth.uid) throw new ApiError(404, "BOOKING_NOT_FOUND", "Booking was not found.");
  response.status(200).json({success: true, data: {booking: bookingSummary(booking.id, booking.data())}, requestId: request.requestId});
}));

app.post("/v1/bookings/:bookingId/cancel", requireAuth, asyncRoute(async (request, response) => {
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

app.post("/v1/owner/bookings/:bookingId/status", requireAuth, asyncRoute(async (request, response) => {
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

app.get("/v1/owner/car-washes/:carWashId/bookings", requireAuth, asyncRoute(async (request, response) => {
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

app.get("/v1/me/notifications", requireAuth, asyncRoute(async (request, response) => {
  await requireOnboarded(request); const type = request.query.type || "all"; const unreadOnly = request.query.unreadOnly === "true"; const limit = Number(request.query.limit || 20);
  if (!["all", "booking", "offer", "update"].includes(type) || !Number.isInteger(limit) || limit < 1 || limit > 50) throw new ApiError(400, "VALIDATION_ERROR", "Notification query is invalid.");
  let query = db.collection("notifications").where("recipientUid", "==", request.auth.uid);
  if (type !== "all") query = query.where("type", "==", type);
  if (unreadOnly) query = query.where("isRead", "==", false);
  const notifications = await query.orderBy("createdAt", "desc").limit(limit).get();
  response.status(200).json({success: true, data: {notifications: notifications.docs.map((item) => ({id: item.id, type: item.data().type, title: item.data().title, body: item.data().body, bookingId: item.data().bookingId || null, isRead: item.data().isRead, createdAt: item.data().createdAt}))}, requestId: request.requestId});
}));

app.post("/v1/me/notifications/read", requireAuth, asyncRoute(async (request, response) => {
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

app.get("/v1/admin/dashboard", requireAuth, asyncRoute(async (request, response) => {
  await requireSuperAdmin(request);
  const count = async (query) => (await query.count().get()).data().count;
  const [users, pendingShops, activeShops, suspendedShops, pendingBookings, completedBookings] = await Promise.all([
    count(db.collection("users")), count(db.collection("carWashes").where("status", "==", "pending_review")),
    count(db.collection("carWashes").where("status", "==", "active")), count(db.collection("carWashes").where("status", "==", "suspended")),
    count(db.collection("bookings").where("status", "==", "pending")), count(db.collection("bookings").where("status", "==", "completed")),
  ]);
  response.status(200).json({success: true, data: {users, shops: {pendingReview: pendingShops, active: activeShops, suspended: suspendedShops}, bookings: {pending: pendingBookings, completed: completedBookings}, generatedAt: admin.firestore.Timestamp.now()}, requestId: request.requestId});
}));

app.get("/v1/admin/car-washes", requireAuth, asyncRoute(async (request, response) => {
  await requireSuperAdmin(request); const status = request.query.status; const limit = Number(request.query.limit || 20);
  if (status !== undefined && !["pending_review", "active", "rejected", "suspended"].includes(status) || !Number.isInteger(limit) || limit < 1 || limit > 100) throw new ApiError(400, "VALIDATION_ERROR", "Car-wash query is invalid.");
  let query = db.collection("carWashes"); if (status) query = query.where("status", "==", status);
  const shops = await query.orderBy("createdAt", "desc").limit(limit).get();
  response.status(200).json({success: true, data: {carWashes: shops.docs.map((shop) => ({...serializeShop(shop.id, shop.data()), ownerUids: shop.data().ownerUids, review: shop.data().review || null}))}, requestId: request.requestId});
}));

app.post("/v1/admin/car-washes/:carWashId/review", requireAuth, asyncRoute(async (request, response) => {
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

app.patch("/v1/admin/users/:uid/status", requireAuth, asyncRoute(async (request, response) => {
  await requireSuperAdmin(request); requireObject(request.body); rejectUnknownFields(request.body, ["status", "reason"]); const {status, reason} = request.body;
  if (!["active", "suspended"].includes(status) || typeof reason !== "string" || reason.trim().length < 2 || reason.trim().length > 500) throw new ApiError(400, "VALIDATION_ERROR", "User status update is invalid.");
  const reference = db.collection("users").doc(request.params.uid); await db.runTransaction(async (tx) => { const user = await tx.get(reference); if (!user.exists) throw new ApiError(404, "USER_NOT_FOUND", "User was not found."); const now = admin.firestore.Timestamp.now(); tx.update(reference, {accountStatus: status, updatedAt: now}); tx.create(db.collection("auditLogs").doc(), auditRecord(request, `user.${status}`, "user", reference.id, {reason: reason.trim()})); });
  if (status === "suspended") await admin.auth().revokeRefreshTokens(request.params.uid);
  response.status(200).json({success: true, data: {uid: reference.id, accountStatus: status}, requestId: request.requestId});
}));

// Owner shop setup. The location is selected in the mobile app using Google
// Maps; this API validates and stores both coordinates and a Firestore GeoPoint.
app.post("/v1/owner/car-washes", requireAuth, asyncRoute(async (request, response) => {
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

app.get("/v1/owner/car-washes", requireAuth, asyncRoute(async (request, response) => {
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

app.get("/v1/owner/car-washes/:carWashId", requireAuth, asyncRoute(async (request, response) => {
  const shop = await requireShopOwner(request, request.params.carWashId);
  response.status(200).json({
    success: true,
    data: {carWash: serializeShop(shop.id, shop.data())},
    requestId: request.requestId,
  });
}));

app.patch("/v1/owner/car-washes/:carWashId", requireAuth, asyncRoute(async (request, response) => {
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

app.post("/v1/owner/car-washes/:carWashId/services", requireAuth, asyncRoute(async (request, response) => {
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

app.put("/v1/owner/car-washes/:carWashId/availability/:date", requireAuth, asyncRoute(async (request, response) => {
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

app.use((request, _response, next) => {
  next(new ApiError(404, "NOT_FOUND", `Route ${request.method} ${request.path} was not found`));
});

app.use((error, request, response, _next) => {
  const status = error instanceof ApiError ? error.status : 500;
  const code = error instanceof ApiError ? error.code : "INTERNAL_ERROR";
  if (status >= 500) {
    logger.error("Unhandled API error", {requestId: request.requestId, error});
  }
  response.status(status).json({
    success: false,
    error: {
      code,
      message: status >= 500 ? "Internal server error" : error.message,
      ...(error.fields ? {fields: error.fields} : {}),
      requestId: request.requestId,
    },
  });
});

exports.api = onRequest({region: "asia-south1", cors: true}, app);
