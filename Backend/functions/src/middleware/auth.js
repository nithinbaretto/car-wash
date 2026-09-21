const {requestId} = require("../middleware/request-id");
const {ApiError} = require("../utils/api-error");
const {asyncRoute} = require("../utils/async-route");
const {admin} = require("../config/firebase");
const logger = require("firebase-functions/logger");

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

module.exports = {requireAuth};
