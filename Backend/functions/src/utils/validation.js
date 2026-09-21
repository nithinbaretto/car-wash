const {ApiError} = require("../utils/api-error");

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

module.exports = {requireObject, rejectUnknownFields, requiredString, optionalHttpsUrl, requiredInteger, isValidTime, isValidDate, validateAddress, validateLocation};
