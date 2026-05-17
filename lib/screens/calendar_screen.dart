import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
//  MODELS
import '../../models/lecture.dart';
//  SCREENS
//  SERVICES
import '../../services/database_service.dart';
//  WIDGETS
//------------------------------------------------------------

class AttendanceCalendar extends StatefulWidget {
  @override
  _AttendanceCalendarState createState() => _AttendanceCalendarState();
}

class _AttendanceCalendarState extends State<AttendanceCalendar> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
        appBar: AppBar(
          title: Text("Attendance Calendar"),
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
              eventLoader: (DateTime selectedDate) =>
                  DatabaseService.getLectures(
                specificDate: selectedDate,
              ),

              // --- Styling ---
              calendarStyle: CalendarStyle(
                outsideDaysVisible: false,
                defaultTextStyle: TextStyle(color: colorScheme.onSurface),
                weekendTextStyle: TextStyle(color: colorScheme.error),
                todayDecoration: BoxDecoration(
                  color: colorScheme.onSurface.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                todayTextStyle: TextStyle(color: colorScheme.onSurface),
                selectedDecoration: BoxDecoration(
                  color: colorScheme.primary,
                  shape: BoxShape.circle,
                ),
              ),
              headerStyle: HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle:
                    TextStyle(color: colorScheme.onSurface, fontSize: 17),
                leftChevronIcon:
                    Icon(Icons.chevron_left, color: colorScheme.onSurface),
                rightChevronIcon:
                    Icon(Icons.chevron_right, color: colorScheme.onSurface),
              ),

              // --- Custom Markers ---
              calendarBuilders: CalendarBuilders(
                markerBuilder: (context, date, lectures) {
                  if (lectures.isEmpty) return null;

                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: lectures.take(3).map((lecture) {
                      // Color dot based on status
                      Color dotColor = Colors.grey;
                      if (lecture.status == "Present")
                        dotColor = Colors.greenAccent;
                      if (lecture.status == "Absent")
                        dotColor = Colors.redAccent;
                      if (lecture.status == "Cancelled")
                        dotColor = Colors.orangeAccent;

                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 0.5),
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: dotColor,
                          shape: BoxShape.circle,
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ),

            // --- Day Detail List ---
            if (_selectedDay != null)
              Expanded(
                child: _buildDayDetailList(_selectedDay!),
              ),
          ],
        ));
  }

  Widget _buildDayDetailList(DateTime date) {
    final lectures = DatabaseService.getLectures(specificDate: date);
    if (lectures.isEmpty)
      return Center(
          child: Text("No lectures this day",
              style: TextStyle(color: Colors.white38)));

    return ListView.builder(
      itemCount: lectures.length,
      itemBuilder: (context, index) {
        final lec = lectures[index];
        final subject = DatabaseService.getSubjectById(lec.subjectID);
        return ListTile(
          leading: Icon(
              IconData(subject?.iconCodePoint ?? Icons.book.codePoint,
                  fontFamily: 'MaterialIcons'),
              color: Color(subject?.colorValue ?? 0xFF888888)),
          title:
              Text('${subject?.name}', style: TextStyle(color: Colors.white)),
          subtitle: Text(lec.status, style: TextStyle(color: Colors.white38)),
          trailing: Icon(Icons.circle,
              color: lec.status == "Present"
                  ? Colors.greenAccent
                  : lec.status == "Absent"
                      ? Colors.redAccent
                      : lec.status == "Cancelled"
                          ? Colors.orangeAccent
                          : Colors.grey,
              size: 12),
        );
      },
    );
  }
}
