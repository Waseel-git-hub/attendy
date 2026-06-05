import 'dart:convert';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
//  SERVICES
import '../services/database_service.dart';
//  MODELS
import '../models/subject.dart';
import '../models/lecture.dart';
import '../models/timetable.dart';
import '../models/attendance.dart';
//------------------------------------------------------------------------------

class BackupService {
  /// Exports all boxes to a JSON string and invokes the system Share sheet
  static Future<void> exportBackup() async {
    try {
      final Map<String, dynamic> backupData = {
        'metadata': {
          'version': '0.0.1',
          'exportedAt': DateTime.now().toIso8601String(),
        },
        'subjects': DatabaseService.subjectBox.values
            .map((s) => {
                  'id': s.key, // Hive auto-increment key or unique key
                  'name': s.name,
                  'semesterID': s.semesterID,
                  'colorValue': s.colorValue,
                  'iconCodePoint': s.iconCodePoint,
                })
            .toList(),
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
                  'status': l.status,
                  'isExtraClass': l.isExtraClass,
                })
            .toList(),
        'timetable': DatabaseService.timetableBox.values
            .map((t) => {
                  'id': t.key,
                  'subjectID': t.subjectID,
                  'dayOfWeek': t.dayOfWeek,
                  'startHour': t.startHour,
                  'startMinute': t.startMinute,
                  'endHour': t.endHour,
                  'endMinute': t.endMinute,
                  'roomNo': t.roomNo,
                })
            .toList(),
        'attendance': DatabaseService.attendanceBox.values
            .map((a) => {
                  'subjectID': a.subjectID,
                  'monthKey': a.monthKey,
                  'presentCount': a.presentCount,
                  'totalCount': a.totalCount,
                })
            .toList(),
      };

      final String jsonString = jsonEncode(backupData);

      // Fire up a share sheet directly without messing with manual Storage Permissions!
      final XFile file = XFile.fromData(
        utf8.encode(jsonString),
        mimeType: 'application/json',
        name:
            'attendance_backup_${DateFormat('yyyyMMdd').format(DateTime.now())}.json',
      );

      await Share.shareXFiles([file], text: 'My Attendance Tracker Backup');
    } catch (e) {
      throw Exception('Failed to generate backup file: $e');
    }
  }

  /// Lets the user pick a backup JSON file and restores it directly to Hive boxes
  static Future<bool> importBackup() async {
    try {
      FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.single.path == null) return false;

      final file = File(result.files.single.path!);
      final String jsonContent = await file.readAsString();
      final Map<String, dynamic> backupData = jsonDecode(jsonContent);

      // Simple validation signature check
      if (!backupData.containsKey('subjects') ||
          !backupData.containsKey('lectures')) {
        throw Exception('Invalid backup file format.');
      }

      // 1. Clear existing application boxes cleanly to avoid mixing data signatures
      await DatabaseService.subjectBox.clear();
      await DatabaseService.lectureBox.clear();
      await DatabaseService.timetableBox.clear();
      await DatabaseService.attendanceBox.clear();

      // 2. Restore Subjects
      for (var s in backupData['subjects']) {
        final subject = Subject(
          name: s['name'],
          semesterID: s['semesterID'],
          colorValue: s['colorValue'],
          iconCodePoint: s['iconCodePoint'],
        );
        await DatabaseService.subjectBox.put(s['id'], subject);
      }

      // 3. Restore Lectures
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
          roomNo: l['roomNo'],
          status: l['status'],
          isExtraClass: l['isExtraClass'] ?? false,
        );
        await DatabaseService.lectureBox.put(l['lectureUID'], lecture);
      }

      // 4. Restore Timetable
      for (var t in backupData['timetable']) {
        final entry = TimetableEntry(
          subjectID: t['subjectID'],
          semesterID: t['semesterID'],
          dayOfWeek: t['dayOfWeek'],
          startHour: t['startHour'],
          startMinute: t['startMinute'],
          endHour: t['endHour'],
          endMinute: t['endMinute'],
          roomNo: t['roomNo'],
        );
        await DatabaseService.timetableBox.put(t['id'], entry);
      }

      // 5. Restore Attendance Analytics Cache Counters
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

      return true;
    } catch (e) {
      throw Exception('Error importing data structure: $e');
    }
  }
}
