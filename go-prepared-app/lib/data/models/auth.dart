class AuthResponse {
  const AuthResponse({
    required this.accessToken,
    this.refreshToken,
    this.tokenType = 'Bearer',
    this.expiresIn,
    this.userId,
    this.email,
    this.displayName,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      accessToken: json['accessToken'] as String? ?? json['token'] as String,
      refreshToken: json['refreshToken'] as String?,
      tokenType: json['tokenType'] as String? ?? 'Bearer',
      expiresIn: json['expiresIn'] as int?,
      userId: json['userId'] as String?,
      email: json['email'] as String?,
      displayName: json['displayName'] as String?,
    );
  }

  final String accessToken;
  final String? refreshToken;
  final String tokenType;
  final int? expiresIn;
  final String? userId;
  final String? email;
  final String? displayName;
}

class GoogleAuthRequest {
  const GoogleAuthRequest({required this.idToken});

  Map<String, dynamic> toJson() => {'idToken': idToken};

  final String idToken;
}

class RefreshTokenRequest {
  const RefreshTokenRequest({required this.refreshToken});

  Map<String, dynamic> toJson() => {'refreshToken': refreshToken};

  final String refreshToken;
}

class DevLoginRequest {
  const DevLoginRequest({
    this.email = 'dev@goprepared.local',
    this.displayName = 'Dev User',
  });

  Map<String, dynamic> toJson() => {
        'email': email,
        'displayName': displayName,
      };

  final String email;
  final String displayName;
}
