import 'dart:async';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
//  MODELS
import '../models/attendance.dart';
import '../models/lecture.dart';
import '../models/subject.dart';
import '../models/timetable.dart';
import '../models/semester.dart';
import '../models/special_day.dart';
import '../models/draft.dart';
//------------------------------------------------------------------------------

class DatabaseService {
  static late Box<Subject> subjectBox;
  static late Box<Lecture> lectureBox;
  static late Box<TimetableEntry> timetableBox;
  static late Box<AttendanceCount> attendanceBox;
  static late Box<Semester> semesterBox;
  static late Box<SpecialDay> specialDayBox;
  static late Box settingsBox;

  static Future<void> init() async {
    await Hive.initFlutter();

    // Register Adapters
    Hive.registerAdapter(SubjectAdapter());
    Hive.registerAdapter(LectureAdapter());
    Hive.registerAdapter(TimetableEntryAdapter());
    Hive.registerAdapter(AttendanceCountAdapter());
    Hive.registerAdapter(SemesterAdapter());
    Hive.registerAdapter(SpecialDayAdapter());

    // Open Boxes
    settingsBox = await Hive.openBox('settingsBox');
    subjectBox = await Hive.openBox<Subject>('subjects');
    lectureBox = await Hive.openBox<Lecture>('lectures');
    timetableBox = await Hive.openBox<TimetableEntry>('timetable');
    attendanceBox = await Hive.openBox<AttendanceCount>('attendanceBox');
    semesterBox = await Hive.openBox<Semester>('semesters');
    specialDayBox = await Hive.openBox<SpecialDay>('specialDay');
  }

//
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

  // Hive Key --> Subject
  static Subject? getSubjectById(dynamic id) {
    if (id == null) return null;
    return subjectBox.get(id);
  }

  // Delete Subject + {Timetable + Lectures + Attend}
  static Future<void> deleteSubject(dynamic subjectId) async {
    final List<dynamic> timetableKeys = [];
    final List<dynamic> lectureKeys = [];
    final List<dynamic> attendanceKeys = [];

    for (var key in timetableBox.keys) {
      final entry = timetableBox.get(key);
      if (entry != null && entry.subjectID == subjectId) {
        timetableKeys.add(key);
      }
    }
    if (timetableKeys.isNotEmpty) await timetableBox.deleteAll(timetableKeys);

    for (var key in lectureBox.keys) {
      final lecture = lectureBox.get(key);
      if (lecture != null && lecture.subjectID == subjectId) {
        lectureKeys.add(key);
      }
    }
    if (lectureKeys.isNotEmpty) await lectureBox.deleteAll(lectureKeys);

    for (var key in attendanceBox.keys) {
      final attendance = attendanceBox.get(key);
      if (attendance!.subjectID == subjectId) {
        attendanceKeys.add(key);
      }
    }
    if (attendanceKeys.isNotEmpty) {
      await attendanceBox.deleteAll(attendanceKeys);
    }

    await subjectBox.delete(subjectId);
  }

//-------------------LECTIURES------------------------

  // Lecture --> Hive or Lecture
  static Future<Lecture?> lectureInput(
      dynamic subjectID,
      dynamic semesterID,
      DateTime date,
      int startHour,
      int startMinute,
      int endHour,
      int endMinute,
      String status,
      String roomNo,
      {bool isExtraClass = false,
      String lectureUID = '',
      bool save = true}) async {
    if (lectureUID == '') {
      lectureUID =
          "${DateFormat('yyyy-MM-dd').format(date)}_${subjectID}_$startHour$startMinute";
    }

    final newLecture = Lecture(
        lectureUID: lectureUID,
        subjectID: subjectID,
        semesterID: semesterID,
        date: date,
        startHour: startHour,
        startMinute: startMinute,
        endHour: endHour,
        endMinute: endMinute,
        roomNo: roomNo,
        status: status,
        isExtraClass: isExtraClass);

    // Normal app flow saves immediately
    if (save) {
      await lectureBox.put(lectureUID, newLecture);
      return null;
    }
    return newLecture;
  }

  // Bulk mark
  static Future<void> markAllLecturesForDate({
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

  // Shared core generator engine
  static Future<Map<String, Lecture>> _buildLectureBatch({
    required DateTime start,
    required DateTime end,
    required List<TimetableEntry> templates,
  }) async {
    final Set<String> holidays = getHolidayDatesSet(true);
    final Map<String, Lecture> batch = {};
    DateTime processingDate = DateTime(start.year, start.month, start.day);
    final DateTime stopDate = DateTime(end.year, end.month, end.day);

    while (!processingDate.isAfter(stopDate)) {
      int weekday = processingDate.weekday;

      String dateString = DateFormat('yyyy-MM-dd').format(processingDate);
      if (holidays.contains(dateString)) continue;

      final dayTemplates = templates.where((e) => e.dayOfWeek == weekday);

      for (var entry in dayTemplates) {
        String uid =
            "${dateString}_${entry.subjectID}_${entry.startHour}${entry.startMinute}";

        if (!lectureBox.containsKey(uid) && !batch.containsKey(uid)) {
          final Lecture? lecture = await lectureInput(
            entry.subjectID,
            entry.semesterID,
            processingDate,
            entry.startHour,
            entry.startMinute,
            entry.endHour,
            entry.endMinute,
            'Not Marked',
            entry.roomNo,
            lectureUID: uid,
            save: false,
          );
          if (lecture != null) batch[uid] = lecture;
        }
      }
      processingDate = processingDate.add(const Duration(days: 1));
    }
    return batch;
  }

  // TimeTable --> Lecture
  static Future<void> generateAllLecturesForSemester({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final templates = timetableBox.values.toList();
    final batchData = await _buildLectureBatch(
        start: startDate, end: endDate, templates: templates);

    if (batchData.isNotEmpty) await lectureBox.putAll(batchData);
  }

// 2. Mid-semester synchronization patch
  static Future<void> syncMidSemesterTimetableUpdates({
    required List<TimetableEntry> newTimetableTemplates,
    required DateTime semesterEndDate,
  }) async {
    final todayStart =
        DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);

    // Clean future unmarked history
    final keysToRemove = lectureBox.keys.where((key) {
      final lecture = lectureBox.get(key);
      return lecture != null &&
          !lecture.date.isBefore(todayStart) &&
          lecture.status == 'Not Marked';
    }).toList();

    if (keysToRemove.isNotEmpty) await lectureBox.deleteAll(keysToRemove);

    // Generate new timeline from today onward
    final batchData = await _buildLectureBatch(
        start: todayStart,
        end: semesterEndDate,
        templates: newTimetableTemplates);

    if (batchData.isNotEmpty) await lectureBox.putAll(batchData);
  }

  static Future<void> deleteLecture(Lecture lecture) async {
    if (lecture.status == 'Present' || lecture.status == 'Absent') {
      await clearAttendance(lecture);
    }
    if (lecture.isInBox) {
      //TODO : Refactor
      await lecture.delete();
    }
  }

//
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

//
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
    lecture.status = 'Not Marked';
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

//---------------------SEMESTER--------------------------

  static bool hasAnySemesterHistory() {
    return semesterBox.isNotEmpty;
  }

  static bool hasActiveSemester() {
    if (semesterBox.isEmpty) return false;

    final currentSemester = semesterBox.values.first;
    final DateTime today = DateTime.now();
    final DateTime todayStart = DateTime(today.year, today.month, today.day);
    final DateTime end = DateTime(
      currentSemester.endDate.year,
      currentSemester.endDate.month,
      currentSemester.endDate.day,
    );

    return !todayStart.isAfter(end);
  }

  // Helper to fetch the currently active semester ID
  static dynamic getActiveSemesterId() {
    try {
      final activeSem =
          semesterBox.values.firstWhere((sem) => sem.isActive == true);
      return activeSem.key; // Hive auto-increment int or dynamic key
    } catch (_) {
      return null;
    }
  }

  static Future<void> commitInitialSetup(SetupDraft draft) async {
    // 2. Mark any existing historical semesters as inactive
    for (var sem in semesterBox.values) {
      if (sem.isActive) {
        sem.isActive = false;
        await sem.save();
      }
    }

    // 3. Create and Save the real Semester object
    final newSemester = Semester(
      name: draft.semesterName,
      startDate: draft.startDate!,
      endDate: draft.endDate!,
      isActive: true,
    );
    // Adding to the box generates the auto-increment `key`
    final dynamic semesterKey = await semesterBox.add(newSemester);

    // 4. Map SubjectDraft items to persistent Subject models
    // We maintain a map linking: temporaryId string -> newly generated Hive subject int/dynamic key
    final Map<String, dynamic> subjectKeyMap = {};

    for (var subjectDraft in draft.subjects) {
      final realSubject = Subject(
        name: subjectDraft.name,
        semesterID: semesterKey,
        iconCodePoint: subjectDraft.iconCodePoint,
        colorValue: subjectDraft.colorValue,
        minAttend: subjectDraft.minAttend,
      );

      final dynamic subjectKey = await subjectBox.add(realSubject);
      subjectKeyMap[subjectDraft.temporaryId] = subjectKey;

      // Initialize an "Overall" attendance summary track counter for each subject
      final overallCounter = AttendanceCount(
        subjectID: subjectKey,
        monthKey: 'Overall',
        presentCount: 0,
        totalCount: 0,
      );
      await attendanceBox.add(overallCounter);
    }

    // 5. Map TimetableEntryDraft items into real permanent Timetable template rows
    for (var slotDraft in draft.timetableSlots) {
      if (slotDraft.subjectTemporaryId == null) continue;

      // Look up what genuine Hive key corresponds to this entry's temporary ID
      final dynamic realSubjectKey =
          subjectKeyMap[slotDraft.subjectTemporaryId!];

      final realTimetableEntry = TimetableEntry(
        dayOfWeek: slotDraft.dayOfWeek,
        startHour: slotDraft.startHour,
        startMinute: slotDraft.startMinute,
        endHour: slotDraft.endHour,
        endMinute: slotDraft.endMinute,
        roomNo: slotDraft.roomNo,
        subjectID: realSubjectKey,
        semesterID: semesterKey,
      );
      await timetableBox.add(realTimetableEntry);
    }

    // 6. AUTO-GENERATE LECTURE SKELETON HISTORY TRACKS
    // Loop step by step through every single date spanning from semester start to end
    DateTime currentDate = _stripTime(draft.startDate!);
    final DateTime lastDate = _stripTime(draft.endDate!);

    final List<Lecture> autoGeneratedLectures = [];
    final Set<String> uniqueMonths = {};

    while (currentDate.isBefore(lastDate) ||
        currentDate.isAtSameMomentAs(lastDate)) {
      final int currentDayOfWeek = currentDate.weekday; // 1 = Mon, 7 = Sun

      // Find all schedule template slots matching this day of the week
      final matchingSlots = draft.timetableSlots
          .where((slot) => slot.dayOfWeek == currentDayOfWeek);

      for (var slot in matchingSlots) {
        if (slot.subjectTemporaryId == null) continue;

        final dynamic realSubjectKey = subjectKeyMap[slot.subjectTemporaryId!];
        final monthKey = DateFormat('yyyy-MM').format(currentDate);
        uniqueMonths.add(monthKey);

        // Generate a clean, structured composite UID unique to this exact instance loop
        final String lectureUID =
            "${realSubjectKey}_${DateFormat('yyyyMMdd').format(currentDate)}_${slot.startHour}:${slot.startMinute}";

        autoGeneratedLectures.add(
          Lecture(
            lectureUID: lectureUID,
            subjectID: realSubjectKey,
            semesterID: semesterKey,
            date: currentDate,
            startHour: slot.startHour,
            startMinute: slot.startMinute,
            endHour: slot.endHour,
            endMinute: slot.endMinute,
            status:
                "Not Marked", // Initially setup as pristine, waiting for student interaction
            roomNo: slot.roomNo,
            isExtraClass: false,
          ),
        );
      }

      // Progress loop counter forward by exactly 1 calendar day
      currentDate = currentDate.add(const Duration(days: 1));
    }

    // Bulk-add all the generated schedule slots into the lectures box safely
    if (autoGeneratedLectures.isNotEmpty) {
      await lectureBox.addAll(autoGeneratedLectures);
    }

    // 7. Initialize Monthly Attendance Cache Tracks
    // To ensure monthly charts load lightning-fast without running dynamic loops later
    for (final monthKey in uniqueMonths) {
      for (final realSubjectKey in subjectKeyMap.values) {
        final monthlyCounter = AttendanceCount(
          subjectID: realSubjectKey,
          monthKey: monthKey,
          presentCount: 0,
          totalCount: 0,
        );
        await attendanceBox.add(monthlyCounter);
      }
    }
  }

  // Clean utility to strip hour/minute noise away from tracking date markers
  static DateTime _stripTime(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

//------------------------------------------------------------

  static Future<SetupDraft> generateDraftFromProduction() async {
    final draft = SetupDraft();

    final List<Subject> productionSubjects = subjectBox.values.toList();
    final List<TimetableEntry> productionEntries = timetableBox.values.toList();

    // Subject --> SubjectDraft
    for (var prodSubject in productionSubjects) {
      draft.subjects.add(
        SubjectDraft(
          temporaryId: prodSubject.key,
          name: prodSubject.name,
          iconCodePoint: prodSubject.iconCodePoint,
          colorValue: prodSubject.colorValue,
          minAttend: prodSubject.minAttend,
        ),
      );
    }

    // Timetable entries --> TimetableEntryDrafts
    for (var entry in productionEntries) {
      draft.timetableSlots.add(
        TimetableEntryDraft.create(
          dayOfWeek: entry.dayOfWeek,
          startHour: entry.startHour,
          startMinute: entry.startMinute,
          endHour: entry.endHour,
          endMinute: entry.endMinute,
          roomNo: entry.roomNo,
          subjectTemporaryId: entry.subjectID,
        ),
      );
    }

    return draft;
  }

//================================================================

  static Future<void> addSpecialDayRange({
    required String reason,
    required bool isLeave,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    DateTime currentDay =
        DateTime(startDate.year, startDate.month, startDate.day);
    final DateTime normalizedEnd =
        DateTime(endDate.year, endDate.month, endDate.day);

    final String startKeyStr = DateFormat('yyyy-MM-dd').format(startDate);
    final String endKeyStr = DateFormat('yyyy-MM-dd').format(endDate);

    final int daysDiff = normalizedEnd.difference(currentDay).inDays;

    final String customGroupId = "${startKeyStr}_${endKeyStr}_$daysDiff";

    while (!currentDay.isAfter(normalizedEnd)) {
      final String stringKey = DateFormat('yyyy-MM-dd').format(currentDay);

      final dayRecord = SpecialDay(
        date: currentDay,
        reason: reason,
        isLeave: isLeave,
        groupID: customGroupId,
      );
      if (isLeave) {
        final lecturesOnThisDay = lectureBox.values.where((lecture) {
          return lecture.date.year == currentDay.year &&
              lecture.date.month == currentDay.month &&
              lecture.date.day == currentDay.day;
        }).toList();

        for (var lecture in lecturesOnThisDay) {
          await deleteLecture(lecture);
        }
      }
      await specialDayBox.put(stringKey, dayRecord);
      currentDay = currentDay.add(const Duration(days: 1));
    }
  }

  static Set<String> getHolidayDatesSet(bool onlyLeave) {
    Iterable<SpecialDay> query = specialDayBox.values;
    if (onlyLeave) {
      query = query.where((day) => day.isLeave);
    }
    return query
        .map((day) => DateFormat('yyyy-MM-dd').format(day.date))
        .toSet();
  }

  static SpecialDay? getSpecialDayDetails(DateTime selectedDate) {
    final String stringKey = DateFormat('yyyy-MM-dd').format(selectedDate);
    return specialDayBox
        .get(stringKey); // Instant lookup by exact Key map address
  }

  static Future<void> deleteSpecialDayRange(String groupId) async {
    if (groupId.isEmpty || !groupId.contains('_')) return;

    final segments = groupId.split('_');
    final DateTime startDate = DateFormat('yyyy-MM-dd').parse(segments[0]);
    final DateTime endDate = DateFormat('yyyy-MM-dd').parse(segments[1]);

    DateTime currentDay = startDate;
    while (!currentDay.isAfter(endDate)) {
      final String storageKey = DateFormat('yyyy-MM-dd').format(currentDay);
      await specialDayBox.delete(storageKey);
      currentDay = currentDay.add(const Duration(days: 1));
    }
    final templates = timetableBox.values.toList();

    // Re-builds the lecture skeletons for this date range since it's no longer a holiday
    final restoredBatch = await _buildLectureBatch(
      start: startDate,
      end: endDate,
      templates: templates,
    );

    if (restoredBatch.isNotEmpty) {
      await lectureBox.putAll(restoredBatch);
    }
  }
}
