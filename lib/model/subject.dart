
class Subject {
  final int id;
  final int semesterId;
  final String name;
  final String? subjectCode;
  final String? facultyName;
  final double? attendanceRequired;

  const Subject({
    required this.id,
    required this.semesterId,
    required this.name,
    this.subjectCode,
    this.facultyName,
    this.attendanceRequired,
  });

  factory Subject.fromJson(Map<String, dynamic> json) {
    return Subject(
      id: (json['id'] as num).toInt(),
      semesterId: (json['semesterId'] as num).toInt(),
      name: json['name']?.toString() ?? 'Untitled subject',
      subjectCode: json['subjectCode']?.toString(),
      facultyName: json['facultyName']?.toString(),
      attendanceRequired: (json['attendanceRequired'] as num?)?.toDouble(),
    );
  }
}
