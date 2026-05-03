import 'package:hive/hive.dart';
part 'timetable.g.dart';

@HiveType(typeId: 3) // New ID for the schedule template
class TimetableEntry extends HiveObject {
  @HiveField(0)
  int dayOfWeek; // 1 = Mon, 7 = Sun
  @HiveField(1)
  int startHour;
  @HiveField(2)
  int startMinute;
  @HiveField(3)
  int endHour;
  @HiveField(4)
  int endMinute;
  @HiveField(5)
  String roomNo;
  @HiveField(6)
  dynamic subjectId; // Links back to Subject(0)

  TimetableEntry({
    required this.dayOfWeek,
    required this.startHour,
    required this.startMinute,
    required this.endHour,
    required this.endMinute,
    required this.roomNo,
    required this.subjectId,
  });
}
