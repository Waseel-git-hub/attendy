import 'package:Attendy/screens/subject/add_subject_screen.dart';
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

  final bool subjectAvailable = DatabaseService.subjectBox.isNotEmpty;
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
    _roomController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 30,
        top: 20,
        left: 20,
        right: 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 1. SUBJECT DROPDOWN
            ValueListenableBuilder(
              valueListenable: DatabaseService.subjectBox.listenable(),
              builder: (context, Box<Subject> box, _) {
                //TODO
                if (box.values.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      //TODO
                      "No Subjects found!\nAdd Subject First",
                      textAlign: TextAlign.center,

                      style: TextStyle(
                        color: Color(0xFFEF4444),
                        fontSize: 24,
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
                            size: 24,
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
                    labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
                    filled: true,
                    fillColor: colorScheme.surfaceContainerLowest,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  dropdownColor: colorScheme.surfaceContainerLowest,
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
                            style: const TextStyle(fontSize: 14),
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
            const SizedBox(height: 10),
            if (subjectAvailable) ...[
              // 2. ROOM TEXT FIELD
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
                    fillColor: theme.colorScheme.surfaceContainerLowest,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),

              // 3. DATE PICKER ROW
              ListTile(
                title: const Text("Date"),
                subtitle:
                    Text(DateFormat('dd MMMM yyyy').format(_selectedDate)),
                leading: const Icon(Icons.calendar_month),
                trailing: const Icon(Icons.edit, size: 20),
                iconColor: colorScheme.onSurface,
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate:
                        DateTime.now().subtract(const Duration(days: 365)),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) {
                    setState(() => _selectedDate = picked);
                  }
                },
              ),

              // 4. START TIME PICKER ROW
              ListTile(
                leading: const Icon(Icons.access_time),
                title: const Text("Start Time"),
                subtitle: Text(_selectedStartTime.format(context)),
                trailing: const Icon(Icons.edit, size: 20),
                iconColor: colorScheme.onSurface,
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

              // 5. END TIME PICKER ROW
              ListTile(
                leading: const Icon(Icons.access_time),
                title: const Text("End Time"),
                subtitle: Text(_selectedEndTime.format(context)),
                trailing: const Icon(Icons.edit, size: 20),
                iconColor: colorScheme.onSurface,
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
            ],

            const SizedBox(height: 10),

            // 6. ACTION BUTTONS
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                const SizedBox(width: 64),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    if (!subjectAvailable) {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => AddSubjectScreen()));
                    }
                    if (_selectedSubjectId == null) return;

                    String roomText = _roomController.text.trim().isEmpty
                        ? 'Not Specified'
                        : _roomController.text.trim();

                    await DatabaseService.lectureInput(
                      _selectedSubjectId,
                      DatabaseService.getActiveSemesterId(),
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
                      Navigator.pop(context, true);
                    }
                  },
                  child:
                      Text((subjectAvailable) ? "Save Lecture" : 'Add Subject'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
