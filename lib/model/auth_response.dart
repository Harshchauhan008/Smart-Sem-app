
class AuthResponse {
  final String token;
  final int? userId;
  final String? name;
  final String? email;

  const AuthResponse({
    required this.token,
    this.userId,
    this.name,
    this.email,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      token: json['token'] as String,
      userId: (json['userId'] as num?)?.toInt(),
      name: (json['name'] ?? json['fullName']) as String?,
      email: json['email'] as String?,
    );
  }
}
