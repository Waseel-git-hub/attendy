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
            status: status,
            isExtraClass: isExtraClass));
  }

  /// Bulk marks all 'Not Marked' lectures for a specific date as 'Present'
  static Future<void> markAllLecturesForDay({
    required DateTime date,
    required String targetStatus,
  }) async {
    // 1. Fetch all lectures from the database box
    final allLectures = lectureBox.values.toList();

    // 2. Filter for lectures that happen on the exact same calendar day and are currently 'Not Marked'
    final targets = allLectures.where((lecture) {
      final bool isSameDay = lecture.date.year == date.year &&
          lecture.date.month == date.month &&
          lecture.date.day == date.day;
      return isSameDay;
    }).toList();

    // 3. Sequential update execution to keep cached counters accurate
    for (var lecture in targets) {
      await updateAttendance(lecture: lecture, newStatus: targetStatus);
    }
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
          "${dateString}_${entry.subjectID}_${entry.startHour}${entry.startMinute}";

      if (!lectureBox.containsKey(uid)) {
        lectureInput(entry.subjectID, date, entry.startHour, entry.startMinute,
            entry.endHour, entry.endMinute, 'Not Marked', entry.roomNo);
      }
    }
  }

  static List<Lecture> getLectures({
    dynamic subjectID,
    DateTime? specificDate,
    DateTime? filterMonth,
    String statusFilter = "All",
    bool oldestFirst = false,
  }) {
    // All lectures
    Iterable<Lecture> query = lectureBox.values;

    // Subject ID
    if (subjectID != null) {
      query =
          query.where((l) => l.subjectID.toString() == subjectID.toString());
    }

    // Exact Date
    if (specificDate != null) {
      final targetDateStr = DateFormat('yyyy-MM-dd').format(specificDate);
      query = query.where(
          (l) => DateFormat('yyyy-MM-dd').format(l.date) == targetDateStr);
    }

    // Month
    if (filterMonth != null) {
      query = query.where((l) =>
          l.date.year == filterMonth.year && l.date.month == filterMonth.month);
    }

    // Attendance Status
    if (statusFilter != "All") {
      query = query
          .where((l) => l.status.toLowerCase() == statusFilter.toLowerCase());
    }
    List<Lecture> lectures = query.toList();

    lectures.sort((a, b) {
      int dateCompare =
          oldestFirst ? a.date.compareTo(b.date) : b.date.compareTo(a.date);
      if (dateCompare != 0) return dateCompare;
      int timeA = (a.startHour * 60) + a.startMinute;
      int timeB = (b.startHour * 60) + b.startMinute;

      return timeA.compareTo(timeB);
    });
    return lectures;
  }

//-------------------TIMETABLE------------------------

  static Future<void> deleteTimetableEntry(TimetableEntry entry) async {
    if (!entry.isInBox) return;

    // 1. Fetch upcoming unmarked lecture copies corresponding to this timetable structure
    final DateTime todayStart =
        DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);

    final lecturesToRemove = lectureBox.values.where((lecture) {
      return lecture.subjectID == entry.subjectID &&
          lecture.startHour == entry.startHour &&
          lecture.startMinute == entry.startMinute &&
          lecture.status == 'Not Marked' &&
          lecture.date.compareTo(todayStart) >= 0;
    }).toList();

    // 2. Clear out those matching future lecture records
    for (var lecture in lecturesToRemove) {
      await lecture.delete();
    }

    // 3. Delete the root template block from the timetable box
    await entry.delete();
  }

// Check if Lecture already exists
  static bool _checkCollision({
    required int day,
    required int start,
    required int end,
    dynamic hiveID,
  }) {
    return timetableBox.values.any((existing) {
      // Safely skips comparison if we are editing this exact entry
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

    if (_checkCollision(
      day: entry.dayOfWeek,
      start: newStart,
      end: newEnd,
      hiveID: hiveKey,
    )) {
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
