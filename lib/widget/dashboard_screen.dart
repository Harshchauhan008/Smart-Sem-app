import 'package:flutter/material.dart';
import 'package:smartsem/widget/profile_screen.dart';
import 'package:smartsem/widget/subjects_screen.dart';
import 'package:smartsem/widget/timetable_screen.dart';
import '../helper/global.dart';
import '../model/semester.dart';
import '../model/subject.dart';
import '../service/attendance_service.dart';
import '../service/notification_service.dart';
import '../service/semester_service.dart';
import '../service/subject_service.dart';
import 'ai_chat_screen.dart';
import 'assignements_screen.dart';
import 'attendance_marking_screen.dart';
import 'notifications_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  static const Color navy = Color(0xFF102A56);
  static const Color blue = Color(0xFF2563EB);
  static const Color background = Color(0xFFF5F7FB);

  List<Semester> _semesters = [];
  bool _isLoadingSemesters = true;
  String? _semesterError;

  List<Subject> _subjects = [];
  final Map<int, double> _attendancePercentages = {};
  bool _isLoadingSubjects = false;
  String? _subjectError;

  // Bottom navigation state.
  int _selectedIndex = 0;

  // Tabs the user has opened at least once. Other tabs are built lazily.
  final Set<int> _visitedTabs = {0};

  @override
  void initState() {
    super.initState();
    _loadSemesters();
  }

  /// The active semester, or the first one if none is active.
  Semester? get _currentSemester {
    final active = _semesters.where((s) => s.active).toList();

    if (active.isNotEmpty) return active.first;
    return _semesters.isNotEmpty ? _semesters.first : null;
  }

  Future<void> _loadSemesters() async {
    try {
      final semesters = await SemesterService.getSemesters();

      if (!mounted) return;

      setState(() {
        _semesters = semesters;
        _semesterError = null;
        _isLoadingSemesters = false;
      });

      // Load subjects for the active semester, or the first semester.
      if (semesters.isNotEmpty) {
        final activeSemesters = semesters.where((s) => s.active).toList();

        final selectedSemester = activeSemesters.isNotEmpty
            ? activeSemesters.first
            : semesters.first;

        await _loadSubjects(selectedSemester.id);
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _semesterError = e.toString();
        _isLoadingSemesters = false;
      });
    }
  }

  Future<void> _loadSubjects(int semesterId) async {
    setState(() {
      _isLoadingSubjects = true;
      _subjectError = null;
    });

    try {
      final subjects = await SubjectService.getSubjects(semesterId);

      if (!mounted) return;

      setState(() {
        _subjects = subjects;
        _attendancePercentages.clear();
      });

      for (final subject in subjects) {
        try {
          final percentage =
          await AttendanceService.getAttendancePercentage(subject.id);

          if (!mounted) return;

          setState(() {
            _attendancePercentages[subject.id] = percentage;
          });
        } catch (e) {
          debugPrint(
            'Attendance fetch failed for ${subject.name}: $e',
          );
        }
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _subjectError = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingSubjects = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = screenSize(context);
    final wide = size.width >= 900;

    // The dashboard app bar belongs to the Home tab only. Other tabs
    // (timetable, chat, profile) bring their own app bars.
    final showHomeBar = wide || _selectedIndex == 0;

    return Scaffold(
      backgroundColor: background,
      appBar: showHomeBar
          ? AppBar(
        backgroundColor: background,
        title: const Text(
          'SmartSem',
          style: TextStyle(
            color: navy,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Notifications',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const NotificationsScreen(),
                ),
              );
            },
            icon: FutureBuilder<int>(
              future: NotificationService.getUnreadCount(),
              builder: (context, snapshot) {
                final count = snapshot.data ?? 0;

                return Badge(
                  isLabelVisible: count > 0,
                  label: Text(count > 99 ? '99+' : '$count'),
                  child: const Icon(Icons.notifications_none_rounded),
                );
              },
            ),
          ),
          const SizedBox(width: 8),
        ],
      )
          : null,
      body: wide ? _buildHome(size) : _buildTabs(size),
      bottomNavigationBar: wide
          ? null
          : NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          // Semester activation happens on the Profile tab, so
          // refresh the semester data when the student leaves it.
          final leavingProfile = _selectedIndex == 3 && index != 3;

          setState(() {
            _selectedIndex = index;
            _visitedTabs.add(index);
          });

          if (leavingProfile) {
            _loadSemesters();
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'Schedule',
          ),
          NavigationDestination(
            icon: Icon(Icons.auto_awesome_outlined),
            selectedIcon: Icon(Icons.auto_awesome),
            label: 'AI Buddy',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  /// Tab container. Keeps each tab's state (e.g. chat messages) alive,
  /// but only builds a tab after it has been opened once.
  Widget _buildTabs(Size size) {
    return IndexedStack(
      index: _selectedIndex,
      children: [
        _buildHome(size),
        _visitedTabs.contains(1)
            ? TimetableScreen(key: ValueKey(_currentSemester?.id))
            : const SizedBox.shrink(),
        _visitedTabs.contains(2) ? _buildAiTab() : const SizedBox.shrink(),
        _visitedTabs.contains(3)
            ? const ProfileScreen()
            : const SizedBox.shrink(),
      ],
    );
  }

  Widget _buildAiTab() {
    final semester = _currentSemester;

    if (semester == null) {
      return Center(
        child: Text(
          _isLoadingSemesters
              ? 'Loading semester...'
              : 'Please add a semester first.',
          style: const TextStyle(color: Colors.black54),
        ),
      );
    }

    // The key makes Flutter start a fresh chat when the active
    // semester changes.
    return AiChatScreen(
      key: ValueKey(semester.id),
      semesterId: semester.id,
    );
  }

  /// The original dashboard content.
  Widget _buildHome(Size size) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: SingleChildScrollView(
          padding: EdgeInsets.all(size.width < 600 ? 16 : 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Welcome back! 👋',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: navy,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Your academic journey, all in one place.',
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 24),

              // Semester overview
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [navy, blue],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Builder(
                  builder: (context) {
                    final semester = _currentSemester;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'CURRENT SEMESTER',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            letterSpacing: 1.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _isLoadingSemesters
                              ? 'Loading semester...'
                              : semester?.name ??
                              (_semesterError != null
                                  ? 'Unable to load semester'
                                  : 'No semester added'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _isLoadingSemesters
                              ? 'Please wait'
                              : semester?.academicYear ??
                              'Academic year not available',
                          style: const TextStyle(color: Colors.white70),
                        ),
                        if (_semesterError != null) ...[
                          const SizedBox(height: 8),
                          const Text(
                            'Check your connection and try again.',
                            style: TextStyle(color: Colors.white70),
                          ),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _isLoadingSemesters = true;
                                _semesterError = null;
                              });
                              _loadSemesters();
                            },
                            child: const Text(
                              'Retry',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 28),

              const Text(
                'Your Overview',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: navy,
                ),
              ),
              const SizedBox(height: 16),

              LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth >= 800
                      ? 4
                      : constraints.maxWidth >= 450
                      ? 2
                      : 1;

                  return GridView.count(
                    crossAxisCount: columns,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: columns == 1 ? 3.0 : 1.25,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _OverviewCard(
                        icon: Icons.fact_check_outlined,
                        title: 'Attendance',
                        value: 'Track classes',
                        color: const Color(0xFF2563EB),
                        onTap: () {
                          final semester = _currentSemester;

                          if (semester == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('No semester found.'),
                              ),
                            );
                            return;
                          }

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AttendanceMarkingScreen(
                                semesterId: semester.id,
                              ),
                            ),
                          );
                        },
                      ),
                      _OverviewCard(
                        icon: Icons.assignment_outlined,
                        title: 'Assignments',
                        value: 'View deadlines',
                        color: const Color(0xFF7C3AED),
                        onTap: () {
                          final semester = _currentSemester;

                          if (semester == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please add a semester first.'),
                              ),
                            );
                            return;
                          }

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AssignmentsScreen(
                                semesterId: semester.id,
                              ),
                            ),
                          );
                        },
                      ),
                      _OverviewCard(
                        icon: Icons.calendar_month_outlined,
                        title: 'Timetable',
                        value: 'Manage schedule',
                        color: const Color(0xFF0891B2),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const TimetableScreen(),
                            ),
                          );
                        },
                      ),
                      _OverviewCard(
                        icon: Icons.auto_awesome,
                        title: 'AI Study Buddy',
                        value: 'Ask your doubts',
                        color: const Color(0xFF059669),
                        onTap: () {
                          final semester = _currentSemester;

                          if (semester == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please add a semester first.'),
                              ),
                            );
                            return;
                          }

                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => AiChatScreen(
                                semesterId: semester.id,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 28),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.menu_book_rounded),
                  label: const Text('View All Subjects'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () {
                    final semester = _currentSemester;

                    if (semester == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('No semester available yet.'),
                        ),
                      );
                      return;
                    }

                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => SubjectsScreen(
                          semesterId: semester.id,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE6EAF0)),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Today's Schedule",
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                        color: navy,
                      ),
                    ),
                    SizedBox(height: 14),
                    Text(
                      'Your class schedule will appear here.',
                      style: TextStyle(color: Colors.black54),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OverviewCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;
  final VoidCallback? onTap;

  const _OverviewCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: const Color(0xFFE6EAF0),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 26),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}