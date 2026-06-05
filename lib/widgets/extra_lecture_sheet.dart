import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:hive_flutter/hive_flutter.dart';
//  MODELS
import '../models/subject.dart';
//  SERVICES
import '../services/database_service.dart';
//------------------------------------------------------------------------------

class AddExtraLectureSheet extends StatefulWidget {
  final DateTime? initialDate;
  final dynamic subjectKey;

  const AddExtraLectureSheet({super.key, this.initialDate, this.subjectKey});

  @override
  State<AddExtraLectureSheet> createState() => _AddExtraLectureSheetState();
}

class _AddExtraLectureSheetState extends State<AddExtraLectureSheet> {
  late DateTime _selectedDate;
  TimeOfDay _selectedStartTime = const TimeOfDay(hour: 9, minute: 0);
  late TimeOfDay _selectedEndTime;
  bool _customEndTime = false;
  dynamic _selectedSubjectId;

  // Declared safely inside persistent State object memory space
  final TextEditingController _roomController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate ?? DateTime.now();
    _selectedEndTime = TimeOfDay(
      hour: _selectedStartTime.hour + 1,
      minute: _selectedStartTime.minute,
    );
    _selectedSubjectId = widget.subjectKey;
  }

  @override
  void dispose() {
    // Explicit clean up to eliminate underlying stream memory leaks
    _roomController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        top: 20,
        left: 20,
        right: 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Add Extra Lecture",
              style: TextStyle(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.bold,
                fontSize: 28,
              ),
            ),
            const SizedBox(height: 15),

            // 1. SUBJECT DROPDOWN
            ValueListenableBuilder(
              valueListenable: DatabaseService.subjectBox.listenable(),
              builder: (context, Box<Subject> box, _) {
                if (box.values.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      "No subjects found! Add them in settings first.",
                      style: TextStyle(
                        color: Colors.redAccent,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }

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
                            style:
                                TextStyle(color: theme.colorScheme.onSurface),
                          ),
                        ],
                      );
                    }).toList();
                  },
                  decoration: InputDecoration(
                    labelText: "Select Subject",
                    labelStyle: TextStyle(
                        color: colorScheme.onSurface.withOpacity(0.6)),
                    filled: true,
                    fillColor: colorScheme.surfaceContainerHighest,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  dropdownColor: colorScheme.surfaceContainerHigh,
                  items: box.values.map((Subject subject) {
                    return DropdownMenuItem<dynamic>(
                      value: subject.key,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
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
                  onChanged: (dynamic val) {
                    setState(() {
                      _selectedSubjectId = val;
                    });
                  },
                );
              },
            ),
            const SizedBox(height: 15),

            // 2. DATE PICKER ROW
            ListTile(
              leading: const Icon(Icons.calendar_month),
              title: const Text("Date"),
              subtitle: Text(DateFormat('yyyy-MM-dd').format(_selectedDate)),
              trailing: const Icon(Icons.edit, size: 20),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime.now().subtract(const Duration(days: 365)),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (picked != null) {
                  setState(() => _selectedDate = picked);
                }
              },
            ),

            // 3. START TIME PICKER ROW
            ListTile(
              leading: const Icon(Icons.access_time),
              title: const Text("Start Time"),
              subtitle: Text(_selectedStartTime.format(context)),
              trailing: const Icon(Icons.edit, size: 20),
              onTap: () async {
                final picked = await showTimePicker(
                  context: context,
                  initialTime: _selectedStartTime,
                );
                if (picked != null) {
                  setState(() {
                    _selectedStartTime = picked;
                    if (!_customEndTime) {
                      _selectedEndTime = TimeOfDay(
                        hour: picked.hour + 1,
                        minute: picked.minute,
                      );
                    }
                  });
                }
              },
            ),

            // 4. END TIME PICKER ROW
            ListTile(
              leading: const Icon(Icons.access_time),
              title: const Text("End Time"),
              subtitle: Text(_selectedEndTime.format(context)),
              trailing: const Icon(Icons.edit, size: 20),
              onTap: () async {
                final picked = await showTimePicker(
                  context: context,
                  initialTime: _selectedEndTime,
                );
                if (picked != null) {
                  setState(() {
                    _customEndTime = true;
                    _selectedEndTime = picked;
                  });
                }
              },
            ),

            // 5. ROOM TEXT FIELD
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: TextFormField(
                controller: _roomController,
                textCapitalization: TextCapitalization.none,
                style: TextStyle(color: theme.colorScheme.onSurface),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.room),
                  labelText: "Room No.",
                  hintText: "101, 205, A-15",
                  labelStyle: TextStyle(
                      color: theme.colorScheme.onSurface.withOpacity(0.6)),
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerHighest,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // 6. ACTION BUTTONS
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    if (_selectedSubjectId == null) return;

                    String roomText = _roomController.text.trim().isEmpty
                        ? 'Not Specified'
                        : _roomController.text.trim();

                    await DatabaseService.lectureInput(
                      _selectedSubjectId,
                      'semester', //TODO
                      DateTime(_selectedDate.year, _selectedDate.month,
                          _selectedDate.day),

                      _selectedStartTime.hour,

                      _selectedStartTime.minute,
                      _selectedEndTime.hour,
                      _selectedEndTime.minute,
                      'Not Marked',
                      roomText,
                      isExtraClass: true,
                    );

                    if (context.mounted) {
                      Navigator.pop(context,
                          true); // Return true to request parent list update
                    }
                  },
                  child: const Text("Save Lecture"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
