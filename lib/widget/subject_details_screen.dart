
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../model/subject.dart';

class SubjectDetailsScreen extends StatelessWidget {
  final Subject subject;
  final double? attendancePercentage;

  const SubjectDetailsScreen({
    super.key,
    required this.subject,
    this.attendancePercentage,
  });

  @override
  Widget build(BuildContext context) {
    final requiredAttendance =
        subject.attendanceRequired ?? 75.0;

    final percentage = attendancePercentage;
    final meetsRequirement =
        percentage != null &&
            percentage >= requiredAttendance;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      appBar: AppBar(
        title: const Text('Subject Details'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF172554),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            elevation: 0,
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: const BorderSide(
                color: Color(0xFFE5EAF2),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.menu_book_rounded,
                    size: 36,
                    color: Color(0xFF4F46E5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    subject.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Subject Code: ${subject.subjectCode ?? "N/A"}',
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Faculty: ${subject.facultyName ?? "Not assigned"}',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 0,
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: const BorderSide(
                color: Color(0xFFE5EAF2),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Attendance Overview',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    percentage == null
                        ? 'Attendance data unavailable'
                        : '${percentage.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: percentage == null
                          ? Colors.blueGrey
                          : meetsRequirement
                          ? Colors.green
                          : Colors.red,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Required attendance: '
                        '${requiredAttendance.toStringAsFixed(0)}%',
                  ),
                  if (percentage != null) ...[
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: (percentage / 100)
                            .clamp(0.0, 1.0),
                        minHeight: 8,
                        backgroundColor:
                        const Color(0xFFE9EDF3),
                        valueColor:
                        AlwaysStoppedAnimation<Color>(
                          meetsRequirement
                              ? Colors.green
                              : Colors.red,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          Card(
            elevation: 0,
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: const BorderSide(
                color: Color(0xFFE5EAF2),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Attendance Analytics',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (attendancePercentage != null)
                    AttendanceBarChart(
                      attendancePercentage: attendancePercentage!,
                      requiredPercentage: requiredAttendance,
                    )
                  else
                    const Text('Attendance data is unavailable.'),
                ],
              ),
            ),
          ),


          if (attendancePercentage != null) ...[
            const SizedBox(height: 16),
            Builder(
              builder: (context) {
                final current = attendancePercentage!;
                final required = requiredAttendance;

                final message = current >= required
                    ? 'You are meeting the attendance requirement.'
                    : 'Your attendance is below the required threshold.';

                final color = current >= required
                    ? Colors.green
                    : Colors.red;

                return Card(
                  elevation: 0,
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                    side: const BorderSide(
                      color: Color(0xFFE5EAF2),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          current >= required
                              ? Icons.check_circle_rounded
                              : Icons.warning_rounded,
                          color: color,
                          size: 30,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Attendance Insight',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                message,
                                style: TextStyle(
                                  color: color,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Current: ${current.toStringAsFixed(1)}% '
                                    '• Required: ${required.toStringAsFixed(0)}%',
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],

        ],
      ),
    );
  }
}


class AttendanceBarChart extends StatelessWidget {
  final double attendancePercentage;
  final double requiredPercentage;

  const AttendanceBarChart({
    super.key,
    required this.attendancePercentage,
    this.requiredPercentage = 75,
  });

  @override
  Widget build(BuildContext context) {
    final attended =
    attendancePercentage.clamp(0.0, 100.0).toDouble();
    final missed = 100.0 - attended;
    final required = requiredPercentage.clamp(0.0, 100.0).toDouble();

    return SizedBox(
      height: 250,
      child: BarChart(
        BarChartData(
          maxY: 100,
          minY: 0,
          gridData: const FlGridData(show: true),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 38,
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 48,
                getTitlesWidget: (value, meta) {
                  const labels = [
                    'Attended',
                    'Missed',
                    'Required',
                  ];

                  final index = value.toInt();

                  if (index < 0 || index >= labels.length) {
                    return const SizedBox.shrink();
                  }

                  return SideTitleWidget(
                    meta: meta,
                    space: 8,
                    child: Text(
                      labels[index],
                      style: const TextStyle(fontSize: 11),
                    ),
                  );
                },
              ),
            ),
          ),
          barGroups: [
            _bar(0, attended, Colors.green),
            _bar(1, missed, Colors.red),
            _bar(2, required, Colors.blue),
          ],
        ),
      ),
    );
  }

  BarChartGroupData _bar(
      int x,
      double value,
      Color color,
      ) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: value,
          color: color,
          width: 28,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(6),
          ),
        ),
      ],
    );
  }
}
