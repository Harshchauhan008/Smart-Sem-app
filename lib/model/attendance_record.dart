
class AttendanceRecord {
  final int id;
  final int subjectId;
  final int? timetableEntryId;
  final DateTime classDate;
  final String status;
  final String? notes;

  const AttendanceRecord({
    required this.id,
    required this.subjectId,
    required this.timetableEntryId,
    required this.classDate,
    required this.status,
    this.notes,
  });

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceRecord(
      id: (json['id'] as num).toInt(),
      subjectId: (json['subjectId'] as num).toInt(),
      timetableEntryId: json['timetableEntryId'] == null
          ? null
          : (json['timetableEntryId'] as num).toInt(),
      classDate: DateTime.parse(json['classDate'].toString()),
      status: json['status'].toString(),
      notes: json['notes']?.toString(),
    );
  }
}
