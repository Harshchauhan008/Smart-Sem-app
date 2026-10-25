
import 'package:flutter/material.dart';
import '../model/semester.dart';
import '../service/semester_service.dart';

class SemesterManagementScreen extends StatefulWidget {
  const SemesterManagementScreen({super.key});

  @override
  State<SemesterManagementScreen> createState() =>
      _SemesterManagementScreenState();
}

class _SemesterManagementScreenState
    extends State<SemesterManagementScreen> {
  List<Semester> _semesters = [];
  bool _loading = true;
  bool _creating = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSemesters();
  }

  Future<void> _loadSemesters() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final semesters = await SemesterService.getSemesters();
      if (!mounted) return;
      setState(() => _semesters = semesters);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _showCreateDialog() async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final yearController = TextEditingController(text: '2026-2027');
    final numberController = TextEditingController();

    DateTime? startDate;
    DateTime? endDate;

    String dateText(DateTime? date) {
      if (date == null) return 'Choose date';
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-'
          '${date.day.toString().padLeft(2, '0')}';
    }

    Future<DateTime?> pickDate(DateTime? initial) async {
      return showDatePicker(
        context: context,
        initialDate: initial ?? DateTime.now(),
        firstDate: DateTime(2020),
        lastDate: DateTime(2040),
      );
    }

    final created = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Create semester'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Semester name',
                      hintText: 'Semester 8',
                    ),
                    validator: (value) =>
                    value == null || value.trim().isEmpty
                        ? 'Enter a semester name'
                        : null,
                  ),
                  TextFormField(
                    controller: yearController,
                    decoration: const InputDecoration(
                      labelText: 'Academic year',
                      hintText: '2026-2027',
                    ),
                    validator: (value) =>
                    value == null || value.trim().isEmpty
                        ? 'Enter the academic year'
                        : null,
                  ),
                  TextFormField(
                    controller: numberController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Semester number',
                    ),
                    validator: (value) {
                      final number = int.tryParse(value ?? '');
                      if (number == null || number < 1 || number > 12) {
                        return 'Enter a number from 1 to 12';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final picked = await pickDate(startDate);
                      if (picked != null) {
                        setDialogState(() => startDate = picked);
                      }
                    },
                    icon: const Icon(Icons.calendar_today),
                    label: Text('Start: ${dateText(startDate)}'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final picked = await pickDate(
                        endDate ?? startDate,
                      );
                      if (picked != null) {
                        setDialogState(() => endDate = picked);
                      }
                    },
                    icon: const Icon(Icons.event),
                    label: Text('End: ${dateText(endDate)}'),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: _creating
                  ? null
                  : () async {
                if (!formKey.currentState!.validate()) return;

                if (startDate == null || endDate == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Choose both semester dates.'),
                    ),
                  );
                  return;
                }

                if (endDate!.isBefore(startDate!)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'End date must be after start date.',
                      ),
                    ),
                  );
                  return;
                }

                setState(() => _creating = true);
                try {
                  await SemesterService.createSemester(
                    name: nameController.text.trim(),
                    academicYear: yearController.text.trim(),
                    semesterNumber:
                    int.parse(numberController.text),
                    startDate: dateText(startDate),
                    endDate: dateText(endDate),
                  );

                  if (!mounted) return;
                  Navigator.pop(dialogContext, true);
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Could not create semester: $e'),
                    ),
                  );
                } finally {
                  if (mounted) setState(() => _creating = false);
                }
              },
              child: _creating
                  ? const SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
                  : const Text('Create'),
            ),
          ],
        ),
      ),
    );

    nameController.dispose();
    yearController.dispose();
    numberController.dispose();

    if (created == true && mounted) {
      await _loadSemesters();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Semester created successfully')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Semester Management')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _creating ? null : _showCreateDialog,
        icon: const Icon(Icons.add),
        label: const Text('New Semester'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Could not load semesters:\n$_error'),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _loadSemesters,
              child: const Text('Retry'),
            ),
          ],
        ),
      )
          : _semesters.isEmpty
          ? const Center(child: Text('No semesters yet. Create one.'))
          : RefreshIndicator(
        onRefresh: _loadSemesters,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _semesters.length,
          itemBuilder: (context, index) {
            final semester = _semesters[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: const CircleAvatar(
                  child: Icon(Icons.school_outlined),
                ),
                title: Text(semester.name),
                subtitle: Text(
                  '${semester.academicYear} · '
                      'Semester ${semester.semesterNumber}\n'
                      '${semester.startDate} – ${semester.endDate}',
                ),
                isThreeLine: true,
                trailing: semester.active
                    ? const Chip(label: Text('Active'))
                    : OutlinedButton(
                  onPressed: () async {
                    try {
                      await SemesterService.activateSemester(semester.id);
                      await _loadSemesters();

                      if (!mounted) return;

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${semester.name} activated successfully'),
                        ),
                      );
                    } catch (e) {
                      if (!mounted) return;

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Could not activate semester: $e')),
                      );
                    }
                  },
                  child: const Text('Activate'),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
