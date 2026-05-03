import 'package:flutter/material.dart';
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
    // 1. Fetch Subject data linked to this lecture
    final Subject? subject = DatabaseService.getSubjectById(lecture.subjectID);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:
            Theme.of(context).cardColor, // Deep surface color from your image
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Subject Name & Room
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                subject?.name ?? "Unknown Subject",
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  "Room: ${lecture.roomNo}",
                  style: const TextStyle(color: Colors.white38, fontSize: 11),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Middle: Attendance Ring & Insight
          Row(
            children: [
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lecture.status == "NONE"
                        ? "Mark your status"
                        : "Status: ${lecture.status}",
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Action Buttons: Update status and save to Hive
          Row(
            children: [
              _ActionButton(
                label: "Present",
                icon: Icons.check_circle_rounded,
                color: const Color(0xFF6366F1), // Your primary indigo
                isActive: lecture.status == "PRESENT",
                onTap: () {
                  if (lecture.status == "PRESENT")
                    _updateStatus("NONE");
                  else
                    _updateStatus("PRESENT");
                },
              ),
              const SizedBox(width: 10),
              _ActionButton(
                label: "Absent",
                icon: Icons.cancel_rounded,
                color: Colors.redAccent,
                isActive: lecture.status == "ABSENT",
                onTap: () {
                  if (lecture.status == "ABSENT")
                    _updateStatus("NONE");
                  else
                    _updateStatus("ABSENT");
                },
              ),
              const SizedBox(width: 10),
              _ActionButton(
                label: "Cancel",
                icon: Icons.remove_circle_outline_rounded,
                color: Colors.white38,
                isActive: lecture.status == "CANCELLED",
                onTap: () {
                  if (lecture.status == "CANCELLED")
                    _updateStatus("NONE");
                  else
                    _updateStatus("CANCELLED");
                },
              ),
            ],
          ),
        ],
      ),
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
