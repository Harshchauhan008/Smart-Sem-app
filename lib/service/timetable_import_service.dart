import 'dart:convert';

import 'package:http/http.dart' as http;

// TODO: adjust these two import paths to where ApiConstants and Pref live
// in your project (use the IDE quick-fix if they show red).
import '../helper/api_constants.dart';
import '../helper/pref.dart';

class TimetableImportService {
  TimetableImportService._();

  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer ${Pref.authToken}',
  };

  /// Asks the backend to read the latest uploaded timetable image.
  /// Nothing is saved: it only returns the classes it found.
  static Future<List<Map<String, dynamic>>> preview(int semesterId) async {
    final response = await http
        .post(
      Uri.parse(
        '${ApiConstants.baseUrl}/api/semesters/$semesterId'
            '/timetable-extraction/preview',
      ),
      headers: _headers,
    )
    // Gemini reads the image, so allow time.
        .timeout(const Duration(seconds: 120));

    final data = _decode(response);

    final entries = data is Map ? data['entries'] : null;

    if (entries is! List) {
      throw Exception('The timetable could not be read. Please try again.');
    }

    return entries
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  /// Saves the entries the student approved. Returns how many were saved.
  /// [subjectId] can be any subject of the semester; the backend maps each
  /// entry to its own subject by name.
  static Future<int> importEntries(
      int subjectId,
      List<Map<String, dynamic>> entries,
      ) async {
    final body = entries.map((e) {
      final copy = Map<String, dynamic>.from(e);
      copy.remove('confidence'); // not part of the import request
      return copy;
    }).toList();

    final response = await http
        .post(
      Uri.parse(
        '${ApiConstants.baseUrl}/api/subjects/$subjectId/timetable/import',
      ),
      headers: _headers,
      body: jsonEncode(body),
    )
        .timeout(const Duration(seconds: 30));

    final data = _decode(response);

    return data is Map ? (data['saved'] as num?)?.toInt() ?? 0 : 0;
  }

  static dynamic _decode(http.Response response) {
    dynamic data;

    try {
      data = response.body.isEmpty ? null : jsonDecode(response.body);
    } catch (_) {
      data = null;
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = data is Map ? data['message'] : null;

      throw Exception(
        message is String && message.isNotEmpty
            ? message
            : 'Request failed (${response.statusCode}).',
      );
    }

    return data;
  }
}