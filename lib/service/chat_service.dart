import 'api_client.dart';

class ChatService {
  ChatService._();

  static Future<int> createConversation({
    required int semesterId,
    String title = 'New conversation',
  }) async {
    final response = await ApiClient.post(
      '/api/conversations',
      body: {
        'semesterId': semesterId,
        'title': title,
      },
    );

    final id = response['id'];

    if (id is! num) {
      throw const FormatException(
        'The server did not return a valid conversation ID.',
      );
    }

    return id.toInt();
  }

  static Future<Map<String, dynamic>> sendMessage({
    required int conversationId,
    required String message,
    String intent = 'ASK_DOUBT',
  }) async {
    final response = await ApiClient.post(
      '/api/conversations/$conversationId/ai/chat',
      body: {
        'messageText': message,
        'intent': intent,
      },
    );

    return response;
  }
}
