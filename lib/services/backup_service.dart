import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
// SERVICES
import '../services/database_service.dart';
// MODELS
import '../models/subject.dart';
import '../models/lecture.dart';
import '../models/timetable.dart';
import '../models/attendance.dart';
import '../models/semester.dart';
import '../models/special_day.dart';

//------------------------------------------------------------------------------

class BackupService {
  /// Exports all boxes to a JSON string and invokes the system Share sheet
  /// Exports database data.
  /// If [structureOnly] is true, it exports the entire calendar structure and extra classes,
  /// but resets all lecture statuses to 'Not Marked' and attendance metrics to 0.
  static Future<void> exportBackup({bool structureOnly = false}) async {
    try {
      final Map<String, dynamic> backupData = {
        'metadata': {
          'version': '0.1.2',
          'exportedAt': DateTime.now().toIso8601String(),
          'type': structureOnly ? 'clean_structure_template' : 'full_backup',
        },
        'semesters': DatabaseService.semesterBox.values
            .map((sem) => {
                  'id': sem.key,
                  'name': sem.name,
                  'startDate': DateFormat('yyyy-MM-dd').format(sem.startDate),
                  'endDate': DateFormat('yyyy-MM-dd').format(sem.endDate),
                  'isActive': sem.isActive,
                })
            .toList(),
        'subjects': DatabaseService.subjectBox.values
            .map((s) => {
                  'id': s.key,
                  'name': s.name,
                  'semesterID': s.semesterID,
                  'colorValue': s.colorValue,
                  'iconCodePoint': s.iconCodePoint,
                  'minAttend': s.minAttend,
                })
            .toList(),
        'timetable': DatabaseService.timetableBox.values
            .map((t) => {
                  'id': t.key,
                  'subjectID': t.subjectID,
                  'semesterID': t.semesterID,
                  'dayOfWeek': t.dayOfWeek,
                  'startHour': t.startHour,
                  'startMinute': t.startMinute,
                  'endHour': t.endHour,
                  'endMinute': t.endMinute,
                  'roomNo': t.roomNo,
                })
            .toList(),

        // 1. CONDITIONAL LECTURE SANITIZATION
        'lectures': DatabaseService.lectureBox.values
            .map((l) => {
                  'lectureUID': l.lectureUID,
                  'subjectID': l.subjectID,
                  'semesterID': l.semesterID,
                  'date': DateFormat('yyyy-MM-dd').format(l.date),
                  'startHour': l.startHour,
                  'startMinute': l.startMinute,
                  'endHour': l.endHour,
                  'endMinute': l.endMinute,
                  'roomNo': l.roomNo,
                  // If structureOnly is true, force it to 'Not Marked' for the clean slate!
                  'status': structureOnly ? 'Not Marked' : l.status,
                  'isExtraClass': l.isExtraClass,
                })
            .toList(),

        // 2. CONDITIONAL COUNTER RESET
        'attendance': DatabaseService.attendanceBox.values
            .map((a) => {
                  'subjectID': a.subjectID,
                  'monthKey': a.monthKey,
                  // If structureOnly is true, reset historical counts to 0
                  'presentCount': structureOnly ? 0 : a.presentCount,
                  'totalCount': structureOnly ? 0 : a.totalCount,
                })
            .toList(),

        // 3. HOLIDAYS / LEAVES
        // We keep these even in structure-only mode so the calendar off-days remain intact for classmates!
        'specialDays': DatabaseService.specialDayBox.values
            .map((sd) => {
                  'date': DateFormat('yyyy-MM-dd').format(sd.date),
                  'reason': sd.reason,
                  'isLeave': sd.isLeave,
                  'groupID': sd.groupID,
                })
            .toList(),
      };

      final String jsonString = jsonEncode(backupData);

      final String fileNamePrefix =
          structureOnly ? 'attendy_clean_structure' : 'attendy_full_backup';
      final String fileTimestamp =
          DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());

      final XFile file = XFile.fromData(
        utf8.encode(jsonString),
        mimeType: 'application/json',
        name: '${fileNamePrefix}_$fileTimestamp.json',
      );

      final String shareText = structureOnly
          ? 'My Clean Attendance Structure Template'
          : 'My Attendy Application Full Backup';

      await Share.shareXFiles([file], text: shareText);
    } catch (e) {
      throw Exception('Failed to generate export file: $e');
    }
  }

  /// Lets the user pick a backup JSON file and restores it directly to Hive boxes
  static Future<bool> importBackup() async {
    try {
      FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null) return false;

      String jsonContent;
      if (kIsWeb || result.files.single.path == null) {
        if (result.files.single.bytes == null) return false;
        jsonContent = utf8.decode(result.files.single.bytes!);
      } else {
        final file = File(result.files.single.path!);
        jsonContent = await file.readAsString();
      }

      final Map<String, dynamic> backupData = jsonDecode(jsonContent);

      // Robust layout verification
      if (!backupData.containsKey('subjects') ||
          !backupData.containsKey('lectures')) {
        throw Exception('Invalid backup structure signature.');
      }

      // 1. Wipe everything synchronously to prepare fresh tracking environment
      await DatabaseService.semesterBox.clear();
      await DatabaseService.subjectBox.clear();
      await DatabaseService.lectureBox.clear();
      await DatabaseService.timetableBox.clear();
      await DatabaseService.attendanceBox.clear();
      await DatabaseService.specialDayBox.clear();

      // 2. Restore Semesters
      if (backupData.containsKey('semesters')) {
        for (var sem in backupData['semesters']) {
          final semester = Semester(
            name: sem['name'],
            startDate: DateFormat('yyyy-MM-dd').parse(sem['startDate']),
            endDate: DateFormat('yyyy-MM-dd').parse(sem['endDate']),
            isActive: sem['isActive'] ?? false,
          );
          await DatabaseService.semesterBox.put(sem['id'], semester);
        }
      }

      // 3. Restore Subjects
      for (var s in backupData['subjects']) {
        final subject = Subject(
          name: s['name'],
          semesterID: s['semesterID'],
          colorValue: s['colorValue'],
          iconCodePoint: s['iconCodePoint'],
          minAttend: (s['minAttend'] ?? 75.0).toDouble(),
        );
        await DatabaseService.subjectBox.put(s['id'], subject);
      }

      // 4. Restore Lectures
      for (var l in backupData['lectures']) {
        final lecture = Lecture(
          lectureUID: l['lectureUID'],
          subjectID: l['subjectID'],
          semesterID: l['semesterID'],
          date: DateFormat('yyyy-MM-dd').parse(l['date']),
          startHour: l['startHour'],
          startMinute: l['startMinute'],
          endHour: l['endHour'],
          endMinute: l['endMinute'],
          roomNo: l['roomNo'] ?? '',
          status: l['status'],
          isExtraClass: l['isExtraClass'] ?? false,
        );
        await DatabaseService.lectureBox.put(l['lectureUID'], lecture);
      }

      // 5. Restore Timetable Rows Safely
      for (var t in backupData['timetable']) {
        final entry = TimetableEntry(
          subjectID: t['subjectID'],
          semesterID: t['semesterID'],
          dayOfWeek: t['dayOfWeek'],
          startHour: t['startHour'],
          startMinute: t['startMinute'],
          endHour: t['endHour'],
          endMinute: t['endMinute'],
          roomNo: t['roomNo'] ?? '',
        );
        await DatabaseService.timetableBox.put(t['id'], entry);
      }

      // 6. Restore Attendance Counters Cache
      for (var a in backupData['attendance']) {
        final count = AttendanceCount(
          subjectID: a['subjectID'],
          monthKey: a['monthKey'],
          presentCount: a['presentCount'],
          totalCount: a['totalCount'],
        );
        final String uid = "${a['subjectID']}_${a['monthKey']}";
        await DatabaseService.attendanceBox.put(uid, count);
      }

      // 7. Restore Leaves and Special Days Track
      if (backupData.containsKey('specialDays')) {
        for (var sd in backupData['specialDays']) {
          final dayRecord = SpecialDay(
            date: DateFormat('yyyy-MM-dd').parse(sd['date']),
            reason: sd['reason'] ?? '',
            isLeave: sd['isLeave'] ?? true,
            groupID: sd['groupID'] ?? '',
          );
          final String stringKey = sd['date'];
          await DatabaseService.specialDayBox.put(stringKey, dayRecord);
        }
      }

      return true;
    } catch (e) {
      debugPrint('Error importing data structure: $e');
      throw Exception('Error importing data structure: $e');
    }
  }
}
