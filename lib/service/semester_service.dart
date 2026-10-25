
import 'package:http/http.dart';

import '../helper/api_constants.dart';
import '../model/semester.dart';
import 'api_client.dart';

class SemesterService {
  SemesterService._();

  static Future<List<Semester>> getSemesters() async {
    final data = await ApiClient.getList(
      ApiConstants.semesters,
    );

    return data
        .map(
          (item) => Semester.fromJson(
        Map<String, dynamic>.from(item as Map),
      ),
    )
        .toList();
  }

  static Future<Semester> createSemester({
    required String name,
    required String academicYear,
    required int semesterNumber,
    required String startDate,
    required String endDate,
  }) async {
    final data = await ApiClient.post(
      ApiConstants.semesters,
      body: {
        'name': name,
        'academicYear': academicYear,
        'semesterNumber': semesterNumber,
        'startDate': startDate,
        'endDate': endDate,
        'active': true,
      },
    );

    return Semester.fromJson(data);
  }

  static Future<void> activateSemester(int semesterId) async {
    await ApiClient.put(
      '${ApiConstants.semesters}/$semesterId/activate',
    );
  }

}
