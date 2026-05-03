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
  static List<Lecture> getLecturesForDate(DateTime date) {
    int weekday = date.weekday;

    List<TimetableEntry> dayTemplate = timetableBox.values
        .where((entry) => entry.dayOfWeek == weekday)
        .toList();

    List<Lecture> results = [];

    for (var entry in dayTemplate) {
      String uid =
          "${DateFormat('yyyy-MM-dd').format(date)}_${entry.subjectId}_${entry.startHour}${entry.startMinute}";
      Lecture? savedLecture = lectureBox.get(uid);

      if (savedLecture != null) {
        results.add(savedLecture);
      } else {
        results.add(Lecture(
          lectureUID: uid,
          subjectID: entry.subjectId,
          date: date,
          roomNo: entry.roomNo,
          status: "NONE", // Default status
        ));
      }
    }

    // Sort by time so they appear in order on the timeline
    results.sort((a, b) => a.date.compareTo(b.date));
    return results;
  }
}
