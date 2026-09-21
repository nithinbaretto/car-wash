const {requestId} = require("../middleware/request-id");
const {admin} = require("../config/firebase");

function auditRecord(request, action, resourceType, resourceId, details = {}) {
  return {
    actorUid: request.auth.uid, action, resourceType, resourceId,
    requestId: request.requestId, details, createdAt: admin.firestore.Timestamp.now(),
  };
}

module.exports = {auditRecord};
