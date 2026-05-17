import 'package:flutter/material.dart';

class CustomCircleProgress extends StatelessWidget {
  final double percentage;
  final double size;
  final double strokeWidth;
  final Color? progressColor;
  final Color? emptyProgressColor;
  final bool showLabel;
  final double fontSize;
  final Color? labelColor;
  final bool showSubLabel;
  final String subLabel;

  const CustomCircleProgress({
    super.key,
    required this.percentage,
    this.size = 90,
    this.strokeWidth = 9,
    this.progressColor,
    this.emptyProgressColor,
    this.showLabel = true,
    this.labelColor,
    this.fontSize = 18,
    this.showSubLabel = false,
    this.subLabel = '',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Check if there is genuinely no attendance record data yet
    final bool isNoData = percentage.isNaN || percentage <= 0.0;
    final double safePercentage = isNoData ? 0.0 : percentage.clamp(0.0, 100.0);

    // Fallback indicator ring color when empty or tracking normally
    final Color activeRingColor = isNoData
        ? theme.colorScheme.onSurface.withOpacity(0.1)
        : (progressColor ?? theme.colorScheme.primary);

    final Color inActiveRingColor = emptyProgressColor ??
        theme.colorScheme.surfaceContainerHighest.withOpacity(0.5);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 1. Core Background Track
          SizedBox.expand(
            child: CircularProgressIndicator(
              value: 1.0,
              strokeWidth: strokeWidth,
              valueColor: AlwaysStoppedAnimation<Color>(
                inActiveRingColor,
              ),
            ),
          ),

          // 2. Main Active Moving Progress Ring Overlay
          if (!isNoData)
            SizedBox.expand(
              child: CircularProgressIndicator(
                value: safePercentage / 100,
                strokeWidth: strokeWidth,
                backgroundColor: Colors.transparent,
                valueColor: AlwaysStoppedAnimation<Color>(activeRingColor),
                strokeCap: StrokeCap.round,
              ),
            ),

          // 3. Central Typography Label Column (FIXED: Zero-state safety check)
          if (showLabel)
            Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  isNoData ? "0%" : "${safePercentage.toStringAsFixed(0)}%",
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.bold,
                    color: labelColor ??
                        (isNoData
                            ? theme.colorScheme.onSurface.withOpacity(0.3)
                            : theme.colorScheme.onSurface),
                  ),
                ),
                const SizedBox(height: 2),
                if (showSubLabel)
                  Text(
                    subLabel,
                    style: TextStyle(
                      fontSize: fontSize * 0.45,
                      color: theme.colorScheme.onSurface.withOpacity(0.4),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}
