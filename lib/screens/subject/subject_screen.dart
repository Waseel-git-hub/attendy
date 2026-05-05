import 'package:attendance_tracker/screens/subject/add_subject_screen.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
//  MODELS
import '../../models/subject.dart';
//  SCREENS
import 'subject_info_screen.dart';
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
    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedIds.isEmpty
            ? "Subjects"
            : "${_selectedIds.length} Selected"),
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
              },
            ),
          if (_selectedIds.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () {
                for (var key in _selectedIds) {
                  DatabaseService.deleteSubject(key);
                }
                setState(() => _selectedIds.clear());
              },
            ),
        ],
      ),
      body: ValueListenableBuilder(
        valueListenable: DatabaseService.subjectBox.listenable(),
        builder: (context, Box<Subject> box, _) {
          final subjects = box.values.toList();

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
                                SubjectInfoScreen(subject: subject)));
                  }
                  if (isSelected) {
                    _toggleSelection(subject.key);
                  }
                },
                onLongPress: () => _toggleSelection(subject.key),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        onPressed: () {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const AddSubjectScreen()));
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
