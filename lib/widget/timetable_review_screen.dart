import 'package:flutter/material.dart';

/// Shows the classes Gemini read from the timetable image.
/// The student can remove wrong ones, then approve.
/// Pops with the approved list, or null if cancelled.
class TimetableReviewScreen extends StatefulWidget {
  final List<Map<String, dynamic>> entries;

  const TimetableReviewScreen({
    super.key,
    required this.entries,
  });

  @override
  State<TimetableReviewScreen> createState() => _TimetableReviewScreenState();
}

class _TimetableReviewScreenState extends State<TimetableReviewScreen> {
  static const List<String> _days = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  late List<Map<String, dynamic>> _entries;

  @override
  void initState() {
    super.initState();

    _entries = widget.entries
        .map((e) => Map<String, dynamic>.from(e))
        .toList()
      ..sort((a, b) {
        final dayCompare = _day(a).compareTo(_day(b));
        if (dayCompare != 0) return dayCompare;
        return _text(a['startTime']).compareTo(_text(b['startTime']));
      });
  }

  int _day(Map<String, dynamic> e) =>
      (e['dayOfWeek'] as num?)?.toInt() ?? 0;

  String _text(dynamic value) => value?.toString() ?? '';

  /// Indexes of classes that overlap another class on the same day.
  /// Different lab groups (Grp-A / Grp-B) may run at the same time.
  Set<int> _conflicts() {
    final result = <int>{};

    for (var i = 0; i < _entries.length; i++) {
      for (var j = i + 1; j < _entries.length; j++) {
        final a = _entries[i];
        final b = _entries[j];

        if (_day(a) != _day(b)) continue;

        final ga = a['group'];
        final gb = b['group'];

        if (ga != null && gb != null && ga != gb) continue;

        final overlaps =
            _text(a['startTime']).compareTo(_text(b['endTime'])) < 0 &&
                _text(b['startTime']).compareTo(_text(a['endTime'])) < 0;

        if (overlaps) {
          result
            ..add(i)
            ..add(j);
        }
      }
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    final conflicts = _conflicts();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Review timetable'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFE0F2FE),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_entries.length} classes found. The AI can misread an '
                    'image, so check each one against your timetable and remove '
                    'any that are wrong.'
                    '${conflicts.isNotEmpty ? '\n\nOrange cards overlap another class at the same time.' : ''}',
                style: const TextStyle(fontSize: 13),
              ),
            ),
          ),
          Expanded(
            child: _entries.isEmpty
                ? const Center(child: Text('No classes left to import.'))
                : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _entries.length,
              itemBuilder: (context, index) {
                final e = _entries[index];
                final hasConflict = conflicts.contains(index);
                final day = _day(e);
                final dayName =
                day >= 1 && day <= 7 ? _days[day - 1] : 'Unknown day';

                final details = [
                  '$dayName  ${_text(e['startTime'])} – ${_text(e['endTime'])}',
                  if (e['room'] != null) 'Room ${e['room']}',
                  _text(e['classType']),
                  if (e['group'] != null) _text(e['group']),
                ].join(' • ');

                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: hasConflict
                          ? Colors.orange
                          : const Color(0xFFE5EAF2),
                      width: hasConflict ? 1.5 : 1,
                    ),
                  ),
                  child: ListTile(
                    title: Text(
                      _text(e['subjectName']),
                      style:
                      const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      hasConflict
                          ? '$details\nOverlaps another class. Check this one.'
                          : details,
                    ),
                    isThreeLine: hasConflict,
                    trailing: IconButton(
                      tooltip: 'Remove this class',
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () {
                        setState(() => _entries.removeAt(index));
                      },
                    ),
                  ),
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      onPressed: _entries.isEmpty
                          ? null
                          : () => Navigator.of(context).pop(_entries),
                      child: Text('Import ${_entries.length} classes'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}