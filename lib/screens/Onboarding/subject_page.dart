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
  void _showAddSubjectDialog() {
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

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Select Subject'),
        contentPadding: const EdgeInsets.only(top: 12, bottom: 8),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // List of fast-add built-in templates
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: defaultSubjects.length,
                  itemBuilder: (context, index) {
                    final template = defaultSubjects[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor:
                            Color(template.colorValue).withOpacity(0.1),
                        child: Icon(
                          IconData(template.iconCodePoint,
                              fontFamily: 'MaterialIcons'),
                          color: Color(template.colorValue),
                        ),
                      ),
                      title: Text(template.name,
                          style: const TextStyle(fontWeight: FontWeight.w500)),
                      onTap: () {
                        setState(() {
                          // Safe copy with a unique dynamic id instance
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
              const Divider(),

              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                child: TextButton.icon(
                  style: TextButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                    alignment: Alignment.centerLeft,
                  ),
                  onPressed: () async {
                    Navigator.pop(ctx); // Dismiss picker modal safely

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
                  icon: const Icon(Icons.add_circle_outline_rounded),
                  label: const Text('Add Custom Subject...',
                      style: TextStyle(fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
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
                color: colorScheme.surfaceContainerHighest.withOpacity(0.25),
                borderRadius:
                    BorderRadius.circular(14), // Matches your input field radii
                border: Border.all(
                  color: colorScheme.onSurface
                      .withOpacity(0.08), // Soft, non-intrusive border
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 20,
                    color: colorScheme.onSurface.withOpacity(0.6),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "Subjects can be edited, added, or deleted later.",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: colorScheme.onSurface.withOpacity(0.7),
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
                              size: 64,
                              color: colorScheme.onSurface.withOpacity(0.7)),
                          const SizedBox(height: 12),
                          Text(
                            'No Subject Added yet\nTry Adding New Subjects',
                            style: TextStyle(
                                color: colorScheme.onSurface.withOpacity(0.5)),
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
                                  Color(subject.colorValue).withOpacity(0.1),
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
                                'Goal: ${subject.minAttend}% attendance requirement'),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_sweep_outlined,
                                  color: Colors.redAccent),
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
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: subjects.isEmpty
                      ? null
                      : widget
                          .onNext, // Disable unless a user configures a target item
                  child: const Text('Setup Timetable'),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        label: Row(
          children: [
            Icon(Icons.add),
            SizedBox(width: 06),
            Text('Add Subject'),
          ],
        ),
        onPressed: _showAddSubjectDialog,
      ),
    );
  }
}
