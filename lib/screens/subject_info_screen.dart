import 'package:flutter/material.dart';
//  MODELS
import '../models/subject.dart';
//  SCREENS
import '../screens/add_subject_screen.dart';
//  SERVICES
//  WIDGETS
//------------------------------------------------------------

class SubjectInfoScreen extends StatelessWidget {
  final Subject subject;

  const SubjectInfoScreen({super.key, required this.subject});

  @override
  Widget build(BuildContext context) {
    final Color subjectColor = Color(subject.colorValue);
    return Scaffold(
      appBar: AppBar(
        title: Text(subject.name),
        backgroundColor: subjectColor.withOpacity(0.1),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddSubjectScreen(subject: subject),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 30),
            decoration: BoxDecoration(
              color: subjectColor.withOpacity(0.1),
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(32)),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: subjectColor,
                  child: Icon(
                    IconData(subject.iconCodePoint,
                        fontFamily: 'MaterialIcons'),
                    color: Colors.white,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  subject.name,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: subjectColor,
                      ),
                ),
              ],
            ),
          ),

          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Assignments",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),

          // List of Assignments for this subject
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Theme.of(context).colorScheme.primary,
        onPressed: () {},
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Assignment", style: TextStyle(color: Colors.white)),
      ),
    );
  }
}
