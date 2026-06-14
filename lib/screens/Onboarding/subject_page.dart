import 'package:flutter/material.dart';
import '../../models/DTO/draft.dart';
import '../../screens/subject/add_subject_screen.dart';

class OnboardingSubjectsSetupScreen extends StatefulWidget {
  final SetupDraft setupDraft;
  final VoidCallback onNext;

  const OnboardingSubjectsSetupScreen({
    Key? key,
    required this.setupDraft,
    required this.onNext,
  }) : super(key: key);

  @override
  State<OnboardingSubjectsSetupScreen> createState() =>
      _OnboardingSubjectsSetupScreenState();
}

class _OnboardingSubjectsSetupScreenState
    extends State<OnboardingSubjectsSetupScreen> {
  void _showAddSubjectDialog(ThemeData theme) {
    final List<SubjectDraft> defaultSubjects = [
      SubjectDraft(
        temporaryId: 'def_math',
        name: 'Mathematics',
        iconCodePoint: Icons.calculate.codePoint,
        colorValue: Colors.blue.value,
      ),
      SubjectDraft(
        temporaryId: 'def_phy',
        name: 'Engineering Physics',
        iconCodePoint: Icons.biotech.codePoint,
        colorValue: Colors.orange.value,
      ),
      SubjectDraft(
        temporaryId: 'def_ee',
        name: 'Electrical Engineering',
        iconCodePoint: Icons.bolt.codePoint,
        colorValue: Colors.amber.value,
      ),
      SubjectDraft(
        temporaryId: 'def_cs',
        name: 'Computer Programming',
        iconCodePoint: Icons.computer.codePoint,
        colorValue: Colors.purple.value,
      ),
      SubjectDraft(
        temporaryId: 'def_chem',
        name: 'Engineering Chemistry',
        iconCodePoint: Icons.science.codePoint,
        colorValue: Colors.teal.value,
      ),
    ];

    final colorScheme = theme.colorScheme;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        // Dialogs represent the highest layout layer
        backgroundColor: colorScheme.surfaceContainerHigh,
        title: Text(
          'Select Subject',
          style: TextStyle(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        contentPadding: const EdgeInsets.only(top: 12, bottom: 0),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: defaultSubjects.length,
                  itemBuilder: (context, index) {
                    final template = defaultSubjects[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor:
                            Color(template.colorValue).withOpacity(0.12),
                        child: Icon(
                          IconData(template.iconCodePoint,
                              fontFamily: 'MaterialIcons'),
                          color: Color(template.colorValue),
                          size: 20,
                        ),
                      ),
                      title: Text(
                        template.name,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface, // Strong Bold Ink
                          fontSize: 15,
                        ),
                      ),
                      onTap: () {
                        setState(() {
                          widget.setupDraft.subjects.add(SubjectDraft(
                            temporaryId: DateTime.now()
                                .millisecondsSinceEpoch
                                .toString(),
                            name: template.name,
                            iconCodePoint: template.iconCodePoint,
                            colorValue: template.colorValue,
                            minAttend: template.minAttend,
                          ));
                        });
                        Navigator.pop(ctx);
                      },
                    );
                  },
                ),
              ),

              // 💡 FIXED: Use the softer outline system line
              Divider(color: colorScheme.outlineVariant, height: 1),

              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                child: TextButton.icon(
                  style: TextButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                    alignment: Alignment.centerLeft,
                    // 💡 FIXED: Secondary actions use our crisp brand accent color for the text layer
                    foregroundColor: colorScheme.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () async {
                    Navigator.pop(ctx);

                    final SubjectDraft? customSubject = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            AddSubjectScreen(isOnboardingFlow: true),
                      ),
                    );

                    if (customSubject != null) {
                      setState(() {
                        widget.setupDraft.subjects.add(customSubject);
                      });
                    }
                  },
                  icon: const Icon(Icons.add_circle_outline_rounded, size: 20),
                  label: const Text(
                    'Add Custom Subject...',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: colorScheme
                  .onSurfaceVariant, // Muted Ink for dismiss/cancel paths
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final subjects = widget.setupDraft.subjects;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Your Subjects'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.only(bottom: 20, top: 4),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerLow,
                borderRadius:
                    BorderRadius.circular(14), // Matches your input field radii
                border: Border.all(
                  color:
                      colorScheme.outlineVariant, // Soft, non-intrusive border
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 20,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "Subjects can be edited, added, or deleted later.",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ), // 💡 Row, Container and decoration safely closed out here!

            // Dynamic display list area
            Expanded(
              child: subjects.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.auto_stories_outlined,
                              size: 64, color: colorScheme.onSurfaceVariant),
                          const SizedBox(height: 12),
                          Text(
                            'No Subject Added.',
                            style: TextStyle(
                                color: colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w500),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: subjects.length,
                      itemBuilder: (context, index) {
                        final subject = subjects[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor:
                                  Color(subject.colorValue).withOpacity(0.2),
                              child: Icon(
                                IconData(subject.iconCodePoint,
                                    fontFamily: 'MaterialIcons'),
                                color: Color(subject.colorValue),
                              ),
                            ),
                            title: Text(subject.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            subtitle: Text(
                              'Goal Attendance : ${subject.minAttend}%',
                              style: TextStyle(
                                  color: colorScheme.onSurfaceVariant),
                            ),
                            trailing: IconButton(
                              icon: Icon(Icons.delete_sweep_outlined,
                                  color: colorScheme.error),
                              onPressed: () {
                                setState(() {
                                  subjects.removeAt(index);
                                });
                              },
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical:
                  16.0), // 24px horizontal padding looks cleaner on wide displays
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: subjects.isEmpty ? null : widget.onNext,
                  style: ElevatedButton.styleFrom(
                    elevation:
                        0, // Keeps it flat to match the minimal productivity look
                    padding: const EdgeInsets.symmetric(
                        vertical: 16), // Thick, premium tap target

                    // 💡 THEME CODES:
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onSurface,
                    disabledForegroundColor:
                        Theme.of(context).colorScheme.onSurfaceVariant,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                          12), // Matching your card radius precisely
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Setup Timetable',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(
                        Icons.arrow_forward_rounded,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        elevation: 1,
        backgroundColor: colorScheme.primaryContainer,
        foregroundColor: colorScheme.onPrimaryContainer,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Add Subject',
          style: TextStyle(fontWeight: FontWeight.w600, letterSpacing: 0.2),
        ),
        onPressed: () {
          _showAddSubjectDialog(theme);
        },
      ),
    );
  }
}
