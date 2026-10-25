class Semester {
  final int id;
  final int? userId;
  final String name;
  final String? academicYear;
  final int? semesterNumber;
  final String? startDate;
  final String? endDate;
  final bool active;

  const Semester({
    required this.id,
    this.userId,
    required this.name,
    this.academicYear,
    this.semesterNumber,
    this.startDate,
    this.endDate,
    this.active = false,
  });

  factory Semester.fromJson(Map<String, dynamic> json) {
    return Semester(
      id: (json['id'] as num).toInt(),
      userId: (json['userId'] as num?)?.toInt(),
      name: json['name']?.toString() ?? 'Semester',
      academicYear: json['academicYear']?.toString(),
      semesterNumber: (json['semesterNumber'] as num?)?.toInt(),
      startDate: json['startDate']?.toString(),
      endDate: json['endDate']?.toString(),
      active: json['active'] as bool? ?? false,
    );
  }
}
