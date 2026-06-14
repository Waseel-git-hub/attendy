import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
//  MODELS
import '../../models/subject.dart';
//  SCREENS
import '../subject/add_subject_screen.dart';
import '../subject/subject_stats_page.dart';
//  WIDGETS
import '../../widgets/subject_card.dart';
//  SERVICES
import '../../services/database_service.dart';
//------------------------------------------------------------

class SubjectScreen extends StatefulWidget {
  const SubjectScreen({super.key});

  @override
  State<SubjectScreen> createState() => _SubjectScreenState();
}

class _SubjectScreenState extends State<SubjectScreen> {
  final Set<dynamic> _selectedIds = {};

  //TODO : Edit Confirmation

  Future<bool> deleteConfirmationDialog(
      BuildContext context, ThemeData theme) async {
    final colorScheme = theme.colorScheme;
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false, // User must tap a button to dismiss
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Delete Subject?'),
              content: Text(
                'This will delete all associated records and cannot be undone',
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 16,
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: Text('Cancel',
                      style: TextStyle(color: colorScheme.onSurfaceVariant)),
                  onPressed: () {
                    Navigator.of(context).pop(false); // Returns false
                  },
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Delete'),
                  onPressed: () {
                    for (var key in _selectedIds) {
                      DatabaseService.deleteSubject(key);
                    }
                    setState(() => _selectedIds.clear());
                    Navigator.of(context).pop(true);
                  },
                ),
              ],
            );
          },
        ) ??
        false; // Fallback to false if dismissed via Android back button
  }

  void _toggleSelection(dynamic key) {
    setState(() {
      if (_selectedIds.contains(key)) {
        _selectedIds.remove(key);
      } else {
        _selectedIds.add(key);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: (_selectedIds.isEmpty)
            ? null
            : IconButton(
                onPressed: () {
                  _selectedIds.clear();
                  setState(() {});
                },
                icon: Icon(Icons.arrow_back_ios)),
        elevation: _selectedIds.isEmpty ? 0 : 1,
        title: _selectedIds.isEmpty
            ? Text(
                "Subjects",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              )
            : Text("${_selectedIds.length} Selected"),
        actions: [
          if (_selectedIds.length == 1)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => AddSubjectScreen(
                            subject: DatabaseService.getSubjectById(
                                _selectedIds.first))));
                setState(() {
                  _selectedIds.clear();
                });
              },
            ),
          if (_selectedIds.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () async {
                if (await deleteConfirmationDialog(context, theme)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.white),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text('Subject Deleted Successfully'),
                          ),
                        ],
                      ),
                      backgroundColor: Colors.green[700],
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 3),
                    ),
                  );
                }
              },
            ),
        ],
      ),
      body: ValueListenableBuilder(
        valueListenable: DatabaseService.subjectBox.listenable(),
        builder: (context, Box<Subject> box, _) {
          final subjects = box.values.toList();

          if (subjects.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.menu_book_rounded,
                    size: 72,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "No Subjects Added",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Add your first subject to continue",
                    style: TextStyle(
                      fontSize: 14,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AddSubjectScreen(),
                        ),
                      );
                    },
                    icon: const Icon(
                      Icons.add,
                      color: Colors.white,
                    ),
                    label: const Text(
                      "Add Subject",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: subjects.length,
            itemBuilder: (context, index) {
              final subject = subjects[index];
              final isSelected = _selectedIds.contains(subject.key);

              return SubjectCard(
                subject: subject,
                isSelected: isSelected,
                onTap: () {
                  if (_selectedIds.isEmpty) {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                SubjectStatsPage(subjectKey: subject.key)));
                  } else {
                    _toggleSelection(subject.key);
                  }
                },
                onLongPress: () => _toggleSelection(subject.key),
              );
            },
          );
        },
      ),
      floatingActionButton:
          DatabaseService.subjectBox.isEmpty // TODO: Need work semester bug
              ? null
              : FloatingActionButton.extended(
                  label: Text('Add Subject'),
                  icon: const Icon(Icons.add),
                  backgroundColor: colorScheme.primary,
                  foregroundColor: Colors.white,
                  onPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const AddSubjectScreen()));
                  },
                ),
    );
  }
}
