class UserProfile {
  UserProfile({
    required this.uid,
    required this.displayName,
    this.phoneNumber,
    this.email,
    this.photoUrl,
    this.roles = const ['customer'],
    this.activeRole = 'customer',
    this.terms,
    this.privacy,
    this.createdAt,
    this.updatedAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      uid: json['uid']?.toString() ?? '',
      displayName: json['displayName']?.toString() ?? '',
      phoneNumber: json['phoneNumber']?.toString(),
      email: json['email']?.toString(),
      photoUrl: json['photoUrl']?.toString(),
      roles: (json['roles'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const ['customer'],
      activeRole: json['activeRole']?.toString() ?? 'customer',
      terms: json['terms'] is Map<String, dynamic>
          ? json['terms'] as Map<String, dynamic>
          : null,
      privacy: json['privacy'] is Map<String, dynamic>
          ? json['privacy'] as Map<String, dynamic>
          : null,
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
    );
  }

  final String uid;
  final String displayName;
  final String? phoneNumber;
  final String? email;
  final String? photoUrl;
  final List<String> roles;
  final String activeRole;
  final Map<String, dynamic>? terms;
  final Map<String, dynamic>? privacy;
  final dynamic createdAt;
  final dynamic updatedAt;

  bool get isOwner => roles.contains('owner');
  bool get isCustomer => roles.contains('customer');
  bool get isActiveOwner => activeRole == 'owner';

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'displayName': displayName,
      'phoneNumber': phoneNumber,
      'email': email,
      'photoUrl': photoUrl,
      'roles': roles,
      'activeRole': activeRole,
      'terms': terms,
      'privacy': privacy,
    };
  }

  UserProfile copyWith({
    String? displayName,
    String? phoneNumber,
    String? email,
    String? photoUrl,
    List<String>? roles,
    String? activeRole,
  }) {
    return UserProfile(
      uid: uid,
      displayName: displayName ?? this.displayName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      roles: roles ?? this.roles,
      activeRole: activeRole ?? this.activeRole,
      terms: terms,
      privacy: privacy,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
