const {admin} = require("../config/firebase");

function bookingState(status) {
  if (["pending", "accepted", "in_progress"].includes(status)) return "ongoing";
  if (status === "completed") return "completed";
  return "cancelled";
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

module.exports = {bookingState, notificationForStatus};
