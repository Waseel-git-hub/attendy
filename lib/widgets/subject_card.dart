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
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  (!isSelected)
                      ? IconData(subject.iconCodePoint,
                          fontFamily: 'MaterialIcons')
                      : Icons.check_circle,
                  color: color,
                  size: 33,
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
            ],
          ),
        ),
      ),
    );
  }
}
