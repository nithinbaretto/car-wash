const express = require("express");
const cors = require("cors");
const {ApiError} = require("./utils/api-error");
const {requestId} = require("./middleware/request-id");
const {notFound, errorHandler} = require("./middleware/errors");

const app = express();

// Hosting forwards the full /api URL; direct Cloud Functions URLs keep /v1.
app.use((request, _response, next) => {
  if (request.url === "/api" || request.url.startsWith("/api/")) {
    request.url = request.url.slice(4) || "/";
  }
  next();
});
app.use(cors({origin: true}));
app.use((request, response, next) => {
  request.requestId = requestId(request);
  response.set("x-correlation-id", request.requestId);
  next();
});
// Up to 31 days of slot definitions may exceed the default small API body.
app.use(/^\/v1\/owner\/car-washes(?:\/[^/]+)?\/onboarding$/, express.json({limit: "512kb"}));
app.use(express.json({limit: "32kb"}));
app.use((error, _request, _response, next) => {
  if (error instanceof SyntaxError && error.status === 400 && "body" in error) {
    next(new ApiError(400, "INVALID_JSON", "Request body must be valid JSON."));
    return;
  }
  next(error);
});


app.use(require("./routes/health"));
app.use(require("./routes/users"));
app.use(require("./routes/discovery"));
app.use(require("./routes/favourites"));
app.use(require("./routes/bookings"));
app.use(require("./routes/notifications"));
app.use(require("./routes/admin"));
app.use(require("./routes/shop-onboarding"));
app.use(require("./routes/owner-shops"));
app.use(require("./routes/owner-operations"));

app.use(notFound);
app.use(errorHandler);

module.exports = app;
