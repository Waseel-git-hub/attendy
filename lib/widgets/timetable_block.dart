import 'package:flutter/material.dart';
//------------------------------------------------------------------------------

class SubjectBlock extends StatelessWidget {
  final String title;
  final String room;
  final Color color;
  final double top; // Calculated based on start time
  final double height; // Calculated based on duration
  final double left; // Calculated based on day (Mon, Tue, etc.)
  final double width;
  final VoidCallback onTap;
  final VoidCallback onHold;

  const SubjectBlock({
    super.key,
    required this.title,
    required this.room,
    required this.color,
    required this.top,
    required this.height,
    required this.left,
    required this.width,
    required this.onTap,
    required this.onHold,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      left: left,
      width: width,
      height: height,
      child: InkWell(
        onTap: onTap,
        onLongPress: onHold,
        child: Container(
          margin: const EdgeInsets.all(2),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: Colors.white)),
              Text(room,
                  style: const TextStyle(fontSize: 10, color: Colors.white70)),
            ],
          ),
        ),
      ),
    );
  }
}
