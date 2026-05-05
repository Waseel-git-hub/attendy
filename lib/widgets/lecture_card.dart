import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';
//  WIDGET
import '../models/lecture.dart';
import '../models/subject.dart';
//  SERVICES
import '../services/database_service.dart';
//------------------------------------------------------------------------------

class LectureCard extends StatelessWidget {
  final Lecture lecture;
  final VoidCallback onTap;
  const LectureCard({super.key, required this.lecture, required this.onTap});

  void _updateStatus(String newStatus) async {
    lecture.status = newStatus;
    await DatabaseService.lectureBox.put(lecture.lectureUID, lecture);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final Subject? subject = DatabaseService.getSubjectById(lecture.subjectID);

    bool lectureMarked = lecture.status != "NONE";
    Color subjectColor = Color(subject!.colorValue);

    String insightText = " itna attend krna hoga abhi";
    double attendancePercentage = 0.74;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: lectureMarked
                  ? theme.cardColor
                  : theme.cardColor.withOpacity(0.7),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withOpacity(0.25),
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
                      height: 52,
                      width: 52,
                      decoration: BoxDecoration(
                        color: subjectColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
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
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Text(
                                  lecture.isExtraClass
                                      ? "Extra Lecture"
                                      : "Normal Lecture",
                                  style: const TextStyle(
                                      color: Colors.white38, fontSize: 13))
                            ],
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(Icons.location_on,
                                  color: Colors.white38, size: 14),
                              Text(" ${lecture.roomNo}",
                                  style: const TextStyle(
                                      color: Colors.white38, fontSize: 13)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Percentage Ring
                    circularPercent(attendancePercentage, subject),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  insightText,
                  style: TextStyle(
                      color: colorScheme.onSurface.withOpacity(0.8),
                      fontSize: 13,
                      fontWeight: FontWeight.w500),
                ),
                // Action Buttons Row
                const SizedBox(height: 10),
                Row(
                  children: [
                    _ActionButton(
                      label: "Cancel",
                      icon: Icons.block,
                      color: const Color(0xFFFBBF24),
                      isSelected: lecture.status == "CANCELLED",
                      isActive: lectureMarked,
                      onTap: () {
                        if (lecture.status == "CANCELLED")
                          _updateStatus("NONE");
                        else
                          _updateStatus("CANCELLED");
                      },
                    ),
                    const SizedBox(width: 8),
                    _ActionButton(
                      label: "Absent",
                      icon: Icons.cancel,
                      color: const Color(0xFFF87171),
                      isSelected: lecture.status == "ABSENT",
                      isActive: lectureMarked,
                      onTap: () {
                        if (lecture.status == "ABSENT")
                          _updateStatus("NONE");
                        else
                          _updateStatus("ABSENT");
                      },
                    ),
                    const SizedBox(width: 8),
                    _ActionButton(
                      label: "Present",
                      icon: Icons.check_circle,
                      color: const Color(0xFF4ADE80),
                      isSelected: lecture.status == "PRESENT",
                      isActive: lectureMarked,
                      onTap: () {
                        if (lecture.status == "PRESENT")
                          _updateStatus("NONE");
                        else
                          _updateStatus("PRESENT");
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

  Widget circularPercent(double attendancePercentage, Subject subject) {
    return CircularPercentIndicator(
      radius: 28.0,
      lineWidth: 4.0,
      percent: attendancePercentage,
      center: Text(
        "${(attendancePercentage * 100).toInt()}%",
        style: const TextStyle(
            color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
      ),
      progressColor: attendancePercentage < subject.minAttend.toDouble()
          ? Colors.blueAccent
          : Colors.red,
      backgroundColor: Colors.white10,
      circularStrokeCap: CircularStrokeCap.round,
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
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 170),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withOpacity(0.27)
                : (isActive ? color.withOpacity(0.15) : color.withOpacity(0.2)),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? color
                  : (isActive
                      ? color.withOpacity(0.1)
                      : color.withOpacity(0.5)),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon,
                  color: isSelected
                      ? color
                      : (isActive
                          ? color.withOpacity(0.2)
                          : color.withOpacity(0.7)),
                  size: 18),
              const SizedBox(height: 4),
            ],
          ),
        ),
      ),
    );
  }
}
