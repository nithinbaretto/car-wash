const {onRequest} = require("firebase-functions/v2/https");
const app = require("./src/app");

exports.api = onRequest({region: "asia-south1", cors: true}, app);
