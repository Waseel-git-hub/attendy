import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
//  MODELS
import '../../models/timetable.dart';
import '../../models/subject.dart';
//  SCREENS
//  SERVICES
import '../../services/database_service.dart';
//  WIDGETS
//------------------------------------------------------------------------------

class AddTimetableScreen extends StatefulWidget {
  final TimetableEntry? prevEntry;
  final int? initialDay;
  const AddTimetableScreen({super.key, this.initialDay, this.prevEntry});

  @override
  State<AddTimetableScreen> createState() => _AddTimetableScreenState();
}

class _AddTimetableScreenState extends State<AddTimetableScreen> {
  final _formKey = GlobalKey<FormState>();

  dynamic _selectedSubjectId;
  late int _selectedDay;
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  late TimeOfDay _endTime;
  bool _isEndTimeManual = false;
  final TextEditingController _roomController = TextEditingController();

  final List<String> _weekdays = [
    "Monday",
    "Tuesday",
    "Wednesday",
    "Thursday",
    "Friday",
    "Saturday",
    "Sunday"
  ];

  @override
  void initState() {
    super.initState();

    if (widget.prevEntry != null) {
      _selectedDay = widget.prevEntry!.dayOfWeek;
      // Fill with existing data
      _startTime = TimeOfDay(
          hour: widget.prevEntry!.startHour,
          minute: widget.prevEntry!.startMinute);
      _endTime = TimeOfDay(
          hour: widget.prevEntry!.endHour, minute: widget.prevEntry!.endMinute);
      _selectedSubjectId = widget.prevEntry!.subjectId;
      _roomController.text = widget.prevEntry!.roomNo;
      _isEndTimeManual = true;
    } else {
      _selectedDay = widget.initialDay ?? 1;
      _endTime = _defaultEnd(_startTime);
    }
  }

  TimeOfDay _defaultEnd(TimeOfDay start) {
    return TimeOfDay(hour: (start.hour + 1) % 24, minute: start.minute);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text("Add Class",
            style: TextStyle(
                color: colorScheme.onSurface, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20.0),
          children: [
            // 1. Subject Dropdown

            ValueListenableBuilder(
              valueListenable: DatabaseService.subjectBox.listenable(),
              builder: (context, Box<Subject> box, _) {
                return DropdownButtonFormField<dynamic>(
                  value: _selectedSubjectId,
                  selectedItemBuilder: (BuildContext context) {
                    return box.values.map((Subject subject) {
                      return Row(
                        children: [
                          Icon(
                            IconData(subject.iconCodePoint,
                                fontFamily: 'MaterialIcons'),
                            color: Color(subject.colorValue),
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            subject.name,
                            style: TextStyle(color: colorScheme.onSurface),
                          ),
                        ],
                      );
                    }).toList();
                  },

                  decoration: InputDecoration(
                    labelText: "Select Subject",
                    labelStyle: TextStyle(
                      color: colorScheme.onSurface.withOpacity(0.8),
                    ),
                    filled: true,
                    fillColor: colorScheme.surfaceContainerHighest,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  dropdownColor: colorScheme.surfaceContainerHigh,

                  // RICH DROPDOWN MENU LIST ITEMS
                  items: box.values.map((Subject subject) {
                    return DropdownMenuItem<dynamic>(
                      value: subject.key,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Renders the icon with its unique color inside the menu selector tray
                          Icon(
                            IconData(subject.iconCodePoint,
                                fontFamily: 'MaterialIcons'),
                            color: Color(subject.colorValue),
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            subject.name,
                            style: const TextStyle(fontSize: 15),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedSubjectId = val),
                  validator: (val) =>
                      val == null ? "Please select a subject" : null,
                );
              },
            ),
            const SizedBox(height: 25),

            // 2. Day Dropdown
            DropdownButtonFormField<int>(
              value: _selectedDay,
              dropdownColor: colorScheme.surfaceContainerHigh,
              style: TextStyle(color: colorScheme.onSurface, fontSize: 15.5),
              decoration: InputDecoration(
                labelText: "Select Day",
                labelStyle: TextStyle(
                  color: colorScheme.onSurface.withOpacity(0.8),
                ),
                filled: true,
                fillColor: colorScheme.surfaceContainerHighest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              items: List.generate(7, (index) {
                return DropdownMenuItem(
                  value: index + 1,
                  child: Text(_weekdays[index]),
                );
              }),
              onChanged: (val) => setState(() => _selectedDay = val ?? 1),
            ),
            const SizedBox(height: 10),

            // 3. Time Pickers (Start and End)
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Start Time",
                          style: TextStyle(
                              color: colorScheme.onSurface.withOpacity(0.8),
                              fontSize: 12)),
                      _buildTimeTile(_startTime, true),
                    ],
                  ),
                ),
                const SizedBox(width: 25),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("End Time",
                          style: TextStyle(
                              color: colorScheme.onSurface.withOpacity(0.8),
                              fontSize: 12)),
                      _buildTimeTile(_endTime, false),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 25),

            TextFormField(
              cursorColor: colorScheme.primary,
              controller: _roomController,
              style: TextStyle(color: colorScheme.onSurface),
              decoration: InputDecoration(
                fillColor: colorScheme.surfaceContainerHighest,
                labelText: "Enter Room Number",
                labelStyle: TextStyle(
                  color: colorScheme.onSurface.withOpacity(0.8),
                ),
                hintText: 'eg: 517, A-21',
              ),
            ),

            const SizedBox(height: 40),

            // 5. Submit Button
            ElevatedButton(
              onPressed: _saveTimetableEntry,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text("Save Entry",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeTile(TimeOfDay time, bool isStart) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return InkWell(
      onTap: () async {
        final TimeOfDay? picked = await showTimePicker(
          context: context,
          initialTime: time,
        );
        if (picked != null) {
          setState(() {
            if (isStart) {
              _startTime = picked;
              if (!_isEndTimeManual) {
                _endTime = TimeOfDay(
                  hour: (picked.hour + 1) % 24,
                  minute: picked.minute,
                );
              }
            } else {
              _endTime = picked;
              _isEndTimeManual = true;
            }
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colorScheme.onSurface.withOpacity(0.05)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(time.format(context),
                style: TextStyle(color: colorScheme.onSurface, fontSize: 15)),
            Icon(Icons.access_time_rounded,
                color: colorScheme.onSurface.withOpacity(0.6), size: 18),
          ],
        ),
      ),
    );
  }

  void _saveTimetableEntry() async {
    if (!_formKey.currentState!.validate()) return;

    double startDouble = _startTime.hour + _startTime.minute / 60.0;
    double endDouble = _endTime.hour + _endTime.minute / 60.0;

    if (endDouble <= startDouble) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("End time must be after start time.")),
      );
      return;
    }

    final newEntry = TimetableEntry(
      subjectId: _selectedSubjectId,
      dayOfWeek: _selectedDay,
      startHour: _startTime.hour,
      startMinute: _startTime.minute,
      endHour: _endTime.hour,
      endMinute: _endTime.minute,
      roomNo: _roomController.text.trim(),
    );
    final error = await DatabaseService.saveTimetableEntry(
      entry: newEntry,
    );

    if (error == null) {
      Navigator.pop(context);
    }
  }
}
