import '../model/assignment_model.dart';
import 'api_client.dart';

class AssignmentService {
  AssignmentService._();

  /// Fetch assignments for one subject.
  static Future<List<AssignmentModel>> getAssignments(
      int subjectId, {
        String? status,
      }) async {
    var endpoint = '/api/subjects/$subjectId/assignments';

    if (status != null && status.isNotEmpty) {
      endpoint += '?status=${Uri.encodeQueryComponent(status)}';
    }

    final data = await ApiClient.getList(endpoint);

    return data.map((item) {
      return AssignmentModel.fromJson(
        Map<String, dynamic>.from(item as Map),
      );
    }).toList();
  }

  /// Create an assignment for a subject.
  static Future<AssignmentModel> createAssignment({
    required int subjectId,
    required String title,
    String? description,
    DateTime? deadline,
  }) async {
    final body = <String, dynamic>{
      'title': title.trim(),
      'description': description?.trim(),
      'status': 'PENDING',
    };

    if (deadline != null) {
      body['deadline'] = deadline.toIso8601String();
    }

    final response = await ApiClient.post(
      '/api/subjects/$subjectId/assignments',
      body: body,
    );

    return AssignmentModel.fromJson(response);
  }

  /// Save submission metadata for an assignment.
  ///
  /// Note: this endpoint does not upload file bytes. The filePath
  /// must refer to a file already stored somewhere accessible.
  static Future<Map<String, dynamic>> submitAssignment({
    required int assignmentId,
    required String fileName,
    required String filePath,
    String? remarks,
  }) async {
    return ApiClient.post(
      '/api/assignments/$assignmentId/submissions',
      body: {
        'fileName': fileName,
        'filePath': filePath,
        'remarks': remarks,
      },
    );
  }
}
