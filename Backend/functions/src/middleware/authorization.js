const {ApiError} = require("../utils/api-error");
const {admin, db} = require("../config/firebase");

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

module.exports = {requireOwner, requireOnboarded, requireSuperAdmin, requireShopOwner};
