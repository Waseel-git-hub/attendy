import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
//  MODELS
import '../models/timetable.dart';
import '../models/subject.dart';
//  SCREENS
//  SERVICES
import '../services/database_service.dart';
//  WIDGETS
//------------------------------------------------------------------------------

class AddTimetableScreen extends StatefulWidget {
  final int? initialDay;
  const AddTimetableScreen({super.key, this.initialDay});

  @override
  State<AddTimetableScreen> createState() => _AddTimetableScreenState();
}

class _AddTimetableScreenState extends State<AddTimetableScreen> {
  final _formKey = GlobalKey<FormState>();

  dynamic _selectedSubjectId;
  late int _selectedDay;
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 10, minute: 0);
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
    _selectedDay =
        widget.initialDay ?? 1; // Use passed day or default to Monday
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F12), // Match deep dark theme
      appBar: AppBar(
        title: const Text("Add Class",
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20.0),
          children: [
            // 1. Subject Dropdown
            const Text("Subject",
                style: TextStyle(color: Colors.white70, fontSize: 14)),
            const SizedBox(height: 8),
            ValueListenableBuilder(
              valueListenable: DatabaseService.subjectBox.listenable(),
              builder: (context, Box<Subject> box, _) {
                return DropdownButtonFormField<dynamic>(
                  value: _selectedSubjectId,
                  dropdownColor: const Color(0xFF1C1C23),
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration(),
                  items: box.values.map((entry) {
                    return DropdownMenuItem(
                      value: entry.key,
                      child: Text(entry.name),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedSubjectId = val),
                  validator: (val) =>
                      val == null ? "Please select a subject" : null,
                );
              },
            ),
            const SizedBox(height: 20),

            // 2. Day Dropdown
            const Text("Day of the Week",
                style: TextStyle(color: Colors.white70, fontSize: 14)),
            const SizedBox(height: 8),
            DropdownButtonFormField<int>(
              value: _selectedDay,
              dropdownColor: const Color(0xFF1C1C23),
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration(),
              items: List.generate(7, (index) {
                return DropdownMenuItem(
                  value: index + 1,
                  child: Text(_weekdays[index]),
                );
              }),
              onChanged: (val) => setState(() => _selectedDay = val ?? 1),
            ),
            const SizedBox(height: 20),

            // 3. Time Pickers (Start and End)
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Start Time",
                          style:
                              TextStyle(color: Colors.white70, fontSize: 14)),
                      const SizedBox(height: 8),
                      _buildTimeTile(_startTime, true),
                    ],
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("End Time",
                          style:
                              TextStyle(color: Colors.white70, fontSize: 14)),
                      const SizedBox(height: 8),
                      _buildTimeTile(_endTime, false),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 4. Room No
            const Text("Room Number",
                style: TextStyle(color: Colors.white70, fontSize: 14)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _roomController,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration(hint: "e.g. A-302"),
              validator: (val) => val!.isEmpty ? "Enter a room number" : null,
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

  // Helper for consistent UI fields
  InputDecoration _inputDecoration({String? hint}) {
    return InputDecoration(
      filled: true,
      fillColor: const Color(0xFF1C1C23),
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white30, fontSize: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.05)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.05)),
      ),
    );
  }

  Widget _buildTimeTile(TimeOfDay time, bool isStart) {
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
            } else {
              _endTime = picked;
            }
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C23),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(time.format(context),
                style: const TextStyle(color: Colors.white, fontSize: 15)),
            const Icon(Icons.access_time_rounded,
                color: Colors.white38, size: 18),
          ],
        ),
      ),
    );
  }

  void _saveTimetableEntry() async {
    if (!_formKey.currentState!.validate()) return;

    // Basic logic validation: End time must be after start time
    double startDouble = _startTime.hour + _startTime.minute / 60.0;
    double endDouble = _endTime.hour + _endTime.minute / 60.0;

    if (endDouble <= startDouble) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("End time must be after start time.")),
      );
      return;
    }

    // Create entry
    final newEntry = TimetableEntry(
      subjectId: _selectedSubjectId,
      dayOfWeek: _selectedDay,
      startHour: _startTime.hour,
      startMinute: _startTime.minute,
      endHour: _endTime.hour,
      endMinute: _endTime.minute,
      roomNo: _roomController.text.trim(),
    );

    // Save to Hive
    await DatabaseService.timetableBox.add(newEntry);

    // Go back
    Navigator.pop(context);
  }
}
