import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
//  WIDGET
import '../widgets/percent_indicator.dart';
//  MODELS
import '../models/lecture.dart';
import '../models/subject.dart';
import '../models/attendance.dart';
//  SERVICES
import '../services/database_service.dart';
//------------------------------------------------------------------------------

class LectureCard extends StatelessWidget {
  final Lecture lecture;
  final VoidCallback onTap;
  const LectureCard({super.key, required this.lecture, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final Subject? subject = DatabaseService.getSubjectById(lecture.subjectID);

    bool isRoomNo = lecture.roomNo != 'Not Specified';
    bool lectureMarked = lecture.status != "Not Marked";
    Color subjectColor = Color(subject!.colorValue);

    AttendanceCount monthCount = DatabaseService.getAttendance(
        lecture.subjectID, DateFormat('yyyy-MM').format(lecture.date));

    int skippable = DatabaseService.requiredLecture(
        subject.minAttend.toDouble(),
        monthCount.totalCount,
        monthCount.presentCount);

    String insightText = (skippable > 0)
        ? "Need to attend $skippable lecture"
        : (skippable < 0)
            ? "Can skip ${-skippable} lecture"
            : "Have to attend";
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: colorScheme.outlineVariant,
                width: 1.5,
              ),
            ),
            child: Column(
              children: [
                // Top Row: Icon, Subject Details, and Percentage
                Row(
                  children: [
                    // Subject Icon Container
                    Container(
                      height: 42,
                      width: 42,
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: colorScheme.outlineVariant,
                          width: 0.8,
                        ),
                      ),
                      child: Icon(
                          IconData(subject.iconCodePoint,
                              fontFamily: 'MaterialIcons'),
                          color: subjectColor.withOpacity(0.9),
                          size: 24),
                    ),
                    const SizedBox(width: 16),
                    // Subject Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            subject.name,
                            style: TextStyle(
                              color: colorScheme.onSurface,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                color: colorScheme.onSurfaceVariant,
                                size: 12,
                              ),
                              Text(
                                " ${(isRoomNo) ? lecture.roomNo : '---'}",
                                style: TextStyle(
                                  color: colorScheme.onSurfaceVariant,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Percentage Ring
                    circularPercent(lecture, subject, context),
                  ],
                ),
                if (!lectureMarked)
                  Text(
                    insightText,
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                // Action Buttons Row
                SizedBox(height: (lectureMarked) ? 10 : 5),
                Row(
                  children: [
                    _ActionButton(
                      label: "Cancel",
                      icon: Icons.block,
                      color: const Color(0xFFFBBF24),
                      isSelected: lecture.status == "Cancelled",
                      isActive: lectureMarked,
                      onTap: () {
                        if (lecture.status == "Cancelled") {
                          DatabaseService.clearAttendance(lecture);
                        } else {
                          DatabaseService.updateAttendance(
                              lecture: lecture, newStatus: 'Cancelled');
                        }
                      },
                    ),
                    const SizedBox(width: 8),
                    _ActionButton(
                      label: "Absent",
                      icon: Icons.cancel,
                      color: const Color(0xFFF87171),
                      isSelected: lecture.status == "Absent",
                      isActive: lectureMarked,
                      onTap: () {
                        if (lecture.status == "Absent") {
                          DatabaseService.clearAttendance(lecture);
                        } else {
                          DatabaseService.updateAttendance(
                              lecture: lecture, newStatus: 'Absent');
                        }
                      },
                    ),
                    const SizedBox(width: 8),
                    _ActionButton(
                      label: "Present",
                      icon: Icons.check_circle,
                      color: const Color(0xFF4ADE80),
                      isSelected: lecture.status == "Present",
                      isActive: lectureMarked,
                      onTap: () {
                        if (lecture.status == "Present") {
                          DatabaseService.clearAttendance(lecture);
                        } else {
                          DatabaseService.updateAttendance(
                              lecture: lecture, newStatus: 'Present');
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget circularPercent(
      Lecture lecture, Subject subject, BuildContext context) {
    // 1. Fixed: Added missing 'return' for the builder itself
    return ValueListenableBuilder(
      valueListenable: DatabaseService.attendanceBox.listenable(),
      builder: (context, Box box, _) {
        final overallStats =
            DatabaseService.getAttendance(lecture.subjectID, 'Overall');

        int total = overallStats.totalCount;
        int present = overallStats.presentCount;

        double livePercentage = total == 0 ? 0.0 : (present / total);
        double displayPercent = livePercentage * 100;
        double minTarget = subject.minAttend.toDouble();

        Color progressColor = displayPercent >= minTarget
            ? const Color(0xFF22C55E)
            : const Color(0xFFEF4444);

        return CustomCircleProgress(
          percentage: displayPercent,
          size: 50,
          fontSize: 10,
          strokeWidth: 3,
          progressColor: progressColor,
        );
      },
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final bool isActive;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 32,
          decoration: BoxDecoration(
            color: isSelected
                ? color.withValues(alpha: 0.15)
                : cs.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? color : cs.outlineVariant,
            ),
          ),
          child: Center(
            child: Icon(
              icon,
              size: 20,
              color: isSelected ? color : cs.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}
