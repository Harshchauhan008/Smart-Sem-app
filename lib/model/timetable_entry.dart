
class TimetableEntry {
  final int id;
  final int subjectId;
  final int dayOfWeek;
  final String startTime;
  final String endTime;
  final String? room;
  final String classType;

  const TimetableEntry({
    required this.id,
    required this.subjectId,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    this.room,
    required this.classType,
  });

  factory TimetableEntry.fromJson(Map<String, dynamic> json) {
    return TimetableEntry(
      id: (json['id'] as num).toInt(),
      subjectId: (json['subjectId'] as num).toInt(),
      dayOfWeek: (json['dayOfWeek'] as num).toInt(),
      startTime: json['startTime']?.toString() ?? '',
      endTime: json['endTime']?.toString() ?? '',
      room: json['room']?.toString(),
      classType: json['classType']?.toString() ?? 'LECTURE',
    );
  }

  String get dayName {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];

    if (dayOfWeek < 1 || dayOfWeek > 7) {
      return 'Unknown day';
    }

    return days[dayOfWeek - 1];
  }
}
