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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.05),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: colorScheme.onSurface.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    "Filter Lectures",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 1. STATUS SELECTION CHIPS
                  _buildSectionTitle("Status"),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children:
                        ["All", "Present", "Absent", "Cancelled"].map((status) {
                      final isSelected = _filterStatus == status;
                      return _buildFilterChip(
                        text: status,
                        isSelected: isSelected,
                        onTap: () =>
                            setModalState(() => _filterStatus = status),
                        colorScheme: colorScheme,
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  // 2. SUBJECTS FILTER CHIPS BLOCK
                  _buildSectionTitle("Subjects"),
                  const SizedBox(height: 10),
                  ValueListenableBuilder(
                    valueListenable: DatabaseService.subjectBox.listenable(),
                    builder: (context, Box<Subject> box, _) {
                      return Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          // Explicit "All Subjects" starting anchor
                          _buildFilterChip(
                            text: "All Subjects",
                            isSelected: _filterSubjectId == null,
                            onTap: () =>
                                setModalState(() => _filterSubjectId = null),
                            colorScheme: colorScheme,
                          ),
                          ...box.values.map((sub) {
                            final isSelected = _filterSubjectId == sub.key;
                            return _buildFilterChip(
                              text: sub.name,
                              isSelected: isSelected,
                              onTap: () => setModalState(
                                  () => _filterSubjectId = sub.key),
                              colorScheme: colorScheme,
                              accentColor: Color(sub.colorValue),
                            );
                          }),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 36),

                  // 3. ACTION TRIGGERS (RESET / APPLY)
                  Row(
                    children: [
                      TextButton(
                        onPressed: () {
                          setModalState(() {
                            _filterSubjectId = null;
                            _filterStatus = "All";
                          });
                        },
                        child: Text(
                          "Reset",
                          style: TextStyle(
                              color: colorScheme.onSurface.withOpacity(0.6),
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                      const Spacer(),
                      ElevatedButton(
                        onPressed: () {
                          setState(
                              () {}); // Repaints host calendar with updated rulesets
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 44, vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                        child: const Text("Apply",
                            style: TextStyle(fontWeight: FontWeight.bold)),
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

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
          fontSize: 19, fontWeight: FontWeight.w600, letterSpacing: 0.3),
    );
  }

  Widget _buildFilterChip({
    required String text,
    required bool isSelected,
    required VoidCallback onTap,
    required ColorScheme colorScheme,
    Color? accentColor,
  }) {
    final activeThemeColor = accentColor ?? colorScheme.primary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? activeThemeColor
              : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : colorScheme.onSurface.withOpacity(0.2),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected) ...[
              const Icon(Icons.check_rounded, color: Colors.white, size: 14),
              const SizedBox(width: 6),
            ],
            Text(
              text,
              style: TextStyle(
                color: isSelected ? Colors.white : colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
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
            icon: Icon(Icons.tune_rounded,
                color: colorScheme
                    .primary), // System modern filter configuration icon
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
              defaultTextStyle: const TextStyle(fontWeight: FontWeight.w500),
              weekendTextStyle: TextStyle(
                  color: colorScheme.error.withOpacity(0.8),
                  fontWeight: FontWeight.w500),
              todayDecoration: BoxDecoration(
                color: colorScheme.onSurface.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              todayTextStyle: const TextStyle(fontWeight: FontWeight.bold),
              selectedDecoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.7),
                shape: BoxShape.circle,
              ),
              selectedTextStyle: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold),
            ),
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle:
                  TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
              color: colorScheme.onSurface.withOpacity(0.7), fontSize: 14),
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
            color: colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(14),
          ),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: subColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                IconData(subject?.iconCodePoint ?? Icons.book_rounded.codePoint,
                    fontFamily: 'MaterialIcons'),
                color: subColor,
                size: 20,
              ),
            ),
            title: Text(
              subject?.name ?? "Unknown Subject",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                lec.status,
                style: TextStyle(
                    color: statusColor.withOpacity(0.8),
                    fontWeight: FontWeight.w600,
                    fontSize: 13),
              ),
            ),
            trailing: Icon(Icons.circle, color: statusColor, size: 10),
          ),
        );
      },
    );
  }
}
