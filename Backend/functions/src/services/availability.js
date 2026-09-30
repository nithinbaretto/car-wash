const {ApiError} = require("../utils/api-error");
const {requireObject, rejectUnknownFields, requiredInteger, isValidTime} = require("../utils/validation");

function mergeAvailability(input, existing = []) {
  if (!Array.isArray(input) || input.length > 100) {
    throw new ApiError(400, "VALIDATION_ERROR", "slots must be an array of at most 100 items.");
  }
  const previous = new Map(existing.map((slot) => [slot.startAt, slot]));
  const starts = new Set();
  const slots = input.map((slot, index) => {
    requireObject(slot);
    rejectUnknownFields(slot, ["startAt", "endAt", "capacity", "enabled"]);
    if (!isValidTime(slot.startAt) || !isValidTime(slot.endAt) || slot.startAt >= slot.endAt || starts.has(slot.startAt)) {
      throw new ApiError(400, "VALIDATION_ERROR", "Slot times must be valid and start times unique.");
    }
    if (slot.enabled !== undefined && typeof slot.enabled !== "boolean") {
      throw new ApiError(400, "VALIDATION_ERROR", "enabled must be a boolean.");
    }
    starts.add(slot.startAt);
    const capacity = requiredInteger(slot.capacity, `slots.${index}.capacity`, 1, 100);
    const current = previous.get(slot.startAt);
    const bookedCount = current?.bookedCount || 0;
    if (bookedCount > 0 && (current.endAt !== slot.endAt || capacity < bookedCount)) {
      throw new ApiError(409, "AVAILABILITY_CONFLICT", "Reserved slots cannot be changed or reduced below bookings.");
    }
    return {startAt: slot.startAt, endAt: slot.endAt, capacity, bookedCount, enabled: slot.enabled !== false};
  });
  if (existing.some((slot) => slot.bookedCount > 0 && !starts.has(slot.startAt))) {
    throw new ApiError(409, "AVAILABILITY_CONFLICT", "Reserved slots cannot be removed.");
  }
  return slots.sort((a, b) => a.startAt.localeCompare(b.startAt));
}

module.exports = {mergeAvailability};
