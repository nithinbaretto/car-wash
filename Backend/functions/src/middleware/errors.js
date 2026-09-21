const {requestId} = require("../middleware/request-id");
const {ApiError} = require("../utils/api-error");
const logger = require("firebase-functions/logger");

function notFound(request, _response, next) {
  next(new ApiError(404, "NOT_FOUND", `Route ${request.method} ${request.path} was not found`));
}

function errorHandler(error, request, response, _next) {
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
}
module.exports = {notFound, errorHandler};
