import 'package:flutter/material.dart';

class TimelineIndicatorTrack extends StatelessWidget {
  final Widget leftWidget;
  final Widget indicatorNode;
  final bool showTopLine;
  final bool showBottomLine;
  final double leftWidth;
  final Color lineColor;

  const TimelineIndicatorTrack({
    super.key,
    required this.leftWidget,
    required this.indicatorNode,
    this.showTopLine = false,
    this.showBottomLine = true,
    this.leftWidth = 50.0,
    this.lineColor =
        const Color(0x26FFFFFF), // Default lazy white10/white24 shade
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Left side block (Dynamic custom dimensions)
          SizedBox(
            width: leftWidth,
            child: leftWidget,
          ),

          // 2. Center Timeline Node and Track Lines
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Column(
              children: [
                // Top line segment (Only displays on your Home Screen setup)
                Expanded(
                  child: Container(
                    width: 2,
                    color: showTopLine ? lineColor : Colors.transparent,
                  ),
                ),

                // Core Middle Node (Icon or Custom Decorated Dot Container)
                indicatorNode,

                // Bottom line segment tracking downward
                Expanded(
                  child: Container(
                    width: 2,
                    color: showBottomLine ? lineColor : Colors.transparent,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
