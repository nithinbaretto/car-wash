

function bookingSummary(id, booking) {
  return {id, carWashId: booking.carWashId, status: booking.status, scheduledDate: booking.availabilityDate,
    startAt: booking.slotStartAt, endAt: booking.slotEndAt, priceMinor: booking.priceMinor, currency: booking.currency,
    carWash: booking.carWashSnapshot, service: booking.serviceSnapshot, vehicle: booking.vehicleSnapshot || null,
    createdAt: booking.createdAt, updatedAt: booking.updatedAt};
}

module.exports = {bookingSummary};
