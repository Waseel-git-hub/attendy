import 'dart:async';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
//  MODELS
import '../models/attendance.dart';
import '../models/lecture.dart';
import '../models/subject.dart';
import '../models/timetable.dart';
//------------------------------------------------------------------------------

class DatabaseService {
  static late Box<Subject> subjectBox;
  static late Box<Lecture> lectureBox;
  static late Box<TimetableEntry> timetableBox;
  static late Box<AttendanceCount> attendanceBox;

  static Future<void> init() async {
    await Hive.initFlutter();

    // Register Adapters
    Hive.registerAdapter(SubjectAdapter());
    Hive.registerAdapter(LectureAdapter());
    Hive.registerAdapter(TimetableEntryAdapter());
    Hive.registerAdapter(AttendanceAdapter());

    // Open Boxes
    subjectBox = await Hive.openBox<Subject>('subjects');
    lectureBox = await Hive.openBox<Lecture>('lectures');
    timetableBox = await Hive.openBox<TimetableEntry>('timetable');
    attendanceBox = await Hive.openBox<AttendanceCount>('attendanceBox');
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

  static Future<void> lectureInput(
      dynamic subjectID,
      DateTime date,
      int startHour,
      int startMinute,
      int endHour,
      int endMinute,
      String status,
      String roomNo,
      {bool isExtraClass = false,
      String lectureUID = ''}) async {
    if (lectureUID == '')
      lectureUID =
          "${DateFormat('yyyy-MM-dd').format(date)}_${subjectID}_${startHour}${startMinute}";

    await lectureBox.put(
        lectureUID,
        Lecture(
            lectureUID: lectureUID,
            subjectID: subjectID,
            date: date,
            startHour: startHour,
            startMinute: startMinute,
            endHour: endHour,
            endMinute: endMinute,
            roomNo: roomNo,
            status: "Not Marked",
            isExtraClass: isExtraClass));
  }

  //Generate Lecture From Timetable
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
        lectureInput(entry.subjectId, date, entry.startHour, entry.startMinute,
            entry.endHour, entry.endMinute, 'Not Marked', entry.roomNo);
      }
    }
  }

  static List<Lecture> getLectures({
    dynamic subjectID,
    DateTime? specificDate,
    DateTime? filterMonth,
    String statusFilter = "All",
    bool latestFirst = false,
  }) {
    // 1. All lectures
    Iterable<Lecture> query = lectureBox.values;

    // 2. Filter by Subject ID
    if (subjectID != null) {
      query =
          query.where((l) => l.subjectID.toString() == subjectID.toString());
    }

    // 3. Filter by Exact Date
    if (specificDate != null) {
      final targetDateStr = DateFormat('yyyy-MM-dd').format(specificDate);
      query = query.where(
          (l) => DateFormat('yyyy-MM-dd').format(l.date) == targetDateStr);
    }

    // 4. Filter by Month/Year
    if (filterMonth != null && specificDate == null) {
      final targetYear = filterMonth.year;
      final targetMonthValue = filterMonth.month;
      query = query.where(
          (l) => l.date.year == targetYear && l.date.month == targetMonthValue);
    }

    // 5. Filter by Attendance Status
    if (statusFilter != "All") {
      query = query
          .where((l) => l.status.toLowerCase() == statusFilter.toLowerCase());
    }
    List<Lecture> results = query.toList();

    if (latestFirst) {
      results.sort((a, b) => (a.startHour * 60 + a.startMinute)
          .compareTo(b.startHour * 60 + b.startMinute));
    } else {
      results.sort((a, b) => (b.date).compareTo(a.date));
    }
    return results;
  }

//-------------------TIMETABLE------------------------

  // Check if Lecture already exists
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

  //
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

//-------------------ATTENDANCE------------------------

  static AttendanceCount getAttendance(dynamic subjectID, String monthKey) {
    final String uid = generateAttendanceUID(subjectID, monthID: monthKey);

    return attendanceBox.get(uid) ??
        AttendanceCount(
          subjectID: subjectID,
          monthKey: monthKey,
          presentCount: 0,
          totalCount: 0,
        );
  }

  static String generateAttendanceUID(dynamic subjectID,
      {String monthID = 'Overall'}) {
    return "${subjectID}_$monthID";
  }

  static Future<void> clearAttendance(Lecture lecture) async {
    final record = [
      getAttendance(
          lecture.subjectID, DateFormat('yyyy-MM').format(lecture.date)),
      getAttendance(lecture.subjectID, 'Overall')
    ];
    for (var stats in record) {
      if (lecture.status == "Present") {
        stats.presentCount--;
        stats.totalCount--;
      } else if (lecture.status == "Absent") {
        stats.totalCount--;
      }
      final String uid = "${stats.subjectID}_${stats.monthKey}";
      await attendanceBox.put(uid, stats);
    }
    lecture.status = 'NONE';
    await lecture.save();
  }

  static Future<void> updateAttendance({
    required Lecture lecture,
    required String newStatus,
  }) async {
    if (lecture.status != 'Not Marked') await clearAttendance(lecture);

    // 2. Set and Save the new status immediately
    lecture.status = newStatus;
    await lecture.save();

    if (newStatus == 'Not Marked' || newStatus == 'Cancelled') {
      return;
    }

    final record = [
      getAttendance(
          lecture.subjectID, DateFormat('yyyy-MM').format(lecture.date)),
      getAttendance(lecture.subjectID, 'Overall')
    ];
    for (var stats in record) {
      if (newStatus == "Present") {
        stats.presentCount++;
        stats.totalCount++;
      } else if (newStatus == "Absent") {
        stats.totalCount++;
      }
      final String uid = "${stats.subjectID}_${stats.monthKey}";
      await attendanceBox.put(uid, stats);
    }
  }

  static int requiredLecture(double minAttend, int total, int present) {
    if (total == 0) return 0;

    double target = minAttend / 100; // Convert 75 to 0.75
    double current = present / total;

    if (current < target) {
      // Formula: (Target * Total - Present) / (1 - Target)
      return ((target * total - present) / (1 - target)).ceil();
    } else {
      // Formula: (Present - Target * Total) / Target
      int canSkip = ((present - target * total) / target).floor();
      return -canSkip;
    }
  }
}
