import '../helper/api_constants.dart';
import '../helper/pref.dart';
import '../model/auth_response.dart';
import '../service/api_client.dart';

class AuthService {
  AuthService._();

  static Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    final response = await ApiClient.post(
      ApiConstants.login,
      body: {
        'email': email.trim(),
        'password': password,
      },
    );

    return AuthResponse.fromJson(response);
  }


  static Future<AuthResponse> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final response = await ApiClient.post(
      ApiConstants.register,
      body: {
        'fullName': name.trim(),
        'email': email.trim(),
        'password': password,
      },
    );

    final authResponse = AuthResponse.fromJson(response);

    if (authResponse.token.isEmpty) {
      throw Exception('Registration succeeded but no authentication token was returned.');
    }

    Pref.authToken = authResponse.token;
    Pref.userEmail = authResponse.email ?? email.trim();

    return authResponse;
  }



  static Future<void> logout() async {
    Pref.authToken = null;
    Pref.userEmail = null;
  }

  static Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await ApiClient.post(
      ApiConstants.changePassword,
      body: {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      },
    );
  }

}
