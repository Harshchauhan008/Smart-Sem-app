
import '../helper/api_constants.dart';
import 'api_client.dart';

class ProfileService {
  Future<Map<String, dynamic>> getCurrentUser() async {
    return await ApiClient.getObject(
      ApiConstants.currentUser,
    );
  }
}
