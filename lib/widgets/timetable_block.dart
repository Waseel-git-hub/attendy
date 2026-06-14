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
    //TODO
    final bool roomAvailable = room != '';
    ColorScheme colorScheme = Theme.of(context).colorScheme;
    return Positioned(
      top: top,
      left: left,
      width: width,
      height: height,
      child: InkWell(
        onTap: onTap,
        onLongPress: onHold,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          margin: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: colorScheme.outlineVariant,
            ),
          ),
          clipBehavior: Clip.hardEdge,
          child: Column(
            children: [
              Expanded(
                child: Container(
                  width: double.infinity,
                  color: color,
                  alignment: Alignment.center,
                  child: Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              if (roomAvailable) ...[
                Container(
                  width: width,
                  height: height / 3.5,
                  alignment: Alignment.center,
                  color: colorScheme.primaryContainer,
                  child: Text(
                    room,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
