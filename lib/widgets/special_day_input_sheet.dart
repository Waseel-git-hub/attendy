import 'package:Attendy/services/database_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:Attendy/models/special_day.dart';

void showAddSpecialDaySheet(BuildContext context, ThemeData theme,
    {SpecialDay? existingItem, DateTime? inputDate}) {
  final colorScheme = theme.colorScheme;
  final TextEditingController reasonController = TextEditingController();

  bool isLeave = true; // True = No Lectures, False = Normal
  bool isRange = false; // True = Range, False = Single Day

  DateTime? singleDate;
  DateTime? startDate;
  DateTime? endDate;

  final bool dayInput = inputDate != null;
  // --- PRE-FILL LOGIC FOR EDIT MODE ---
  final bool isEditing = existingItem != null;
  String? oldGroupId;

  if (isEditing) {
    reasonController.text = existingItem.reason;
    isLeave = existingItem.isLeave;
    oldGroupId = existingItem.groupID;

    if (oldGroupId.isNotEmpty && oldGroupId.contains('_')) {
      final segments = oldGroupId.split('_');
      if (segments.length == 3) {
        final parsedStart = DateFormat('yyyy-MM-dd').parse(segments[0]);
        final parsedEnd = DateFormat('yyyy-MM-dd').parse(segments[1]);
        final int diff = int.tryParse(segments[2]) ?? 0;

        if (diff == 0) {
          isRange = false;
          singleDate = parsedStart;
          startDate = parsedStart; // Pre-populate boundaries to avoid nulls
          endDate = parsedStart;
        } else {
          isRange = true;
          startDate = parsedStart;
          endDate = parsedEnd;
          singleDate = parsedStart; // Pre-populate single fallback
        }
      }
    }
  }
  if (dayInput) {
    isRange = false;
    singleDate = inputDate;
  }

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (bottomSheetContext) {
      // Renamed context parameter to prevent shading
      return StatefulBuilder(
        builder: (BuildContext sheetContext, StateSetter setSheetState) {
          // Renamed context parameter
          // Helper method to dynamically update the informational footer text
          String getFooterText() {
            String timing = "";
            if (!isRange && singleDate != null) {
              timing = "on ${DateFormat('dd MMM').format(singleDate!)}";
            } else if (isRange && startDate != null && endDate != null) {
              timing =
                  "from ${DateFormat('dd MMM').format(startDate!)} to ${DateFormat('dd MMM').format(endDate!)}";
            } else {
              timing = "on these days";
            }

            return isLeave
                ? "ℹ️ Lectures will be skipped $timing."
                : "ℹ️ Lectures will follow normal scheduling $timing.";
          }

          return Padding(
            padding: EdgeInsets.fromLTRB(
                20, 20, 20, MediaQuery.of(sheetContext).viewInsets.bottom + 20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // TITLE TITLE (Switches dynamically)
                  Text(
                    isEditing ? "Edit Special Day" : "Add Special Day",
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  // 1. REASON FIELD
                  Text(
                    "Reason",
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 2),
                  TextField(
                    controller: reasonController,
                    decoration: const InputDecoration(
                      hintText: "e.g., Independence Day, Study Leave",
                      hintStyle: TextStyle(fontSize: 14),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // --- LECTURE IMPACT SECTION ---
                  Text(
                    "Lecture Impact",
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      {"label": "No Lectures", "value": true},
                      {"label": "Normal", "value": false},
                    ].map((impact) {
                      final label = impact["label"] as String;
                      final value = impact["value"] as bool;
                      final isSelected = isLeave == value;

                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                          child: ChoiceChip(
                            label: Center(child: Text(label)),
                            selected: isSelected,
                            onSelected: (_) =>
                                setSheetState(() => isLeave = value),
                            selectedColor: colorScheme.primaryContainer,
                            backgroundColor: colorScheme.surfaceContainerLow,
                            labelStyle: TextStyle(
                              color: isSelected
                                  ? colorScheme.onPrimaryContainer
                                  : colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: isSelected
                                    ? colorScheme.onPrimaryFixed
                                    : colorScheme.outlineVariant,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // --- DURATION SECTION ---
                  Text(
                    "Duration",
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      {"label": "Single", "value": false},
                      {"label": "Range", "value": true},
                    ].map((duration) {
                      final label = duration["label"] as String;
                      final value = duration["value"] as bool;
                      final isSelected = isRange == value;

                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                          child: ChoiceChip(
                            label: Center(child: Text(label)),
                            selected: isSelected,
                            onSelected: (_) => setSheetState(() {
                              isRange = value;
                              // Synchronize dates instantly on state change so data isn't missing
                              if (isRange) {
                                startDate ??= singleDate ?? DateTime.now();
                                endDate ??= singleDate ?? DateTime.now();
                              } else {
                                singleDate ??= startDate ?? DateTime.now();
                              }
                            }),
                            selectedColor: colorScheme.primaryContainer,
                            backgroundColor: colorScheme.surfaceContainerLow,
                            labelStyle: TextStyle(
                              color: isSelected
                                  ? colorScheme.onPrimaryContainer
                                  : colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: isSelected
                                    ? colorScheme.onPrimaryFixed
                                    : colorScheme.outlineVariant,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // 4. ADAPTIVE DATE INPUT LOOKUPS
                  Text(
                    "Date Selection",
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 2),
                  if (!isRange) ...[
                    // Single date select layout
                    ListTile(
                      tileColor: colorScheme.surfaceContainerLowest,
                      title: Text(
                        singleDate == null
                            ? "Select Date"
                            : DateFormat('dd MMMM yyyy').format(singleDate!),
                        style: TextStyle(
                          color: singleDate == null
                              ? colorScheme.onSurfaceVariant
                              : colorScheme.onSurface,
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                        ),
                      ),
                      trailing: const Icon(Icons.calendar_today_rounded),
                      shape: RoundedRectangleBorder(
                        side: BorderSide(color: colorScheme.outlineVariant),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context:
                              sheetContext, // Explicit unique context mapping
                          initialDate: singleDate ?? DateTime.now(),
                          firstDate: DateTime(2025),
                          lastDate: DateTime(2030),
                        );
                        if (picked != null) {
                          setSheetState(() {
                            singleDate = picked;
                            startDate = picked;
                            endDate = picked;
                          });
                        }
                      },
                    ),
                  ] else ...[
                    // Range start and end date select layouts
                    Row(
                      children: [
                        Expanded(
                          child: ListTile(
                            tileColor: colorScheme.surfaceContainerLowest,
                            title: Text(
                              startDate == null
                                  ? "Start Date"
                                  : DateFormat('dd  MMM').format(startDate!),
                              style: TextStyle(
                                color: startDate == null
                                    ? colorScheme.onSurfaceVariant
                                    : colorScheme.onSurface,
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                              ),
                            ),
                            trailing: const Icon(
                              Icons.calendar_today_rounded,
                              size: 18,
                            ),
                            shape: RoundedRectangleBorder(
                              side:
                                  BorderSide(color: colorScheme.outlineVariant),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            onTap: () async {
                              final picked = await showDatePicker(
                                context:
                                    sheetContext, // Explicit unique context mapping
                                initialDate: startDate ?? DateTime.now(),
                                firstDate: DateTime(2025),
                                lastDate: DateTime(2030),
                              );
                              if (picked != null) {
                                setSheetState(() {
                                  startDate = picked;
                                  if (endDate != null &&
                                      endDate!.isBefore(picked)) {
                                    endDate = null;
                                  }
                                });
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ListTile(
                            tileColor: colorScheme.surfaceContainerLowest,
                            title: Text(
                              endDate == null
                                  ? "End Date"
                                  : DateFormat('dd  MMM').format(endDate!),
                              style: TextStyle(
                                color: endDate == null
                                    ? colorScheme.onSurfaceVariant
                                    : colorScheme.onSurface,
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                              ),
                            ),
                            trailing: const Icon(
                              Icons.calendar_today_rounded,
                              size: 18,
                            ),
                            shape: RoundedRectangleBorder(
                              side:
                                  BorderSide(color: colorScheme.outlineVariant),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            onTap: () async {
                              final picked = await showDatePicker(
                                context:
                                    sheetContext, // Explicit unique context mapping
                                initialDate:
                                    endDate ?? startDate ?? DateTime.now(),
                                firstDate: startDate ?? DateTime(2025),
                                lastDate: DateTime(2030),
                              );
                              if (picked != null) {
                                setSheetState(() => endDate = picked);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 10),

                  // 5. INFORMATIVE CAPTION FOOTER
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    color: colorScheme.surfaceContainerHigh,
                    child: Text(
                      getFooterText(),
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // 6. SAVE CTA (Handles Edit Validation Rule)
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () async {
                        final finalStart = isRange ? startDate : singleDate;
                        final finalEnd = isRange ? endDate : singleDate;

                        if (reasonController.text.trim().isEmpty ||
                            finalStart == null ||
                            finalEnd == null) {
                          return;
                        }

                        if (isEditing && oldGroupId != null) {
                          await DatabaseService.deleteSpecialDayRange(
                              oldGroupId);
                        }

                        await DatabaseService.addSpecialDayRange(
                          reason: reasonController.text.trim(),
                          isLeave: isLeave,
                          startDate: finalStart,
                          endDate: finalEnd,
                        );

                        if (bottomSheetContext.mounted) {
                          Navigator.pop(
                              bottomSheetContext); // Target sheet layout stack cleanly
                        }
                      },
                      child: const Text(
                        "Save",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}
