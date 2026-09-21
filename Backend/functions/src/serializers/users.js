

function serializeUser(user) {
  return {
    uid: user.uid,
    displayName: user.displayName,
    phoneNumber: user.phoneNumber || null,
    email: user.email || null,
    photoUrl: user.photoUrl || null,
    roles: user.roles,
    activeRole: user.activeRole,
    terms: user.terms,
    privacy: user.privacy,
    createdAt: user.createdAt,
    updatedAt: user.updatedAt,
  };
}

module.exports = {serializeUser};
