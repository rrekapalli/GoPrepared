class UserProfile {
  const UserProfile({
    required this.id,
    this.email,
    this.displayName,
    this.avatarUrl,
    this.locale,
    this.createdAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id']?.toString() ?? json['userId']?.toString() ?? '',
      email: json['email'] as String?,
      displayName: json['displayName'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      locale: json['locale'] as String?,
      createdAt: json['createdAt'] as String?,
    );
  }

  final String id;
  final String? email;
  final String? displayName;
  final String? avatarUrl;
  final String? locale;
  final String? createdAt;
}
