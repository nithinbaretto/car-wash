const {bookingSummary} = require("./bookings");
const {serializeShop} = require("./shops");

function adminUser(id, user) {
  return {uid: id, displayName: user.displayName, email: user.email || null,
    phoneNumber: user.phoneNumber || null, photoUrl: user.photoUrl || null,
    roles: user.roles || [], activeRole: user.activeRole || null,
    accountStatus: user.accountStatus || "active", createdAt: user.createdAt,
    updatedAt: user.updatedAt};
}

function adminShop(id, shop) {
  return {...serializeShop(id, shop), ownerUids: shop.ownerUids || [], review: shop.review || null,
    rating: {average: shop.ratingAverage || 0, count: shop.ratingCount || 0},
    startingPriceMinor: shop.minPriceMinor || null, currency: shop.currency || "INR"};
}

function adminBooking(id, booking) {
  return {...bookingSummary(id, booking), customerId: booking.customerId,
    availabilityDate: booking.availabilityDate, scheduledAt: booking.scheduledAt,
    timezone: booking.timezone || "Asia/Kolkata", customer: booking.customerSnapshot || null,
    statusUpdatedBy: booking.statusUpdatedBy || null,
    acceptedAt: booking.acceptedAt || null, rejectedAt: booking.rejectedAt || null,
    cancelledAt: booking.cancelledAt || null, inProgressAt: booking.in_progressAt || null,
    completedAt: booking.completedAt || null};
}

module.exports = {adminUser, adminShop, adminBooking};
