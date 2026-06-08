import 'package:flutter/material.dart';
import '../../models/DTO/draft.dart';
import '../../models/timetable.dart';
import '../../services/database_service.dart';

class SetupTimetableScreen extends StatefulWidget {
  final SetupDraft setupDraft;
  final VoidCallback onBack;
  final VoidCallback onNext;
  final bool isFromOnboarding;

  const SetupTimetableScreen({
    super.key,
    required this.setupDraft,
    required this.isFromOnboarding,
    required this.onNext,
    required this.onBack,
  });

  @override
  State<SetupTimetableScreen> createState() => _SetupTimetableScreenState();
}

class _SetupTimetableScreenState extends State<SetupTimetableScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _formatTime(int hour, int minute) {
    final String period = hour >= 12 ? "PM" : "AM";
    final int displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    final String displayMinute = minute.toString().padLeft(2, '0');
    return "$displayHour:$displayMinute $period";
  }

  TimeOfDay _defaultEnd(TimeOfDay start, int durationMinutes) {
    int startMinutes = (start.hour * 60) + start.minute;
    int endMinutes = (startMinutes + durationMinutes) % 1440;

    return TimeOfDay(
      hour: endMinutes ~/ 60,
      minute: endMinutes % 60,
    );
  }

  void _openAddOrEditBottomSheet(ThemeData theme, int dayIndex,
      {TimetableEntryDraft? existingSlot}) {
    final colorScheme = theme.colorScheme;

    dynamic selectedSubjectId = existingSlot?.subjectTemporaryId;
    if (selectedSubjectId == null && widget.setupDraft.subjects.isNotEmpty) {
      selectedSubjectId = widget.setupDraft.subjects.first.temporaryId;
    }

    TimeOfDay startTime;
    if (existingSlot != null) {
      startTime = TimeOfDay(
          hour: existingSlot.startHour, minute: existingSlot.startMinute);
    } else {
      final existingDaySlots = widget.setupDraft.timetableSlots
          .where((slot) => slot.dayOfWeek == dayIndex)
          .toList();

      if (existingDaySlots.isNotEmpty) {
        existingDaySlots.sort((a, b) {
          if (a.endHour != b.endHour) return a.endHour.compareTo(b.endHour);
          return a.endMinute.compareTo(b.endMinute);
        });
        final lastSlot = existingDaySlots.last;
        startTime =
            TimeOfDay(hour: lastSlot.endHour, minute: lastSlot.endMinute);
      } else {
        startTime = const TimeOfDay(hour: 9, minute: 0);
      }
    }

    TimeOfDay endTime;
    int currentDurationMinutes = 60;
    bool isEndTimeManual = existingSlot != null;

    if (existingSlot != null) {
      endTime =
          TimeOfDay(hour: existingSlot.endHour, minute: existingSlot.endMinute);
      int startTotalMin =
          (existingSlot.startHour * 60) + existingSlot.startMinute;
      int endTotalMin = (existingSlot.endHour * 60) + existingSlot.endMinute;
      currentDurationMinutes = endTotalMin - startTotalMin;
    } else {
      endTime = _defaultEnd(startTime, currentDurationMinutes);
    }

    final TextEditingController roomController =
        TextEditingController(text: existingSlot?.roomNo ?? '');
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                top: 24,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // --- HEADER CONTROLS ---
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            existingSlot == null
                                ? "Add Class Slot"
                                : "Edit Class Slot",
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (existingSlot != null)
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded,
                                  color: Colors.redAccent),
                              onPressed: () {
                                setState(() {
                                  widget.setupDraft.timetableSlots
                                      .remove(existingSlot);
                                });
                                Navigator.pop(context);
                              },
                            )
                        ],
                      ),
                      const SizedBox(height: 24),

                      //  DROPDOWN SELECTION FIELD
                      Text("Select Subject",
                          style: TextStyle(
                              color: colorScheme.onSurface, fontSize: 13)),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<dynamic>(
                        value: selectedSubjectId,
                        dropdownColor: colorScheme.surfaceContainerHigh,
                        style: const TextStyle(fontSize: 15),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: colorScheme.surfaceContainerHigh,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                                color: Colors.white.withOpacity(0.05)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                const BorderSide(color: Color(0xFF6366F1)),
                          ),
                        ),
                        items: widget.setupDraft.subjects.map((sub) {
                          return DropdownMenuItem<dynamic>(
                            value: sub.temporaryId,
                            child: Row(
                              children: [
                                Icon(
                                  IconData(sub.iconCodePoint,
                                      fontFamily: 'MaterialIcons'),
                                  color: Color(sub.colorValue),
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Text(sub.name,
                                    style: TextStyle(
                                        color: colorScheme.onSurface)),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (val) =>
                            setSheetState(() => selectedSubjectId = val),
                        validator: (val) =>
                            val == null ? "Please select a subject" : null,
                      ),
                      const SizedBox(height: 20),

                      // --- TIME PICKERS (AUTOMATED TRACKS) ---
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Start Time",
                                    style: TextStyle(
                                        color: colorScheme.onSurface,
                                        fontSize: 13)),
                                const SizedBox(height: 8),
                                InkWell(
                                  onTap: () async {
                                    final TimeOfDay? picked =
                                        await showTimePicker(
                                            context: context,
                                            initialTime: startTime);
                                    if (picked != null) {
                                      setSheetState(() {
                                        startTime = picked;
                                        if (!isEndTimeManual) {
                                          endTime = _defaultEnd(startTime,
                                              currentDurationMinutes);
                                        }
                                      });
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 14, horizontal: 16),
                                    decoration: BoxDecoration(
                                      color: colorScheme.surfaceContainerHigh,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                          color:
                                              Colors.white.withOpacity(0.05)),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(_formatTime(
                                            startTime.hour, startTime.minute)),
                                        Icon(Icons.access_time_rounded,
                                            color: colorScheme.onSurface,
                                            size: 18),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("End Time",
                                    style: TextStyle(
                                        color: colorScheme.onSurface,
                                        fontSize: 13)),
                                const SizedBox(height: 8),
                                InkWell(
                                  onTap: () async {
                                    final TimeOfDay? picked =
                                        await showTimePicker(
                                            context: context,
                                            initialTime: endTime);
                                    if (picked != null) {
                                      setSheetState(() {
                                        endTime = picked;
                                        isEndTimeManual = true;
                                      });
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 14, horizontal: 16),
                                    decoration: BoxDecoration(
                                      color: colorScheme.surfaceContainerHigh,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                          color:
                                              Colors.white.withOpacity(0.05)),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          _formatTime(
                                              endTime.hour, endTime.minute),
                                        ),
                                        Icon(Icons.access_time_rounded,
                                            color: colorScheme.onSurface,
                                            size: 18),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // --- ROOM ENTRY ---
                      Text("Room / Location (Optional)",
                          style: TextStyle(
                              color: colorScheme.onSurface, fontSize: 13)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: roomController,
                        style:
                            const TextStyle(color: Colors.white, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: "e.g., Lab 3, Room 402",
                          hintStyle: TextStyle(
                              color: colorScheme.onSurface.withOpacity(0.5)),
                          filled: true,
                          fillColor: colorScheme.surfaceContainerHigh,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                                color: Colors.white.withOpacity(0.05)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                const BorderSide(color: Color(0xFF6366F1)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),

                      // --- ACTION BUTTON ---
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            if (!formKey.currentState!.validate()) return;

                            double startDouble =
                                startTime.hour + startTime.minute / 60.0;
                            double endDouble =
                                endTime.hour + endTime.minute / 60.0;

                            if (endDouble <= startDouble) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      "End time must be after start time."),
                                  backgroundColor: Colors.redAccent,
                                ),
                              );
                              return;
                            }

                            setState(() {
                              final newSlot = TimetableEntryDraft.create(
                                dayOfWeek: dayIndex,
                                startHour: startTime.hour,
                                startMinute: startTime.minute,
                                endHour: endTime.hour,
                                endMinute: endTime.minute,
                                roomNo: roomController.text.trim(),
                                subjectTemporaryId: selectedSubjectId,
                              );

                              if (existingSlot != null) {
                                final idx = widget.setupDraft.timetableSlots
                                    .indexOf(existingSlot);
                                if (idx != -1) {
                                  widget.setupDraft.timetableSlots[idx] =
                                      newSlot;
                                }
                              } else {
                                widget.setupDraft.timetableSlots.add(newSlot);
                              }
                            });
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6366F1),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: Text(
                              existingSlot == null
                                  ? "Create Class Slot"
                                  : "Apply Changes",
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _handleSavePipeline() async {
    if (widget.isFromOnboarding) {
      widget.onNext();
    } else {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      try {
        // 1. Build the list of updated layout templates
        final List<TimetableEntry> productionEntries = [];

        for (var draftSlot in widget.setupDraft.timetableSlots) {
          final productionEntry = TimetableEntry(
            dayOfWeek: draftSlot.dayOfWeek,
            startHour: draftSlot.startHour,
            startMinute: draftSlot.startMinute,
            endHour: draftSlot.endHour,
            endMinute: draftSlot.endMinute,
            roomNo: draftSlot.roomNo,
            subjectID:
                int.tryParse(draftSlot.subjectTemporaryId?.toString() ?? '') ??
                    draftSlot.subjectTemporaryId,
            semesterID: 'semester',
          );
          productionEntries.add(productionEntry);
        }

        // 2. Clear out old template blocks and update the structural reference box
        await DatabaseService.timetableBox.clear();
        await DatabaseService.timetableBox.addAll(productionEntries);

        // 3. Automatically sync structural updates across all future days
        // Replace with your actual dynamic terminal date lookup if managed dynamically
        final DateTime semesterEndDate =
            DateTime.now().add(const Duration(days: 120));

        await DatabaseService.syncMidSemesterTimetableUpdates(
          newTimetableTemplates: productionEntries,
          semesterEndDate: semesterEndDate,
        );

        if (!context.mounted) return;
        Navigator.pop(context); // Dismiss loading screen
        Navigator.pop(context); // Navigate back to standard Home grid view

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text("Timetable and calendar tracked instances synchronized!"),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        if (!context.mounted) return;
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error saving updates to local storage: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final int currentDayIndex = _tabController.index + 1; // 1 = Mon, 7 = Sun

    final List<TimetableEntryDraft> daySlots = widget.setupDraft.timetableSlots
        .where((slot) => slot.dayOfWeek == currentDayIndex)
        .toList();

    daySlots.sort((a, b) {
      if (a.startHour != b.startHour) return a.startHour.compareTo(b.startHour);
      return a.startMinute.compareTo(b.startMinute);
    });

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Text(
          widget.isFromOnboarding ? "Set Up Schedule" : "Edit Timetable",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: widget.onBack,
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: colorScheme.primary,
          labelColor: colorScheme.primary,
          unselectedLabelColor: colorScheme.onSurface.withOpacity(0.5),
          tabs: _days.map((day) => Tab(text: day)).toList(),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: daySlots.isEmpty
                  ? Center(child: _buildEmptyStateCard(theme, currentDayIndex))
                  : _buildSlotsListView(theme, daySlots, currentDayIndex),
            ),
          ),
          Padding(
            padding:
                const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 24.0),
            child: _buildBottomActionBar(colorScheme),
          ),
        ],
      ),
    );
  }

  // --- PRIVATE GRAPHIC FACTORIES ---

  Widget _buildEmptyStateCard(ThemeData theme, int dayIndex) {
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: colorScheme.onSurface.withOpacity(0.04), width: 1),
        color: colorScheme.surfaceContainerHigh,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLowest,
              shape: BoxShape.circle,
              border:
                  Border.all(color: colorScheme.onSurface.withOpacity(0.04)),
            ),
            child: Icon(Icons.calendar_today_rounded,
                size: 32, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 20),
          const Text(
            "No classes scheduled",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            "Keep it free or draft a standard session window loop.",
            textAlign: TextAlign.center,
            style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _openAddOrEditBottomSheet(theme, dayIndex),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            ),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text("Add Class Slot",
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildSlotsListView(
      ThemeData theme, List<TimetableEntryDraft> slots, int dayIndex) {
    final colorScheme = theme.colorScheme;
    return ListView.separated(
      itemCount: slots.length + 1,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        if (index == slots.length) {
          return InkWell(
            onTap: () => _openAddOrEditBottomSheet(theme, dayIndex),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colorScheme.onSurface, width: 1.5),
                color: colorScheme.surfaceContainerHigh,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_circle_outline_rounded,
                      color: colorScheme.onSurface.withOpacity(0.7), size: 18),
                  const SizedBox(width: 8),
                  Text(
                    "Add Another Slot",
                    style: TextStyle(
                        color: colorScheme.onSurface.withOpacity(0.5),
                        fontWeight: FontWeight.bold,
                        fontSize: 14),
                  ),
                ],
              ),
            ),
          );
        }

        final slot = slots[index];
        final associatedSubject = widget.setupDraft.subjects.firstWhere(
          (sub) => sub.temporaryId == slot.subjectTemporaryId,
          orElse: () => SubjectDraft(
              temporaryId: '',
              name: 'Free Period / Unknown',
              iconCodePoint: 57404,
              colorValue: 0xFF2E303E),
        );

        final Color blockColor = Color(associatedSubject.colorValue);

        return GestureDetector(
          onTap: () =>
              _openAddOrEditBottomSheet(theme, dayIndex, existingSlot: slot),
          child: Container(
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colorScheme.onSurface, width: 1),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(width: 6, color: blockColor),
                    const SizedBox(width: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _formatTime(slot.startHour, slot.startMinute),
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatTime(slot.endHour, slot.endMinute),
                            style: TextStyle(
                                color: colorScheme.onSurface.withOpacity(0.5),
                                fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),
                    VerticalDivider(
                        color: Colors.grey.shade800,
                        thickness: 1,
                        indent: 14,
                        endIndent: 14),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              associatedSubject.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            if (slot.roomNo.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.location_on_rounded,
                                      size: 12, color: Colors.grey.shade500),
                                  const SizedBox(width: 4),
                                  Text(
                                    "Room ${slot.roomNo}",
                                    style: TextStyle(
                                        color: Colors.grey.shade500,
                                        fontSize: 12),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.remove_circle_outline_rounded,
                          color: Colors.red.shade400, size: 20),
                      onPressed: () {
                        setState(() {
                          widget.setupDraft.timetableSlots.remove(slot);
                        });
                      },
                    ),
                    const SizedBox(width: 6),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomActionBar(ColorScheme colorScheme) {
    if (widget.isFromOnboarding) {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: widget.onBack,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: colorScheme.onSurface),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              icon: Icon(Icons.keyboard_return,
                  color: colorScheme.onSurface, size: 18),
              label: Text("Back",
                  style: TextStyle(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                      fontSize: 15)),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _handleSavePipeline,
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                side: BorderSide(color: colorScheme.primary),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              icon:
                  const Icon(Icons.info_outline, color: Colors.white, size: 18),
              label: const Text("Semester Info",
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15)),
            ),
          ),
        ],
      );
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _handleSavePipeline,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF6366F1),
          foregroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        icon: const Icon(Icons.check_circle_outline, size: 18),
        label: const Text("Save Timetable changes",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
      ),
    );
  }
}
