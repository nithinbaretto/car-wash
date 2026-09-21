

const crypto = require("node:crypto");

function requestId(request) {
  const incoming = request.get("x-correlation-id") || request.get("x-request-id");
  return incoming && /^[A-Za-z0-9_-]{1,128}$/.test(incoming) ? incoming : crypto.randomUUID();
}

module.exports = {requestId};
