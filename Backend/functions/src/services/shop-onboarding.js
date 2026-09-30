const {ApiError} = require("../utils/api-error");
const {requireObject, rejectUnknownFields, requiredString, requiredInteger, optionalHttpsUrl, validateAddress, validateLocation, isValidDate} = require("../utils/validation");
const {SERVICE_CATEGORIES} = require("../constants");
const {mergeAvailability} = require("./availability");

const minutes = (time) => Number(time.slice(0, 2)) * 60 + Number(time.slice(3));
const todayInIndia = () => new Date().toLocaleDateString("en-CA", {timeZone: "Asia/Kolkata"});
function onboardingSlots(input) {
  const slots = mergeAvailability(input);
  if (slots.some((slot, index) => index > 0 && slots[index - 1].endAt > slot.startAt)) {
    throw new ApiError(400, "VALIDATION_ERROR", "Availability slots must not overlap.");
  }
  return slots;
}
function validateShopFields(body) {
  const contactPhone = requiredString(body.contactPhone, "contactPhone", 7, 20);
  if (!/^\+?[\d ()-]+$/.test(contactPhone) || contactPhone.replace(/\D/g, "").length < 7) {
    throw new ApiError(400, "VALIDATION_ERROR", "A valid contact phone is required.");
  }
  if (!Array.isArray(body.categories) || !body.categories.length || body.categories.length > SERVICE_CATEGORIES.size || body.categories.some((item) => !SERVICE_CATEGORIES.has(item))) {
    throw new ApiError(400, "VALIDATION_ERROR", "Select valid service categories.");
  }
  return {name: requiredString(body.name, "name", 2, 120), contactPhone,
    address: validateAddress(body.address), location: validateLocation(body.location),
    categories: [...new Set(body.categories)], coverImageUrl: optionalHttpsUrl(body.coverImageUrl, "coverImageUrl")};
}
function validateService(body) {
  requireObject(body);
  rejectUnknownFields(body, ["name", "category", "priceMinor", "durationMinutes", "active"]);
  if (!SERVICE_CATEGORIES.has(body.category) || body.active !== undefined && typeof body.active !== "boolean") {
    throw new ApiError(400, "VALIDATION_ERROR", "Service category or active flag is invalid.");
  }
  return {name: requiredString(body.name, "name", 2, 100), category: body.category,
    priceMinor: requiredInteger(body.priceMinor, "priceMinor", 1, 10000000),
    durationMinutes: requiredInteger(body.durationMinutes, "durationMinutes", 5, 1440), active: body.active !== false};
}
function inspectOnboarding(shop, services, availability, now = new Date()) {
  const issues = [];
  try { validateShopFields({...shop, location: {latitude: shop.latitude ?? shop.location?.latitude, longitude: shop.longitude ?? shop.location?.longitude}}); } catch (_) { issues.push("Complete valid shop contact, address, location and categories."); }
  const active = services.filter((service) => service.active);
  const categories = Array.isArray(shop.categories) ? shop.categories : [];
  if (!active.length) issues.push("Add at least one active service with a price and duration.");
  for (const category of categories) {
    if (!active.some((service) => service.category === category)) issues.push(`Add an active priced service for the selected ${category} category.`);
  }
  const futureSlots = availability.flatMap((day) => {
    if (!isValidDate(day.date)) return [];
    try { onboardingSlots((day.slots || []).map(({bookedCount, availableCapacity, ...slot}) => slot)); } catch (_) { return []; }
    return (day.slots || []).filter((slot) => slot.enabled && slot.capacity > (slot.bookedCount || 0) && new Date(`${day.date}T${slot.startAt}:00+05:30`) > now)
      .map((slot) => ({...slot, date: day.date}));
  });
  if (!futureSlots.length) issues.push("Add enabled availability with a future start time.");
  for (const service of active) {
    try { validateService({name: service.name, category: service.category, priceMinor: service.priceMinor, durationMinutes: service.durationMinutes, active: service.active}); } catch (_) { issues.push(`Service ${service.name || "unnamed"} needs a valid price and duration.`); continue; }
    if (!categories.includes(service.category)) issues.push(`Service ${service.name} must use a selected shop category.`);
    if (futureSlots.length && !futureSlots.some((slot) => minutes(slot.endAt) - minutes(slot.startAt) >= service.durationMinutes)) issues.push(`Add an available slot long enough for ${service.name}.`);
  }
  return {complete: issues.length === 0, issues, serviceCount: active.length, availabilityDates: [...new Set(futureSlots.map((slot) => slot.date))].sort()};
}
function validateOnboarding(body) {
  requireObject(body);
  rejectUnknownFields(body, ["name", "contactPhone", "address", "location", "categories", "coverImageUrl", "services", "availability"]);
  const shop = validateShopFields(body);
  if (!Array.isArray(body.services) || !body.services.length || body.services.length > 20) throw new ApiError(400, "VALIDATION_ERROR", "Provide 1 to 20 services.");
  const services = body.services.map(validateService);
  if (!Array.isArray(body.availability) || !body.availability.length || body.availability.length > 31) throw new ApiError(400, "VALIDATION_ERROR", "Provide 1 to 31 availability dates.");
  const dates = new Set();
  const availability = body.availability.map((day) => {
    requireObject(day); rejectUnknownFields(day, ["date", "slots"]);
    if (!isValidDate(day.date) || dates.has(day.date) || day.date < todayInIndia()) throw new ApiError(400, "VALIDATION_ERROR", "Availability dates must be unique and today or later.");
    dates.add(day.date);
    return {date: day.date, slots: onboardingSlots(day.slots)};
  });
  const readiness = inspectOnboarding(shop, services, availability);
  if (!readiness.complete) throw new ApiError(400, "SHOP_ONBOARDING_INCOMPLETE", readiness.issues.join(" "), {issues: readiness.issues});
  return {shop, services, availability};
}
async function readOnboarding(ref, transaction) {
  const get = (query) => transaction ? transaction.get(query) : query.get();
  const [services, availability] = await Promise.all([
    get(ref.collection("services").limit(101)),
    get(ref.collection("availability").where("date", ">=", todayInIndia()).limit(101)),
  ]);
  return {services: services.docs, availability: availability.docs};
}
function onboardingData(shop, documents) {
  const services = documents.services.map((doc) => ({id: doc.id, ...doc.data()}));
  const availability = documents.availability.map((doc) => ({date: doc.id, ...doc.data()}));
  return {services, availability, onboarding: inspectOnboarding(shop, services, availability)};
}
module.exports = {validateOnboarding, inspectOnboarding, readOnboarding, onboardingData};
