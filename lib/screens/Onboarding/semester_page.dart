import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/DTO/draft.dart';

class OnboardingSemesterSetupScreen extends StatefulWidget {
  final SetupDraft setupDraft;
  final VoidCallback onComplete;

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
              const SizedBox(height: 24),

              _buildSubjectSummarySection(),

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

                      // Extra guard checking the full draft rules before hitting onComplete
                      if (!validateFinalSetupDraft(widget.setupDraft)) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text(
                                  'Setup validation failed. Check your schedule slots.')),
                        );
                        return;
                      }

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

  // 💡 Subject Summary Helper Widget
  Widget _buildSubjectSummarySection() {
    final theme = Theme.of(context);
    final subjects = widget.setupDraft.subjects;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Subject Summary',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${subjects.length} Total',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (subjects.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.errorContainer.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
              border:
                  Border.all(color: theme.colorScheme.error.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber_rounded,
                    color: theme.colorScheme.error),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'No subjects added yet! Go back to add subjects.',
                    style: TextStyle(color: theme.colorScheme.onErrorContainer),
                  ),
                ),
              ],
            ),
          )
        else
          // Dynamic wrapping grid layout to fit subject rows cleanly
          Wrap(
            spacing: 8.0, // horizontal gap between chips
            runSpacing: 8.0, // vertical gap between rows
            children: subjects.map((subject) {
              // Deduce total lecture count for this specific subject draft
              final int slotCount = widget.setupDraft.timetableSlots
                  .where(
                      (slot) => slot.subjectTemporaryId == subject.temporaryId)
                  .length;

              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Color(subject.colorValue).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Color(subject.colorValue).withOpacity(0.4),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      IconData(subject.iconCodePoint,
                          fontFamily: 'MaterialIcons'),
                      size: 16,
                      color: Color(subject.colorValue),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      subject.name,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(width: 6),
                    // Small badge bubble highlighting the weekly lecture occurrences
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Color(subject.colorValue),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${slotCount}x',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
      ],
    );
  }
}

bool validateFinalSetupDraft(SetupDraft draft) {
  if (draft.semesterName.isEmpty ||
      draft.startDate == null ||
      draft.endDate == null) {
    return false;
  }
  if (draft.subjects.isEmpty) {
    return false;
  }
  if (draft.timetableSlots.isEmpty) {
    return false;
  }
  for (var entry in draft.timetableSlots) {
    if (entry.subjectTemporaryId == null) {
      return false;
    }
  }
  return true;
}
