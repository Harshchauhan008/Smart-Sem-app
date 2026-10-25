import 'package:flutter/material.dart';

import '../model/attendance_record.dart';
import '../model/subject.dart';
import '../model/timetable_entry.dart';
import '../service/attendance_service.dart';
import '../service/subject_service.dart';
import '../service/timetable_service.dart';

class AttendanceMarkingScreen extends StatefulWidget {
  final int semesterId;

  const AttendanceMarkingScreen({super.key, required this.semesterId});

  @override
  State<AttendanceMarkingScreen> createState() =>
      _AttendanceMarkingScreenState();
}

class _AttendanceMarkingScreenState extends State<AttendanceMarkingScreen> {
  bool _loading = true;
  String? _error;

  List<Subject> _subjects = [];
  Subject? _selectedSubject;
  List<TimetableEntry> _timetable = [];
  List<AttendanceRecord> _records = [];

  DateTime _selectedDate = DateTime.now();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadSubjects();
  }

  Future<void> _loadSubjects() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final subjects = await SubjectService.getSubjects(widget.semesterId);

      if (!mounted) return;

      setState(() {
        _subjects = subjects;
        _selectedSubject = subjects.isNotEmpty ? subjects.first : null;
      });

      if (_selectedSubject != null) {
        await _loadSubjectData(_selectedSubject!);
      } else {
        setState(() => _loading = false);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _loadSubjectData(Subject subject) async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        TimetableService.getSubjectTimetable(subject.id),
        AttendanceService.getAttendanceBySubject(subject.id),
      ]);

      if (!mounted) return;

      setState(() {
        _timetable = results[0] as List<TimetableEntry>;
        _records = results[1] as List<AttendanceRecord>;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _selectSubject(Subject? subject) async {
    if (subject == null || _saving) return;

    setState(() {
      _selectedSubject = subject;
    });

    await _loadSubjectData(subject);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked != null && mounted) {
      setState(() => _selectedDate = picked);
    }
  }

  bool _sameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  AttendanceRecord? _recordFor(TimetableEntry entry) {
    for (final record in _records) {
      if (record.timetableEntryId == entry.id &&
          _sameDate(record.classDate, _selectedDate)) {
        return record;
      }
    }
    return null;
  }

  Future<void> _markAttendance(TimetableEntry entry, String status) async {
    final subject = _selectedSubject;
    if (subject == null || _saving) return;

    if (_selectedDate.isAfter(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Attendance cannot be marked for a future date.'),
        ),
      );
      return;
    }

    final existing = _recordFor(entry);

    if (existing != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'This class already has a ${existing.status.toLowerCase()} record.',
          ),
        ),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final saved = await AttendanceService.markAttendance(
        subjectId: subject.id,
        classDate: _selectedDate,
        timetableEntryId: entry.id,
        status: status,
      );

      if (!mounted) return;

      setState(() {
        _records = [..._records, saved];
        _saving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Attendance marked $status successfully.')),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() => _saving = false);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not mark attendance: $e')));

      // Reload in case the server saved the record before an error occurred.
      await _loadSubjectData(subject);
    }
  }

  int _countStatus(String status) {
    return _records
        .where((record) => record.status.toUpperCase() == status)
        .length;
  }

  @override
  Widget build(BuildContext context) {
    final subject = _selectedSubject;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loading ? null : _loadSubjects,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _buildError()
          : _subjects.isEmpty
          ? const Center(child: Text('No subjects found for this semester.'))
          : _buildContent(subject!),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            const Text(
              'Could not load attendance data.',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _loadSubjects,
              icon: const Icon(Icons.refresh),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(Subject subject) {
    final present = _countStatus('PRESENT');
    final absent = _countStatus('ABSENT');
    final cancelled = _countStatus('CANCELLED');

    final classes =
        _timetable
            .where((entry) => entry.dayOfWeek == _selectedDate.weekday)
            .toList()
          ..sort((a, b) => a.startTime.compareTo(b.startTime));

    return RefreshIndicator(
      onRefresh: _loadSubjects,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          DropdownButtonFormField<Subject>(
            initialValue: subject,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Subject',
              border: OutlineInputBorder(),
            ),
            items: _subjects.map((item) {
              return DropdownMenuItem<Subject>(
                value: item,
                child: Text(item.name),
              );
            }).toList(),
            onChanged: _saving ? null : _selectSubject,
          ),
          const SizedBox(height: 16),

          OutlinedButton.icon(
            onPressed: _pickDate,
            icon: const Icon(Icons.calendar_month),
            label: Text(
              'Date: ${_selectedDate.day.toString().padLeft(2, '0')}/'
              '${_selectedDate.month.toString().padLeft(2, '0')}/'
              '${_selectedDate.year}',
            ),
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _SummaryTile(
                  title: 'Present',
                  count: present,
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SummaryTile(
                  title: 'Absent',
                  count: absent,
                  color: Colors.red,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SummaryTile(
                  title: 'Cancelled',
                  count: cancelled,
                  color: Colors.orange,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          Text(
            'Classes on ${_selectedDate.weekday == 1
                ? 'Monday'
                : _selectedDate.weekday == 2
                ? 'Tuesday'
                : _selectedDate.weekday == 3
                ? 'Wednesday'
                : _selectedDate.weekday == 4
                ? 'Thursday'
                : _selectedDate.weekday == 5
                ? 'Friday'
                : _selectedDate.weekday == 6
                ? 'Saturday'
                : 'Sunday'}',
            style: Theme.of(context).textTheme.titleLarge,
          ),

          const SizedBox(height: 8),

          if (classes.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text('No timetable classes are scheduled for this day.'),
              ),
            )
          else
            ...classes.map(_buildClassCard),

          const SizedBox(height: 20),

          const Text(
            'Note: Overall semester attendance analytics will be shown in the Attendance Overview screen.',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildClassCard(TimetableEntry entry) {
    final record = _recordFor(entry);
    final status = record?.status.toUpperCase();

    final isCancelled = status == 'CANCELLED';
    final isMarked = record != null;

    Color statusColor;
    if (status == 'PRESENT') {
      statusColor = Colors.green;
    } else if (status == 'ABSENT') {
      statusColor = Colors.red;
    } else if (isCancelled) {
      statusColor = Colors.orange;
    } else {
      statusColor = Colors.grey;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.menu_book_outlined),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${entry.startTime} - ${entry.endTime}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                if (isMarked)
                  Chip(
                    label: Text(status ?? ''),
                    backgroundColor: statusColor.withValues(alpha: 0.12),
                    side: BorderSide(color: statusColor),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text('Type: ${entry.classType}'),
            if (entry.room != null && entry.room!.isNotEmpty)
              Text('Room: ${entry.room}'),
            if (record?.notes != null && record!.notes!.isNotEmpty)
              Text('Note: ${record.notes}'),

            const SizedBox(height: 12),

            if (isCancelled)
              const Text(
                'This class was cancelled.',
                style: TextStyle(color: Colors.orange),
              )
            else if (isMarked)
              const Text('Attendance already recorded.')
            else
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _saving
                          ? null
                          : () => _markAttendance(entry, 'PRESENT'),
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text('Present'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _saving
                          ? null
                          : () => _markAttendance(entry, 'ABSENT'),
                      icon: const Icon(Icons.cancel_outlined),
                      label: const Text('Absent'),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  final String title;
  final int count;
  final Color color;

  const _SummaryTile({
    required this.title,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
        child: Column(
          children: [
            Text(
              '$count',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(title, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
