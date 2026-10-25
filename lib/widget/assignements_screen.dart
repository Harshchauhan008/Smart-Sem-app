import 'package:flutter/material.dart';

import '../helper/pref.dart';
import '../model/assignment_model.dart';
import '../model/subject.dart';
import '../service/assignment_service.dart';
import '../service/reminder_service.dart';
import '../service/subject_service.dart';

class AssignmentsScreen extends StatefulWidget {
  final int semesterId;

  const AssignmentsScreen({
    super.key,
    required this.semesterId,
  });

  @override
  State<AssignmentsScreen> createState() => _AssignmentsScreenState();
}

class _AssignmentsScreenState extends State<AssignmentsScreen> {
  bool _loading = true;
  String? _error;
  String _filter = 'ALL';

  List<Subject> _subjects = [];
  List<AssignmentModel> _assignments = [];

  Map<int, String> _subjectNames = {};

  @override
  void initState() {
    super.initState();
    _loadAssignments();
  }

  @override
  void didUpdateWidget(covariant AssignmentsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.semesterId != widget.semesterId) {
      _loadAssignments();
    }
  }


  Future<void> _loadAssignments() async {
    debugPrint('semesterId=${widget.semesterId}, token=${Pref.authToken}');
    if (!mounted) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final subjects = await SubjectService.getSubjects(widget.semesterId);

      // A semester with no subjects has no assignments to fetch.
      if (subjects.isEmpty) {
        if (!mounted) return;

        setState(() {
          _subjects = [];
          _subjectNames = {};
          _assignments = [];
          _loading = false;
        });

        await _syncReminders([]);
        return;
      }

      final subjectNames = <int, String>{
        for (final subject in subjects) subject.id: subject.name,
      };

      final results = await Future.wait(
        subjects.map(
              (subject) => AssignmentService.getAssignments(subject.id),
        ),
      );

      final assignments = results
          .expand((items) => items)
          .toList()
        ..sort((a, b) {
          if (a.deadline == null && b.deadline == null) return 0;
          if (a.deadline == null) return 1;
          if (b.deadline == null) return -1;
          return a.deadline!.compareTo(b.deadline!);
        });

      if (!mounted) return;

      setState(() {
        _subjects = subjects;
        _subjectNames = subjectNames;
        _assignments = assignments;
        _loading = false;
      });

      await _syncReminders(assignments);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }


  Future<void> _syncReminders(List<AssignmentModel> assignments) async {
    try {
      await ReminderService.syncAssignments(assignments);
    } catch (e) {
      // A reminder failure should never break the assignments screen.
      debugPrint('Reminder sync failed: $e');
    }
  }

  List<AssignmentModel> get _filteredAssignments {
    if (_filter == 'ALL') return _assignments;

    if (_filter == 'OVERDUE') {
      return _assignments.where((a) => a.isOverdue).toList();
    }

    return _assignments.where((a) => a.status == _filter).toList();
  }

  int get _pendingCount =>
      _assignments.where((a) => a.isPending && !a.isOverdue).length;

  int get _overdueCount =>
      _assignments.where((a) => a.isOverdue).length;

  int get _submittedCount =>
      _assignments.where((a) => a.isSubmitted || a.isCompleted).length;

  String _formatDate(DateTime? date) {
    if (date == null) return 'No deadline';

    final localDate = date.toLocal();
    final day = localDate.day.toString().padLeft(2, '0');
    final month = localDate.month.toString().padLeft(2, '0');

    return '$day/$month/${localDate.year}';
  }

  Color _statusColor(AssignmentModel assignment) {
    if (assignment.isOverdue) return Colors.red;
    if (assignment.isSubmitted || assignment.isCompleted) {
      return Colors.green;
    }
    return Colors.orange;
  }

  String _statusLabel(AssignmentModel assignment) {
    if (assignment.isOverdue) return 'OVERDUE';
    return assignment.status;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Assignments'),
        actions: [
          IconButton(
            onPressed: _loading ? null : _loadAssignments,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh assignments',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _buildError()
          : RefreshIndicator(
        onRefresh: _loadAssignments,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            _buildSummary(theme),
            const SizedBox(height: 20),
            _buildFilters(),
            const SizedBox(height: 12),
            if (_subjects.isEmpty)
              _buildEmpty(
                Icons.menu_book_outlined,
                'No subjects found',
                'Add subjects to this semester first.',
              )
            else if (_assignments.isEmpty)
              _buildEmpty(
                Icons.assignment_outlined,
                'No assignments yet',
                'Assignments for your subjects will appear here.',
              )
            else if (_filteredAssignments.isEmpty)
                _buildEmpty(
                  Icons.filter_list_off,
                  'No matching assignments',
                  'Try selecting another filter.',
                )
              else
                ..._filteredAssignments.map(_buildAssignmentCard),
          ],
        ),
      ),
    );
  }

  Widget _buildSummary(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: _summaryCard(
            'Pending',
            _pendingCount.toString(),
            Icons.pending_actions,
            Colors.orange,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _summaryCard(
            'Overdue',
            _overdueCount.toString(),
            Icons.warning_amber_rounded,
            Colors.red,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _summaryCard(
            'Submitted',
            _submittedCount.toString(),
            Icons.check_circle_outline,
            Colors.green,
          ),
        ),
      ],
    );
  }

  Widget _summaryCard(
      String label,
      String value,
      IconData icon,
      Color color,
      ) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        child: Column(
          children: [
            Icon(icon, color: color, size: 23),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters() {
    const filters = [
      ('ALL', 'All'),
      ('PENDING', 'Pending'),
      ('SUBMITTED', 'Submitted'),
      ('COMPLETED', 'Completed'),
      ('OVERDUE', 'Overdue'),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((filter) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(filter.$2),
              selected: _filter == filter.$1,
              onSelected: (_) {
                setState(() => _filter = filter.$1);
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAssignmentCard(AssignmentModel assignment) {
    final color = _statusColor(assignment);
    final subjectName =
        _subjectNames[assignment.subjectId] ?? 'Subject';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    assignment.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _statusLabel(assignment),
                    style: TextStyle(
                      color: color,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              subjectName,
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (assignment.description?.trim().isNotEmpty == true) ...[
              const SizedBox(height: 10),
              Text(assignment.description!),
            ],
            const SizedBox(height: 14),
            Row(
              children: [
                const Icon(Icons.calendar_today_outlined, size: 16),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    'Deadline: ${_formatDate(assignment.deadline)}',
                    style: TextStyle(
                      color: assignment.isOverdue ? Colors.red : null,
                      fontWeight:
                      assignment.isOverdue ? FontWeight.w600 : null,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty(
      IconData icon,
      String title,
      String subtitle,
      ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Icon(icon, size: 48, color: Colors.grey),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              size: 48,
              color: Colors.red,
            ),
            const SizedBox(height: 12),
            const Text(
              'Could not load assignments',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _loadAssignments,
              icon: const Icon(Icons.refresh),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}