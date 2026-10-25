
import '../helper/api_constants.dart';
import '../model/subject.dart';
import 'api_client.dart';

class SubjectService {
  SubjectService._();

  static Future<List<Subject>> getSubjects(int semesterId) async {
    final data = await ApiClient.getList(
      '${ApiConstants.semesters}/$semesterId/subjects',
    );

    return data.map((item) {
      return Subject.fromJson(
        Map<String, dynamic>.from(item as Map),
      );
    }).toList();
  }
}
