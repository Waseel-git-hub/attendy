import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:hive_flutter/hive_flutter.dart';
//  MODELS
import '../../models/lecture.dart';
import '../../models/subject.dart';
//  SERVICES
import '../../services/database_service.dart';
//------------------------------------------------------------

class AttendanceCalendar extends StatefulWidget {
  const AttendanceCalendar({super.key});

  @override
  State<AttendanceCalendar> createState() => _AttendanceCalendarState();
}

class _AttendanceCalendarState extends State<AttendanceCalendar> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  // Filter
  dynamic _filterSubjectId; // null means "All"
  String _filterStatus = "All"; // "All", "Present", "Absent", "Cancelled"

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  List<Lecture> _applyFilters(List<Lecture> rawLectures) {
    return rawLectures.where((lecture) {
      final matchesSubject =
          _filterSubjectId == null || lecture.subjectID == _filterSubjectId;
      final matchesStatus =
          _filterStatus == "All" || lecture.status == _filterStatus;
      return matchesSubject && matchesStatus;
    }).toList();
  }

  void _showFilterBottomSheet(ThemeData theme) {
    final colorScheme = theme.colorScheme;

    // 1. Shield host state by capturing initial filters into local temp variables
    String tempStatus = _filterStatus;
    dynamic tempSubjectId = _filterSubjectId;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              // Handles system navigation bars dynamically via MediaQuery padding bottom
              padding: EdgeInsets.fromLTRB(
                  24, 16, 24, MediaQuery.of(context).padding.bottom + 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top drag handlebar line indicator
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: colorScheme.onSurfaceVariant.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "Filter Lectures",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // SECTION 1: STATUS CHIPS BLOCK
                  Text(
                    "Status",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children:
                        ["All", "Present", "Absent", "Cancelled"].map((status) {
                      final isSelected = tempStatus == status;
                      return ChoiceChip(
                        label: Text(status),
                        selected: isSelected,
                        onSelected: (_) =>
                            setModalState(() => tempStatus = status),
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
                          side: BorderSide.none,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  // SECTION 2: SUBJECTS FILTER CHIPS BLOCK
                  Text(
                    "Subjects",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ValueListenableBuilder(
                    valueListenable: DatabaseService.subjectBox.listenable(),
                    builder: (context, Box<Subject> box, _) {
                      return Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          // Explicit "All Subjects" starting anchor chip
                          ChoiceChip(
                            label: const Text("All Subjects"),
                            selected: tempSubjectId == null,
                            onSelected: (_) =>
                                setModalState(() => tempSubjectId = null),
                            selectedColor: colorScheme.primaryContainer,
                            backgroundColor: colorScheme.surfaceContainerLow,
                            labelStyle: TextStyle(
                              color: tempSubjectId == null
                                  ? colorScheme.onPrimaryContainer
                                  : colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide.none,
                            ),
                          ),
                          ...box.values.map((sub) {
                            final isSelected = tempSubjectId == sub.key;

                            return ChoiceChip(
                              label: Text(sub.name),
                              selected: isSelected,
                              onSelected: (_) =>
                                  setModalState(() => tempSubjectId = sub.key),
                              // Micro-tint background styling matched to subject colors
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
                                side: BorderSide.none,
                              ),
                            );
                          }),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 32),

                  // SECTION 3: ACTION BUTTON ROW (RESET / APPLY)
                  Row(
                    children: [
                      Expanded(
                        child: TextButton.icon(
                          style: TextButton.styleFrom(
                            backgroundColor: colorScheme.surfaceContainerHigh,
                            foregroundColor: colorScheme.onSurfaceVariant,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () {
                            // Clean live reset visual cue within the interactive layout sheet
                            setModalState(() {
                              tempStatus = "All";
                              tempSubjectId = null;
                            });
                          },
                          label: Text(
                            "Reset View",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.primary,
                            foregroundColor: colorScheme.onPrimary,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () {
                            // Commit local selections to host state engine only on explicit tap
                            setState(() {
                              _filterStatus = tempStatus;
                              _filterSubjectId = tempSubjectId;
                            });
                            Navigator.pop(context);
                          },
                          child: const Text(
                            "Apply Filters",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Attendance Calendar",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
        centerTitle: false,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.tune_rounded, color: colorScheme.primary),
            onPressed: () => _showFilterBottomSheet(theme),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: Column(
        children: [
          TableCalendar<Lecture>(
            firstDay: DateTime.utc(2025, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },

            // Runs custom filtering queries inside the loader mapping pipeline
            eventLoader: (DateTime selectedDate) {
              final dayLectures =
                  DatabaseService.getLectures(specificDate: selectedDate);
              return _applyFilters(dayLectures);
            },

            // --- Calendar UI Overrides ---
            calendarStyle: CalendarStyle(
              outsideDaysVisible: false,
              defaultTextStyle: const TextStyle(fontWeight: FontWeight.w400),
              weekendTextStyle: TextStyle(
                  color: colorScheme.error.withOpacity(0.8),
                  fontWeight: FontWeight.w400),
              todayDecoration: BoxDecoration(
                color: colorScheme.surfaceContainerLow,
                shape: BoxShape.circle,
              ),
              todayTextStyle: const TextStyle(fontWeight: FontWeight.w500),
              selectedDecoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              selectedTextStyle: TextStyle(
                  color: colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold),
            ),
            headerStyle: HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle:
                  TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              leftChevronIcon: Icon(Icons.chevron_left_rounded),
              rightChevronIcon: Icon(Icons.chevron_right_rounded),
            ),

            // --- Fixed Dots Marker Architecture ---
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, date, lectures) {
                if (lectures.isEmpty) return null;

                return Positioned(
                  bottom: 6, // Anchors the dots safely beneath the date numbers
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: lectures.take(4).map((lecture) {
                      Color dotColor = Colors.grey;
                      if (lecture.status == "Present")
                        dotColor = const Color(0xFF4ADE80);
                      if (lecture.status == "Absent")
                        dotColor = const Color(0xFFEF4444);
                      if (lecture.status == "Cancelled")
                        dotColor = const Color(0xFFF59E0B);

                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 1.0),
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                            color: dotColor, shape: BoxShape.circle),
                      );
                    }).toList(),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),

          // --- Day Detail List ---
          if (_selectedDay != null)
            Expanded(
              child: _buildDayDetailList(_selectedDay!, theme),
            ),
        ],
      ),
    );
  }

  Widget _buildDayDetailList(DateTime date, ThemeData theme) {
    final colorScheme = theme.colorScheme;
    final rawLectures = DatabaseService.getLectures(specificDate: date);
    final filteredLectures = _applyFilters(rawLectures);

    if (filteredLectures.isEmpty) {
      return Center(
        child: Text(
          rawLectures.isEmpty
              ? "No lectures this day"
              : "No matches for active filter settings",
          style: TextStyle(
            color: colorScheme.onSurfaceVariant,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: filteredLectures.length,
      itemBuilder: (context, index) {
        final lec = filteredLectures[index];
        final subject = DatabaseService.getSubjectById(lec.subjectID);
        final subColor =
            subject != null ? Color(subject.colorValue) : Colors.grey;

        Color statusColor = Colors.grey;
        if (lec.status == "Present") statusColor = const Color(0xFF4ADE80);
        if (lec.status == "Absent") statusColor = const Color(0xFFEF4444);
        if (lec.status == "Cancelled") statusColor = const Color(0xFFF59E0B);

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(14),
            border: BoxBorder.all(color: colorScheme.outlineVariant),
          ),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
            leading: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                border: BoxBorder.all(color: colorScheme.outlineVariant),
                color: subColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                IconData(subject?.iconCodePoint ?? Icons.book_rounded.codePoint,
                    fontFamily: 'MaterialIcons'),
                color: subColor,
                size: 22,
              ),
            ),
            title: Text(
              subject?.name ?? "Unknown Subject",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                lec.status,
                style: TextStyle(
                  color: statusColor.withOpacity(0.8),
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
            trailing: Icon(Icons.circle, color: statusColor, size: 10),
          ),
        );
      },
    );
  }
}
