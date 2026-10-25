
import '../helper/api_constants.dart';
import '../model/timetable_entry.dart';
import 'api_client.dart';

class TimetableService {
  TimetableService._();

  static Future<List<TimetableEntry>> getSubjectTimetable(
      int subjectId,
      ) async {
    final data = await ApiClient.getList(
      '${ApiConstants.subjects}/$subjectId/timetable',
    );

    return data
        .map(
          (item) => TimetableEntry.fromJson(
        Map<String, dynamic>.from(item as Map),
      ),
    )
        .toList();
  }
}
