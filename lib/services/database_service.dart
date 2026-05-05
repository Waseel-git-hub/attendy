import 'dart:async';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
//  MODELS
import '../models/subject.dart';
import '../models/lecture.dart';
import '../models/timetable.dart';
//------------------------------------------------------------------------------

class DatabaseService {
  static late Box<Subject> subjectBox;
  static late Box<Lecture> lectureBox;
  static late Box<TimetableEntry> timetableBox;

  static Future<void> init() async {
    await Hive.initFlutter();

    // Register Adapters
    Hive.registerAdapter(SubjectAdapter());
    Hive.registerAdapter(LectureAdapter());
    Hive.registerAdapter(TimetableEntryAdapter());

    // Open Boxes
    subjectBox = await Hive.openBox<Subject>('subjects');
    lectureBox = await Hive.openBox<Lecture>('lectures');
    timetableBox = await Hive.openBox<TimetableEntry>('timetable');
  }

//-------------------SUBJECT------------------------

  // Add or Update Subject
  static Future<void> saveSubject(Subject subject) async {
    if (subject.isInBox) {
      await subject.save();
    } else {
      // If it's new, we add it to the box
      await subjectBox.add(subject);
    }
  }

  // Get a specific subject by its ID (key)
  static Subject? getSubjectById(dynamic id) {
    if (id == null) return null;
    return subjectBox.get(id);
  }

  // Delete Subject and associated assignments
  static Future<void> deleteSubject(dynamic subjectId) async {
    await subjectBox.delete(subjectId); // delete subject
  }

//-------------------LECTIURES------------------------

  static Future<void> generateLecturesForDate(DateTime date) async {
    int weekday = date.weekday;
    String dateString = DateFormat('yyyy-MM-dd').format(date);

    // Get the templates for this day
    List<TimetableEntry> dayTemplate = timetableBox.values
        .where((entry) => entry.dayOfWeek == weekday)
        .toList();

    for (var entry in dayTemplate) {
      String uid =
          "${dateString}_${entry.subjectId}_${entry.startHour}${entry.startMinute}";

      if (!lectureBox.containsKey(uid)) {
        await lectureBox.put(
            uid,
            Lecture(
              lectureUID: uid,
              subjectID: entry.subjectId,
              date: date,
              startHour: entry.startHour,
              startMinute: entry.startMinute,
              endHour: entry.endHour,
              endMinute: entry.endMinute,
              roomNo: entry.roomNo,
              status: "NONE",
            ));
      }
    }
  }

  static List<Lecture> getLecturesForDate(DateTime date) {
    String dateString = DateFormat('yyyy-MM-dd').format(date);

    List<Lecture> results = lectureBox.values.where((lecture) {
      return DateFormat('yyyy-MM-dd').format(lecture.date) == dateString;
    }).toList();

    results.sort((a, b) => (a.startHour * 60 + a.startMinute)
        .compareTo(b.startHour * 60 + b.startMinute));

    return results;
  }

//-------------------TIMETABLE------------------------

  static bool _checkCollision(
      {required int day,
      required int start,
      required int end,
      dynamic hiveID}) {
    return timetableBox.values.any((existing) {
      if (hiveID != null && existing.key == hiveID) return false;
      if (existing.dayOfWeek != day) return false;

      int exStart = (existing.startHour * 60) + existing.startMinute;
      int exEnd = (existing.endHour * 60) + existing.endMinute;

      return start < exEnd && end > exStart;
    });
  }

  static Future<String?> saveTimetableEntry({
    required TimetableEntry entry,
    dynamic hiveKey,
  }) async {
    int newStart = (entry.startHour * 60) + entry.startMinute;
    int newEnd = (entry.endHour * 60) + entry.endMinute;

    if (_checkCollision(day: entry.dayOfWeek, start: newStart, end: newEnd)) {
      return "Time Clash: Slot already taken!";
    }
    try {
      if (hiveKey != null) {
        await timetableBox.put(hiveKey, entry);
      } else {
        await timetableBox.add(entry);
      }
      return null;
    } catch (e) {
      return "Database Error: Could not save.";
    }
  }
}
