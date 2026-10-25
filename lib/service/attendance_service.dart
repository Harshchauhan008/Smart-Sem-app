
import '../helper/api_constants.dart';
import '../model/attendance_record.dart';
import 'api_client.dart';

class AttendanceService {
  AttendanceService._();

  static Future<double> getAttendancePercentage(int subjectId) async {
    final response = await ApiClient.getObject(
      '${ApiConstants.subjects}/$subjectId/attendance/percentage',
    );

    final value = response['attendancePercentage'];

    if (value is num) {
      return value.toDouble();
    }

    throw const FormatException(
      'Attendance percentage is missing from the response.',
    );
  }

  static Future<List<AttendanceRecord>> getAttendanceBySubject(
      int subjectId,
      ) async {
    final response = await ApiClient.getList(
      '${ApiConstants.subjects}/$subjectId/attendance',
    );

    return response
        .map(
          (json) => AttendanceRecord.fromJson(
        Map<String, dynamic>.from(json),
      ),
    )
        .toList();
  }

  static Future<AttendanceRecord> markAttendance({
    required int subjectId,
    required DateTime classDate,
    required int timetableEntryId,
    required String status,
    String? notes,
  }) async {
    final normalizedStatus = status.toUpperCase();

    if (normalizedStatus != 'PRESENT' &&
        normalizedStatus != 'ABSENT') {
      throw ArgumentError('Status must be PRESENT or ABSENT.');
    }

    final response = await ApiClient.post(
      '${ApiConstants.subjects}/$subjectId/attendance',
      body: {
        'classDate':
        '${classDate.year.toString().padLeft(4, '0')}-'
            '${classDate.month.toString().padLeft(2, '0')}-'
            '${classDate.day.toString().padLeft(2, '0')}',
        'timetableEntryId': timetableEntryId,
        'status': normalizedStatus,
        if (notes != null && notes.trim().isNotEmpty)
          'notes': notes.trim(),
      },
    );

    return AttendanceRecord.fromJson(response);
  }
}
