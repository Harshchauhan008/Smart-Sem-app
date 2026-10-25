
import 'package:flutter/material.dart';
import 'package:smartsem/widget/subject_details_screen.dart';

import '../model/subject.dart';
import '../service/attendance_service.dart';
import '../service/subject_service.dart';

class SubjectsScreen extends StatefulWidget {
  final int semesterId;

  const SubjectsScreen({
    super.key,
    required this.semesterId,
  });

  @override
  State<SubjectsScreen> createState() => _SubjectsScreenState();
}

class _SubjectsScreenState extends State<SubjectsScreen> {
  List<Subject> _subjects = [];
  final Map<int, double> _attendance = {};
  bool _loading = true;
  String? _error;

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
      final subjects =
      await SubjectService.getSubjects(widget.semesterId);

      if (!mounted) return;
      setState(() => _subjects = subjects);

      for (final subject in subjects) {
        try {
          final percentage =
          await AttendanceService.getAttendancePercentage(
            subject.id,
          );

          if (!mounted) return;
          setState(() => _attendance[subject.id] = percentage);
        } catch (e) {
          debugPrint('Attendance error for ${subject.name}: $e');
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      appBar: AppBar(
        title: const Text('My Subjects'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF172554),
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Could not load subjects.\n$_error'),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _loadSubjects,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      )
          : _subjects.isEmpty
          ? const Center(child: Text('No subjects found.'))
          : LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final columns = width < 600
              ? 2
              : width < 1000
              ? 3
              : 4;

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _subjects.length,
            gridDelegate:
            SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              mainAxisExtent: width < 600 ? 190 : 210,
            ),
            itemBuilder: (context, index) {
              final subject = _subjects[index];
              final percentage =
              _attendance[subject.id];
              final required =
                  subject.attendanceRequired ?? 75.0;

              final color = percentage == null
                  ? Colors.blueGrey
                  : percentage >= required
                  ? const Color(0xFF16834A)
                  : const Color(0xFFDC2626);


              return InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => SubjectDetailsScreen(
                          subject: subject,
                          attendancePercentage: _attendance[subject.id],
                        ),
                      ),
                    );
                  },
                  child: Card(
                elevation: 0,
                color: Colors.white,
                margin: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(
                    color: Color(0xFFE5EAF2),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.menu_book_rounded,
                        color: color,
                        size: 24,
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: Text(
                          subject.name,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      Text(
                        percentage == null
                            ? '--'
                            : '${percentage.toStringAsFixed(1)}%',
                        style: TextStyle(
                          color: color,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius:
                        BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: percentage == null
                              ? 0
                              : (percentage / 100)
                              .clamp(0.0, 1.0),
                          minHeight: 5,
                          backgroundColor:
                          const Color(0xFFE9EDF3),
                          valueColor:
                          AlwaysStoppedAnimation(color),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Required ${required.toStringAsFixed(0)}%',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
                  );
            },
          );
        },
      ),
    );
  }
}
