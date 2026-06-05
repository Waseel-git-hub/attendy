import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/DTO/draft.dart';

class OnboardingSemesterSetupScreen extends StatefulWidget {
  final SetupDraft setupDraft;
  final VoidCallback onComplete; // Callback to move to Step 2 (Subjects Setup)

  const OnboardingSemesterSetupScreen({
    Key? key,
    required this.setupDraft,
    required this.onComplete,
  }) : super(key: key);

  @override
  State<OnboardingSemesterSetupScreen> createState() =>
      _OnboardingSemesterSetupScreenState();
}

class _OnboardingSemesterSetupScreenState
    extends State<OnboardingSemesterSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: widget.setupDraft.semesterName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickDateRange() async {
    final DateTime initialNow = DateTime.now();
    final DateTime firstDate = initialNow.subtract(const Duration(days: 365));
    final DateTime lastDate = initialNow.add(const Duration(days: 365 * 2));

    DateTimeRange? pickedRange = await showDateRangePicker(
      context: context,
      firstDate: firstDate,
      lastDate: lastDate,
      initialDateRange: (widget.setupDraft.startDate != null &&
              widget.setupDraft.endDate != null)
          ? DateTimeRange(
              start: widget.setupDraft.startDate!,
              end: widget.setupDraft.endDate!)
          : DateTimeRange(
              start: initialNow,
              end: initialNow.add(const Duration(days: 120))),
    );

    if (pickedRange != null) {
      setState(() {
        widget.setupDraft.startDate = pickedRange.start;
        widget.setupDraft.endDate = pickedRange.end;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM, yyyy');
    final hasDates = widget.setupDraft.startDate != null &&
        widget.setupDraft.endDate != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('New Semester Setup'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome to Attendy',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Let\'s configure your current semester details to calibrate your auto-generated lecture history tracks.',
                style: TextStyle(color: Colors.grey, fontSize: 15),
              ),
              const SizedBox(height: 32),

              // Semester Name Field
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Semester Name',
                  hintText: 'e.g., Semester 1, Fall 2026',
                  prefixIcon: Icon(Icons.school_outlined),
                  border: OutlineInputBorder(),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter your semester title';
                  }
                  return null;
                },
                onChanged: (val) => widget.setupDraft.semesterName = val.trim(),
              ),
              const SizedBox(height: 24),

              // Date Range Selector Card
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  side: BorderSide(color: Theme.of(context).dividerColor),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.calendar_month_outlined,
                              color: Colors.grey),
                          const SizedBox(width: 8),
                          Text(
                            'Semester Duration',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (hasDates) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildDateColumn(
                                'START DATE',
                                dateFormat
                                    .format(widget.setupDraft.startDate!)),
                            const Icon(Icons.arrow_forward_rounded,
                                color: Colors.grey, size: 16),
                            _buildDateColumn('END DATE',
                                dateFormat.format(widget.setupDraft.endDate!)),
                          ],
                        ),
                      ] else ...[
                        const Text(
                          'No active date limits defined yet.',
                          style: TextStyle(
                              color: Colors.redAccent,
                              fontStyle: FontStyle.italic),
                        ),
                      ],
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: _pickDateRange,
                          child: Text(hasDates
                              ? 'Modify Date Limits'
                              : 'Select Academic Term Calendar'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),

              // Continue Navigation Control
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      if (!hasDates) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text(
                                  'Please select your semester term duration range.')),
                        );
                        return;
                      }
                      // Configuration passes verification checks -> Proceed to Subject Setup Screen
                      widget.onComplete();
                    }
                  },
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Complete Setup', style: TextStyle(fontSize: 16)),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward_rounded, size: 18),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateColumn(String label, String dateStr) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
              fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Text(
          dateStr,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

bool validateFinalSetupDraft(SetupDraft draft) {
  // 1. Double check Semester Data
  if (draft.semesterName.isEmpty ||
      draft.startDate == null ||
      draft.endDate == null) {
    return false;
  }

  // 2. Must contain at least one valid tracking entity subject
  if (draft.subjects.isEmpty) {
    return false;
  }

  // 3. Prevent empty schedules that break tracking dashboards
  if (draft.timetableSlots.isEmpty) {
    return false;
  }

  // 4. Verify all template blocks are assigned a subject draft target
  for (var entry in draft.timetableSlots) {
    if (entry.subjectTemporaryId == null) {
      return false;
    }
  }

  return true;
}
