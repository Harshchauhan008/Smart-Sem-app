
class AssignmentModel {
  final int id;
  final int subjectId;
  final String title;
  final String? description;
  final DateTime? assignedAt;
  final DateTime? deadline;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const AssignmentModel({
    required this.id,
    required this.subjectId,
    required this.title,
    this.description,
    this.assignedAt,
    this.deadline,
    required this.status,
    this.createdAt,
    this.updatedAt,
  });

  factory AssignmentModel.fromJson(Map<String, dynamic> json) {
    return AssignmentModel(
      id: _toInt(json['id']),
      subjectId: _toInt(json['subjectId'] ?? json['subject_id']),
      title: json['title']?.toString() ?? 'Untitled assignment',
      description: json['description']?.toString(),
      assignedAt: _toDate(json['assignedAt'] ?? json['assigned_at']),
      deadline: _toDate(json['deadline']),
      status: (json['status']?.toString() ?? 'PENDING').toUpperCase(),
      createdAt: _toDate(json['createdAt'] ?? json['created_at']),
      updatedAt: _toDate(json['updatedAt'] ?? json['updated_at']),
    );
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static DateTime? _toDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString())?.toLocal();
  }

  bool get isPending => status == 'PENDING';

  bool get isSubmitted => status == 'SUBMITTED';

  bool get isCompleted => status == 'COMPLETED';

  bool get isOverdue {
    if (deadline == null || !isPending) return false;
    return deadline!.isBefore(DateTime.now());
  }
}
