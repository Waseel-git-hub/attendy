import 'dart:io';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../services/database_service.dart';

class BugReportSheet extends StatefulWidget {
  const BugReportSheet({super.key});

  @override
  State<BugReportSheet> createState() => _BugReportSheetState();
}

class _BugReportSheetState extends State<BugReportSheet> {
  final TextEditingController _issueController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _includeAppStats = true;

  @override
  void dispose() {
    _issueController.dispose();
    super.dispose();
  }

  void _submitBugReport() async {
    if (!_formKey.currentState!.validate()) return;

    // 1. Capture the user's input text
    String userIssue = _issueController.text.trim();

    // 2. Automatically harvest light structural metadata to help you diagnose the crash
    StringBuffer reportBuffer = StringBuffer();
    reportBuffer.writeln("=== USER BUG REPORT ===");
    reportBuffer.writeln(userIssue);
    reportBuffer.writeln("\n=== DIAGNOSTIC LOGS ===");
    reportBuffer.writeln(
        "Device OS: ${Platform.operatingSystem} ${Platform.operatingSystemVersion}");
    reportBuffer.writeln("Report Date: ${DateTime.now()}");

    if (_includeAppStats) {
      int totalSubjects = DatabaseService.subjectBox.length;
      int totalLectures = DatabaseService.lectureBox.length;
      reportBuffer.writeln("Tracked Subjects Count: $totalSubjects");
      reportBuffer.writeln("Tracked Total Lectures History: $totalLectures");
    }

    reportBuffer.writeln("=======================");

    // 3. Hand off the compiled text directly to the native Share Sheet
    // The user can instantly forward this text block to your Email, Discord, or Clipboard!
    await Share.share(
      reportBuffer.toString(),
      subject: 'Attendance Tracker Bug Query',
    );

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        top: 24,
        left: 20,
        right: 20,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Report an Issue",
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Describe the bug or request a feature. Your text will be compiled into a message you can share directly with the developer.",
              style: TextStyle(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                  fontSize: 13),
            ),
            const SizedBox(height: 16),

            // Issue Input Field
            TextFormField(
              controller: _issueController,
              maxLines: 5,
              maxLength: 500,
              decoration: InputDecoration(
                hintText:
                    "What happened? (e.g., 'The trend line graph doesn't show up when I have only 1 lecture marked.')",
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return "Please enter a short description of the issue";
                }
                return null;
              },
            ),

            // Checkbox option to append diagnostics
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text("Include anonymous diagnostics",
                  style: TextStyle(fontSize: 14)),
              subtitle: const Text(
                  "Appends total database counts to help trace calculation loops",
                  style: TextStyle(fontSize: 11)),
              value: _includeAppStats,
              onChanged: (val) {
                setState(() => _includeAppStats = val ?? true);
              },
            ),
            const SizedBox(height: 12),

            // Action Row
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _submitBugReport,
                  icon: const Icon(Icons.send_rounded, size: 16),
                  label: const Text("Share Report"),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
