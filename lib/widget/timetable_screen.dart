
import 'package:flutter/material.dart';
import 'package:smartsem/widget/timetable_review_screen.dart';

import '../model/attendance_record.dart';
import '../model/semester.dart';
import '../model/subject.dart';
import '../model/timetable_entry.dart';
import '../service/attendance_service.dart';
import '../service/semester_service.dart';
import '../service/subject_service.dart';
import '../service/timetable_import_service.dart';
import '../service/timetable_service.dart';

class TimetableScreen extends StatefulWidget {
  const TimetableScreen({super.key});

  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen> {
  bool _loading = true;
  String? _error;

  DateTime _selectedDate = DateTime.now();

  final Map<int, List<TimetableEntry>> _entriesByDay = {};
  final Map<int, String> _subjectNames = {};
  final Map<String, AttendanceRecord> _attendanceBySlotDate = {};

  static const List<String> _days = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  int get _selectedDay => _selectedDate.weekday;

  String _dateKey(DateTime date) {
    final d = date.toLocal();
    final year = d.year.toString().padLeft(4, '0');
    final month = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  String _slotDateKey(int timetableEntryId, DateTime date) {
    return '$timetableEntryId|${_dateKey(date)}';
  }

  @override
  void initState() {
    super.initState();
    _loadTimetable();
  }

  Future<void> _loadTimetable() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final List<Semester> semesters =
      await SemesterService.getSemesters();

      if (semesters.isEmpty) {
        if (!mounted) return;
        setState(() {
          _entriesByDay.clear();
          _subjectNames.clear();
          _attendanceBySlotDate.clear();
          _loading = false;
        });
        return;
      }

      final activeSemesters =
      semesters.where((semester) => semester.active).toList();

      final semester =
      activeSemesters.isNotEmpty ? activeSemesters.first : semesters.first;

      final List<Subject> subjects =
      await SubjectService.getSubjects(semester.id);

      final Map<int, List<TimetableEntry>> grouped = {};
      final Map<int, String> names = {};
      final Map<String, AttendanceRecord> attendanceMap = {};

      for (final subject in subjects) {
        names[subject.id] = subject.name;

        final timetableEntries =
        await TimetableService.getSubjectTimetable(subject.id);

        for (final entry in timetableEntries) {
          grouped.putIfAbsent(entry.dayOfWeek, () => []).add(entry);
        }

        final records =
        await AttendanceService.getAttendanceBySubject(subject.id);

        for (final record in records) {
          final slotId = record.timetableEntryId;

          // Only slot-specific records can be matched accurately.
          if (slotId != null) {
            attendanceMap[_slotDateKey(slotId, record.classDate)] = record;
          }
        }
      }

      for (final entries in grouped.values) {
        entries.sort((a, b) => a.startTime.compareTo(b.startTime));
      }

      if (!mounted) return;

      setState(() {
        _entriesByDay
          ..clear()
          ..addAll(grouped);

        _subjectNames
          ..clear()
          ..addAll(names);

        _attendanceBySlotDate
          ..clear()
          ..addAll(attendanceMap);

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

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );

    if (picked == null || !mounted) return;

    setState(() {
      _selectedDate = DateTime(picked.year, picked.month, picked.day);
    });
  }

  void _changeDate(int days) {
    setState(() {
      _selectedDate = _selectedDate.add(Duration(days: days));
    });
  }

  void _selectWeekday(int weekday) {
    setState(() {
      // Keep the selected date in the same Monday-to-Sunday week.
      _selectedDate = _selectedDate.add(
        Duration(days: weekday - _selectedDate.weekday),
      );
    });
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];

    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _formatTime(String time) {
    final parts = time.split(':');

    if (parts.length < 2) return time;

    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);

    if (hour == null || minute == null) return time;

    final suffix = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour % 12 == 0 ? 12 : hour % 12;

    return '$displayHour:${minute.toString().padLeft(2, '0')} $suffix';
  }


  Future<void> _previewAndImportTimetable() async {
    try {
      final semesters = await SemesterService.getSemesters();

      if (!mounted) return;

      if (semesters.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Create a semester first.')),
        );
        return;
      }

      final activeSemesters =
      semesters.where((semester) => semester.active).toList();

      final semester =
      activeSemesters.isNotEmpty ? activeSemesters.first : semesters.first;

      final subjects = await SubjectService.getSubjects(semester.id);

      if (!mounted) return;

      if (subjects.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No subjects found. Add subjects before importing.'),
          ),
        );
        return;
      }

      final entries =
      await TimetableImportService.preview(semester.id);

      if (!mounted) return;

      if (entries.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No timetable classes were detected.')),
        );
        return;
      }

      final approvedEntries =
      await Navigator.of(context).push<List<Map<String, dynamic>>>(
        MaterialPageRoute(
          builder: (_) => TimetableReviewScreen(entries: entries),
        ),
      );

      if (!mounted || approvedEntries == null || approvedEntries.isEmpty) {
        return;
      }

      final saved = await TimetableImportService.importEntries(
        subjects.first.id,
        approvedEntries,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Successfully imported $saved classes.')),
      );

      await _loadTimetable();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Timetable import failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final dayEntries = _entriesByDay[_selectedDay] ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      appBar: AppBar(
        title: const Text('Manage Schedule'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF172554),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _loading ? null : _previewAndImportTimetable,
            icon: const Icon(Icons.document_scanner_outlined),
            tooltip: 'Import timetable from image',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                size: 44,
                color: Colors.redAccent,
              ),
              const SizedBox(height: 12),
              const Text(
                'Could not load timetable.',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                ),
              ),
              const SizedBox(height: 8),
              Text(_error!),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadTimetable,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      )
          : _entriesByDay.isEmpty
          ? const Center(
        child: Text(
          'No timetable entries found for this semester.',
        ),
      )
          : ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Your Weekly Schedule',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF172554),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Select a date to check your classes and cancellations.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 16),

          // Calendar date selector.
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: const Color(0xFFE5EAF2),
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => _changeDate(-1),
                  icon: const Icon(Icons.chevron_left),
                  tooltip: 'Previous day',
                ),
                Expanded(
                  child: InkWell(
                    onTap: _pickDate,
                    child: Column(
                      children: [
                        Text(
                          _days[_selectedDay - 1],
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatDate(_selectedDate),
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF172554),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => _changeDate(1),
                  icon: const Icon(Icons.chevron_right),
                  tooltip: 'Next day',
                ),
                IconButton(
                  onPressed: _pickDate,
                  icon: const Icon(Icons.calendar_month),
                  tooltip: 'Choose date',
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Weekday selector.
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(7, (index) {
                final dayNumber = index + 1;
                final isSelected = _selectedDay == dayNumber;

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(_days[index].substring(0, 3)),
                    selected: isSelected,
                    onSelected: (_) =>
                        _selectWeekday(dayNumber),
                    selectedColor: const Color(0xFF0891B2),
                    backgroundColor: Colors.white,
                    labelStyle: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : const Color(0xFF334155),
                      fontWeight: FontWeight.w600,
                    ),
                    side: BorderSide(
                      color: isSelected
                          ? const Color(0xFF0891B2)
                          : const Color(0xFFE5EAF2),
                    ),
                    showCheckmark: false,
                  ),
                );
              }),
            ),
          ),

          const SizedBox(height: 24),

          Text(
            '${_days[_selectedDay - 1]} • ${_formatDate(_selectedDate)}',
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w700,
              color: Color(0xFF172554),
            ),
          ),
          const SizedBox(height: 12),

          if (dayEntries.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 32,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFFE5EAF2),
                ),
              ),
              child: const Column(
                children: [
                  Icon(
                    Icons.event_available_outlined,
                    size: 42,
                    color: Color(0xFF0891B2),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'No classes scheduled',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Enjoy your free day!',
                    style: TextStyle(color: Colors.black54),
                  ),
                ],
              ),
            )
          else
            for (final entry in dayEntries)
              Builder(
                builder: (context) {
                  final record = _attendanceBySlotDate[
                  _slotDateKey(entry.id, _selectedDate)
                  ];

                  final cancelled = record != null &&
                      record.status.toUpperCase() == 'CANCELLED';

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 0,
                    color: cancelled
                        ? const Color(0xFFF1F5F9)
                        : Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(
                        color: cancelled
                            ? const Color(0xFFCBD5E1)
                            : const Color(0xFFE5EAF2),
                      ),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(14),
                      leading: CircleAvatar(
                        backgroundColor: cancelled
                            ? const Color(0xFFE2E8F0)
                            : const Color(0xFFE0F2FE),
                        child: Icon(
                          cancelled
                              ? Icons.event_busy
                              : Icons.menu_book_rounded,
                          color: cancelled
                              ? const Color(0xFF64748B)
                              : const Color(0xFF0891B2),
                        ),
                      ),
                      title: Text(
                        _subjectNames[entry.subjectId] ??
                            'Subject ${entry.subjectId}',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: cancelled
                              ? const Color(0xFF64748B)
                              : const Color(0xFF172554),
                        ),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          '${_formatTime(entry.startTime)} – '
                              '${_formatTime(entry.endTime)}\n'
                              '${entry.room ?? 'Room not assigned'}'
                              ' • ${entry.classType}'
                              '${cancelled ? '\n${record.notes?.isNotEmpty == true ? record.notes : 'Class did not happen'}' : ''}',
                          style: TextStyle(
                            color: cancelled
                                ? const Color(0xFF64748B)
                                : Colors.black54,
                          ),
                        ),
                      ),
                      isThreeLine: true,
                      trailing: cancelled
                          ? const Icon(
                        Icons.cancel_outlined,
                        color: Color(0xFF64748B),
                      )
                          : null,
                    ),
                  );
                },
              ),
        ],
      ),
    );
  }
}
