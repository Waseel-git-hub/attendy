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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final dateFormat = DateFormat('dd MMM, yyyy');
    final hasDates = widget.setupDraft.startDate != null &&
        widget.setupDraft.endDate != null;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              Text(
                'Welcome to Attendy',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),

              const SizedBox(height: 32),

              // Semester Name Field
              TextFormField(
                controller: _nameController,
                style: TextStyle(color: colorScheme.onSurface),
                decoration: InputDecoration(
                  labelText: 'Semester Name',
                  labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
                  hintText: 'e.g., Semester 1, Fall 2026',
                  hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
                  prefixIcon: Icon(Icons.school_outlined,
                      color: colorScheme.onSurfaceVariant),
                  filled: true,
                  fillColor: colorScheme.surfaceContainerLowest,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: colorScheme.outlineVariant),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        BorderSide(color: colorScheme.primary, width: 1),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: colorScheme.error),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: colorScheme.error, width: 2),
                  ),
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
                color: colorScheme.surfaceContainerLow,
                shape: RoundedRectangleBorder(
                  side: BorderSide(color: colorScheme.outlineVariant),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.calendar_month_outlined,
                              color: colorScheme.onSurfaceVariant),
                          const SizedBox(width: 8),
                          Text(
                            'Semester Duration',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      if (hasDates) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildDateColumn(
                                colorScheme,
                                'START DATE',
                                dateFormat
                                    .format(widget.setupDraft.startDate!)),
                            Icon(Icons.arrow_forward_rounded,
                                color: colorScheme.onSurfaceVariant, size: 16),
                            _buildDateColumn(colorScheme, 'END DATE',
                                dateFormat.format(widget.setupDraft.endDate!)),
                          ],
                        ),
                      ] else ...[
                        Text(
                          'No active date limits defined yet.',
                          style: TextStyle(
                              color: colorScheme.error,
                              fontSize: 13,
                              fontStyle: FontStyle.italic,
                              fontWeight: FontWeight.w500),
                        ),
                      ],
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: _pickDateRange,
                          style: OutlinedButton.styleFrom(
                            backgroundColor: colorScheme.primaryContainer,
                            side: BorderSide(color: colorScheme.outlineVariant),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: Text(
                            hasDates
                                ? 'Modify Date Limits'
                                : 'Select Academic Term Calendar',
                            style: TextStyle(
                                color: colorScheme.onPrimaryContainer,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              _buildSubjectSummarySection(theme, colorScheme),

              const SizedBox(height: 40),

              // Continue Navigation Control
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      if (!hasDates) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text(
                                'Please select your semester term duration range.'),
                            backgroundColor: colorScheme.error,
                          ),
                        );
                        return;
                      }

                      if (!validateFinalSetupDraft(widget.setupDraft)) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text(
                                'Setup validation failed. Check your schedule slots.'),
                            backgroundColor: colorScheme.error,
                          ),
                        );
                        return;
                      }

                      widget.onComplete();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onSurface,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Complete Setup',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
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

  Widget _buildDateColumn(
      ColorScheme colorScheme, String label, String dateStr) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
              fontSize: 11,
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Text(
          dateStr,
          style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface),
        ),
      ],
    );
  }

  Widget _buildSubjectSummarySection(ThemeData theme, ColorScheme colorScheme) {
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
                  color: colorScheme.onSurface,
                ),
              ),
              Text(
                '${subjects.length} Total',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.primary,
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
              color: colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colorScheme.error.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber_rounded,
                    color: colorScheme.onErrorContainer),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'No subjects added yet! Go back to add subjects.',
                    style: TextStyle(
                        color: colorScheme.onErrorContainer,
                        fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          )
        else
          Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children: subjects.map((subject) {
              final int slotCount = widget.setupDraft.timetableSlots
                  .where(
                      (slot) => slot.subjectTemporaryId == subject.temporaryId)
                  .length;

              final Color baseColor = Color(subject.colorValue);

              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: baseColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: baseColor.withOpacity(0.4),
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
                      color: baseColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      subject.name,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: baseColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${slotCount}x',
                        style: TextStyle(
                          fontSize: 10,
                          // Uses ThemeData's logic to figure out if white or black text sits best on this specific subject label color tint
                          color:
                              ThemeData.estimateBrightnessForColor(baseColor) ==
                                      Brightness.dark
                                  ? Colors.white
                                  : Colors.black,
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
