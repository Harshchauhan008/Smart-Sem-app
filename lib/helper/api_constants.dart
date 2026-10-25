
class ApiConstants {
  ApiConstants._();

  // Deployed SmartSem Spring Boot backend on Render
  static const String baseUrl =
      'https://smart-sem-backend.onrender.com';

  static const String login = '/api/auth/login';
  static const String register = '/api/auth/register';
  static const String semesters = '/api/semesters';
  static const String subjects = '/api/subjects';
  static const String currentUser = '/api/users/me';
  static const String changePassword = '/api/auth/change-password';
  static const String notifications = '/api/notifications';
}
