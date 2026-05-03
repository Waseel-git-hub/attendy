import 'package:flutter/material.dart';
//  MODELS
import '../models/subject.dart';
//------------------------------------------------------------

class SubjectCard extends StatelessWidget {
  final Subject subject;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const SubjectCard({
    super.key,
    required this.subject,
    this.isSelected = false,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final color = Color(subject.colorValue);

    return Card(
      elevation: isSelected ? 8 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isSelected ? BorderSide(color: color, width: 2) : BorderSide.none,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon Container
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  IconData(subject.iconCodePoint, fontFamily: 'MaterialIcons'),
                  color: color,
                  size: 32,
                ),
              ),
              const SizedBox(height: 12),
              // Subject Name
              Text(
                subject.name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              // Selection Indicator (Visible only when selected)
              if (isSelected)
                Padding(
                  padding: const EdgeInsets.fromLTRB(0, 8, 0, 0),
                  child: Icon(Icons.check_circle, color: color, size: 20),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
