import 'package:Attendy/services/database_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/special_day.dart';

import '../widgets/special_day_input_sheet.dart';

class AcademicCalendarListPage extends StatelessWidget {
  final ThemeData theme;

  const AcademicCalendarListPage({super.key, required this.theme});

  @override
  Widget build(BuildContext context) {
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Academic Calendar",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
        centerTitle: true,
        actions: [
          IconButton(
              onPressed: () {}, icon: const Icon(Icons.more_vert_rounded)),
        ],
      ),
      body: Stack(
        children: [
          ValueListenableBuilder<Box<SpecialDay>>(
            valueListenable: DatabaseService.specialDayBox.listenable(),
            builder: (context, box, _) {
              // inside ValueListenableBuilder build logic...
              final List<SpecialDay> flatDaysList = box.values.toList();
              flatDaysList.sort((a, b) => a.date.compareTo(b.date));

              final List<SpecialDay> holidays = [];
              final List<SpecialDay> events = [];

              int i = 0;
              while (i < flatDaysList.length) {
                final currentItem = flatDaysList[i];
                final String groupId = currentItem.groupID;

                // 1. Determine how many spaces we need to leap ahead
                int totalDaysInBlock = 1;
                if (groupId.isNotEmpty && groupId.contains('_')) {
                  final segments = groupId.split('_');
                  if (segments.length == 3) {
                    final int diff = int.tryParse(segments[2]) ?? 0;
                    totalDaysInBlock = diff + 1;
                  }
                }

                // 2. Add the first day object of this group directly to your UI display buckets
                if (currentItem.isLeave) {
                  holidays.add(currentItem);
                } else {
                  events.add(currentItem);
                }

                // 3. Take the leap 😉
                i += totalDaysInBlock;
              }
              return SingleChildScrollView(
                padding: const EdgeInsets.only(
                    left: 16.0, right: 16.0, top: 16.0, bottom: 100.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ================= CONTAINER 1: HOLIDAYS =================
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: colorScheme.outlineVariant),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionDivider(
                              label: "Holidays & Off-Days",
                              count: holidays.length,
                              color: colorScheme.error,
                              theme: theme),
                          const SizedBox(height: 12),
                          _buildInnerSubList(holidays, colorScheme),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ================= CONTAINER 2: EVENTS =================
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: colorScheme.outlineVariant),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionDivider(
                              label: "Campus Events & Fests",
                              count: events.length,
                              color: colorScheme.secondary,
                              theme: theme),
                          const SizedBox(height: 12),
                          _buildInnerSubList(events, colorScheme),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          // Bottom Fixed Action Anchor
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 16,
            left: 16,
            right: 16,
            child: SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () {
                  showAddSpecialDaySheet(context, theme);
                },
                icon: const Icon(Icons.add_rounded, size: 20),
                label: const Text("Add Special Day",
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ),
            ),
          )
        ],
      ),
      // Bottom Fixed Action Anchor
    );
  }

  Widget _buildSectionDivider(
      {required String label,
      required int count,
      required Color color,
      required ThemeData theme}) {
    final colorScheme = theme.colorScheme;
    return Row(
      children: [
        Container(
          width: 3.5,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color.withOpacity(0.85)),
        ),
        const SizedBox(width: 6),
        Text(
          "($count)",
          style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }

  Widget _buildInnerSubList(List<SpecialDay> items, ColorScheme colorScheme) {
    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
        child: Text(
          "No days added in this section yet.",
          style: TextStyle(
              fontSize: 12,
              color: colorScheme.onSurfaceVariant.withOpacity(0.6),
              fontStyle: FontStyle.italic),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      separatorBuilder: (context, index) =>
          Divider(color: colorScheme.outlineVariant, height: 24),
      itemBuilder: (context, index) {
        // Inside your row itemBuilder context...
        final item = items[index];
        final String groupId = item.groupID;

        String dateDisplayRangeText = "";

// Parse the compound string to build the UI text formatting
        if (groupId.isNotEmpty && groupId.contains('_')) {
          final segments = groupId.split('_');
          if (segments.length == 3) {
            final String startStr = segments[0]; // "05-09-2026"
            final String endStr = segments[1]; // "07-09-2026"
            final int diff = int.tryParse(segments[2]) ?? 0;

            if (diff == 0) {
              // Single day case: Convert "15-08-2026" into human-friendly format
              final parsedDate = DateFormat('yyyy-MM-dd').parse(startStr);
              dateDisplayRangeText =
                  DateFormat('d MMMM yyyy').format(parsedDate);
            } else {
              // Multi-day range case
              final startDateTime = DateFormat('yyyy-MM-dd').parse(startStr);
              final endDateTime = DateFormat('yyyy-MM-dd').parse(endStr);

              if (startDateTime.month == endDateTime.month) {
                // Same month: "5 – 7 September 2026"
                final monthYearStr =
                    DateFormat('MMMM yyyy').format(startDateTime);
                dateDisplayRangeText =
                    "${startDateTime.day} – ${endDateTime.day} $monthYearStr";
              } else {
                // Month overlap: "28 Oct – 2 Nov 2026"
                dateDisplayRangeText =
                    "${DateFormat('d MMM').format(startDateTime)} – ${DateFormat('d MMM yyyy').format(endDateTime)}";
              }
            }
          }
        }
        return InkWell(
          onTap: () {
            showAddSpecialDaySheet(context, theme, existingItem: item);
          },
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: item.isLeave
                      ? colorScheme.errorContainer
                      : colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  item.isLeave
                      ? Icons.event_busy_rounded
                      : Icons.event_available_rounded,
                  color: item.isLeave
                      ? colorScheme.onErrorContainer
                      : colorScheme.onPrimaryContainer,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.reason,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(dateDisplayRangeText,
                        style: TextStyle(
                            fontSize: 14, color: colorScheme.onSurfaceVariant)),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: item.isLeave
                      ? colorScheme.errorContainer
                      : colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  item.isLeave ? "No Lecture" : "Normal",
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: item.isLeave
                          ? colorScheme.onErrorContainer
                          : colorScheme.onPrimaryContainer),
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right_rounded,
                  size: 16, color: colorScheme.onSurfaceVariant),
            ],
          ),
        );
      },
    );
  }
}
