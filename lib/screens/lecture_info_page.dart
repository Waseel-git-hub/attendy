import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/lecture.dart';
import '../../services/database_service.dart';
import '../../widgets/extra_lecture_sheet.dart';

class LectureInfoPage extends StatelessWidget {
  final Lecture lecture;

  const LectureInfoPage({super.key, required this.lecture});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final subject = DatabaseService.getSubjectById(lecture.subjectID);

    final String dateStr =
        DateFormat('EEEE, dd MMMM yyyy').format(lecture.date);
    final String timeStr =
        "${_formatTime(lecture.startHour, lecture.startMinute)} – ${_formatTime(lecture.endHour, lecture.endMinute)}";

    return Scaffold(
      appBar: AppBar(
        title: const Text("Lecture Details"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ================= LECTURE CARD HEADER =================
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: subject != null
                    ? Color(subject.colorValue).withOpacity(0.15)
                    : colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: subject != null
                      ? Color(subject.colorValue).withOpacity(0.5)
                      : colorScheme.outlineVariant,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    subject?.name ?? "Unknown Subject",
                    style: theme.textTheme.headlineMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Status: ${lecture.status}",
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: lecture.status == "Present"
                          ? Colors.green
                          : lecture.status == "Absent"
                              ? Colors.red
                              : colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ================= DETAILS METADATA LIST =================
            _buildInfoRow(
                context, Icons.calendar_today_rounded, "Date", dateStr),
            _buildInfoRow(context, Icons.access_time_rounded, "Time", timeStr),
            _buildInfoRow(context, Icons.meeting_room_rounded, "Room No",
                lecture.roomNo.isEmpty ? "Not Specified" : lecture.roomNo),
            _buildInfoRow(
                context,
                Icons.star_rounded,
                "Class Type",
                lecture.isExtraClass
                    ? "Extra Class"
                    : "Regular Timetable Class"),

            const Spacer(),

            // ================= ACTION BUTTONS ROW =================
            Row(
              children: [
                // DELETE BUTTON
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colorScheme.error,
                      side: BorderSide(color: colorScheme.error),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: () => _confirmDelete(context),
                    icon: const Icon(Icons.delete_outline_rounded),
                    label: const Text("Delete"),
                  ),
                ),
                const SizedBox(width: 16),

                // EDIT BUTTON
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: () async {
                      final bool? updated = await showModalBottomSheet<bool>(
                        context: context,
                        isScrollControlled: true,
                        builder: (context) =>
                            AddExtraLectureSheet(lectureToEdit: lecture),
                      );

                      if (updated == true && context.mounted) {
                        // This pops the info screen and alerts the calendar main view to refresh itself!
                        Navigator.pop(context, true);
                      }
                    },
                    icon: const Icon(Icons.edit_rounded),
                    label: const Text("Edit"),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
      BuildContext context, IconData icon, String title, String value) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          Icon(icon, color: theme.colorScheme.primary, size: 28),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              Text(value,
                  style: theme.textTheme.bodyLarge
                      ?.copyWith(fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }

  String _formatTime(int hour, int minute) {
    final time = TimeOfDay(hour: hour, minute: minute);
    return "${time.hourOfPeriod}:${time.minute.toString().padLeft(2, '0')} ${time.period == DayPeriod.am ? 'AM' : 'PM'}";
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Delete Lecture?"),
        content: const Text(
            "This will permanently remove this instance from your calendar and automatically reverse any attendance counts connected to it."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("Cancel"),
          ),
          TextButton(
            style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error),
            onPressed: () async {
              Navigator.pop(dialogContext);
              Navigator.pop(context);
              await DatabaseService.deleteLecture(lecture);
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }
}
