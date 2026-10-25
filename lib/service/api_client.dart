import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../helper/api_constants.dart';
import '../helper/pref.dart';

class ApiClient {
  ApiClient._();

  static const Duration requestTimeout = Duration(seconds: 60);
  static const Duration uploadTimeout = Duration(seconds: 120);

  static Map<String, String> _headers({
    bool jsonBody = false,
    bool includeAuth = true,
  }) {
    final headers = <String, String>{'Accept': 'application/json'};

    if (includeAuth) {
      final token = Pref.authToken;
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    if (jsonBody) {
      headers['Content-Type'] = 'application/json';
    }

    return headers;
  }

  static Future<Map<String, dynamic>> post(
    String endpoint, {
    required Map<String, dynamic> body,
  }) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}$endpoint');

    final response = await http
        .post(
          uri,
          headers: _headers(
            jsonBody: true,
            includeAuth:
                endpoint != ApiConstants.login &&
                endpoint != ApiConstants.register,
          ),
          body: jsonEncode(body),
        )
        .timeout(requestTimeout);

    return _decodeObjectResponse(response);
  }

  static Future<List<dynamic>> getList(String endpoint) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}$endpoint');

    final response = await http
        .get(uri, headers: _headers())
        .timeout(requestTimeout);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Failed to load data (${response.statusCode}): ${response.body}',
      );
    }

    final decoded = jsonDecode(response.body);

    if (decoded is! List) {
      throw const FormatException('Expected a list from the server.');
    }

    return decoded;
  }

  static Future<Map<String, dynamic>> getObject(String endpoint) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}$endpoint');

    final response = await http
        .get(uri, headers: _headers())
        .timeout(requestTimeout);

    return _decodeObjectResponse(response);
  }

  // Returns the MIME type based on the uploaded file extension.
  static String _mimeFor(String fileName) {
    final name = fileName.toLowerCase();

    if (name.endsWith('.pdf')) return 'application/pdf';
    if (name.endsWith('.png')) return 'image/png';
    return 'image/jpeg';
  }

  static Future<Map<String, dynamic>> uploadDocument({
    required int semesterId,
    required String fileName,
    required Uint8List bytes,
    String documentType = 'OTHER',
  }) async {
    final token = Pref.authToken;

    if (token == null || token.isEmpty) {
      throw Exception('Your session has expired. Please log in again.');
    }

    final uri = Uri.parse(
      '${ApiConstants.baseUrl}/api/semesters/$semesterId/documents',
    );

    final request = http.MultipartRequest('POST', uri);

    request.headers['Accept'] = 'application/json';
    request.headers['Authorization'] = 'Bearer $token';
    request.fields['documentType'] = documentType;

    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: fileName,
        contentType: MediaType.parse(_mimeFor(fileName)),
      ),
    );

    final streamedResponse = await request.send().timeout(uploadTimeout);

    // Also apply the timeout while reading the response body.
    final response = await http.Response.fromStream(
      streamedResponse,
    ).timeout(uploadTimeout);

    return _decodeObjectResponse(response);
  }

  static Map<String, dynamic> _decodeObjectResponse(http.Response response) {
    dynamic decoded;

    try {
      decoded = response.body.isEmpty
          ? <String, dynamic>{}
          : jsonDecode(response.body);
    } on FormatException {
      throw Exception(
        'Server returned non-JSON data '
        '(HTTP ${response.statusCode}): ${response.body}',
      );
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = decoded is Map<String, dynamic>
          ? decoded['message']?.toString() ??
                decoded['error']?.toString() ??
                'Request failed (${response.statusCode})'
          : 'Request failed (${response.statusCode}): ${response.body}';

      throw Exception(message);
    }

    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Unexpected server response.');
    }

    return decoded;
  }

  static Future<dynamic> put(
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    final headers = _headers(jsonBody: body != null);

    final response = await http
        .put(
          Uri.parse('${ApiConstants.baseUrl}$endpoint'),
          headers: headers,
          body: body == null ? null : jsonEncode(body),
        )
        .timeout(requestTimeout);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return jsonDecode(response.body);
    }

    throw Exception(
      'PUT request failed (${response.statusCode}): ${response.body}',
    );
  }

  static Future<Map<String, dynamic>> patch(
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    final response = await http
        .patch(
          Uri.parse('${ApiConstants.baseUrl}$endpoint'),
          headers: _headers(jsonBody: body != null),
          body: body == null ? null : jsonEncode(body),
        )
        .timeout(requestTimeout);

    return _decodeObjectResponse(response);
  }
}
