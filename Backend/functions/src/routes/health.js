const {Router} = require("express");
const {requestId} = require("../middleware/request-id");

const router = Router();

router.get("/health", (request, response) => {
  response.status(200).json({
    success: true,
    data: {message: "Car Wash API is running", timestamp: new Date().toISOString()},
    requestId: request.requestId,
  });
});

// Firebase Authentication owns Phone OTP, Google, and Apple authentication.
// This route creates a Firestore profile after authentication succeeds.

module.exports = router;
