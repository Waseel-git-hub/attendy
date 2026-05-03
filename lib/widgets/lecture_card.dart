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
  const LectureCard({super.key, required this.lecture});

  @override
  Widget build(BuildContext context) {
    final Subject? subject = DatabaseService.getSubjectById(lecture.subjectID);

    // 1. DYNAMIC THEME LOGIC
    Color themeColor = Color(subject!.colorValue);
    String statusLabel;
    String insightText = "Mat Jaa College";

    switch (lecture.status) {
      case "PRESENT":
        statusLabel = "PRESENT MARKED";
        break;
      case "ABSENT":
        statusLabel = "ABSENT MARKED";
        break;
      case "CANCELLED":
        statusLabel = "CANCELLED / NOT CONDUCTED";
        break;
      default:
        statusLabel = "NOT MARKED";
    }

    // Placeholder percentage - link this to your DatabaseService.getAttendanceStats
    double attendancePercentage = 0.80;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Status Label above the card
        Padding(
          padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
          child: Text(
            statusLabel,
            style: TextStyle(
              color: themeColor,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF0D0D0F), // Deep black background
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: lecture.status == "NONE"
                  ? Colors.white.withOpacity(0.05)
                  : themeColor.withOpacity(0.3),
              width: 1.5,
            ),
            boxShadow: [
              if (lecture.status != "NONE")
                BoxShadow(
                  color: themeColor.withOpacity(0.05),
                  blurRadius: 15,
                  spreadRadius: 2,
                )
            ],
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
                      color: themeColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                        IconData(subject.iconCodePoint,
                            fontFamily: 'MaterialIcons'),
                        color: themeColor.withOpacity(0.9),
                        size: 24),
                  ),
                  const SizedBox(width: 16),
                  // Subject Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "${subject.name} - ${lecture.lectureUID.split('_').last.characters.first}",
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.location_on,
                                color: Colors.white38, size: 14),
                            Text(" ${lecture.roomNo}",
                                style: const TextStyle(
                                    color: Colors.white38, fontSize: 13)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          insightText,
                          style: TextStyle(
                              color: themeColor.withOpacity(0.9),
                              fontSize: 11,
                              fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                  // Percentage Ring
                  CircularPercentIndicator(
                    radius: 28.0,
                    lineWidth: 4.0,
                    percent: attendancePercentage,
                    center: Text(
                      "${(attendancePercentage * 100).toInt()}%",
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12),
                    ),
                    progressColor: themeColor == Colors.white24
                        ? Colors.blueAccent
                        : themeColor,
                    backgroundColor: Colors.white10,
                    circularStrokeCap: CircularStrokeCap.round,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Action Buttons Row
              Row(
                children: [
                  _ActionButton(
                    label: "Cancel",
                    icon: Icons.block,
                    color: const Color(0xFFFBBF24),
                    isActive: lecture.status == "CANCELLED",
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
                    icon: Icons.cancel_outlined,
                    color: const Color(0xFFF87171),
                    isActive: lecture.status == "ABSENT",
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
                    icon: Icons.check_circle_outline,
                    color: const Color(0xFF4ADE80),
                    isActive: lecture.status == "PRESENT",
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
    );
  }

  void _updateStatus(String newStatus) async {
    lecture.status = newStatus;
    await DatabaseService.lectureBox.put(lecture.lectureUID, lecture);
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isActive;
  final VoidCallback onTap;

  const _ActionButton(
      {required this.label,
      required this.icon,
      required this.color,
      required this.isActive,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? color.withOpacity(0.2) : color.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isActive ? color : color.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon,
                  color: isActive ? color : color.withOpacity(0.5), size: 18),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isActive ? color : color.withOpacity(0.5),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
