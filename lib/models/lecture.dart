import 'package:hive/hive.dart';

part 'lecture.g.dart';

@HiveType(typeId: 1)
class Lecture extends HiveObject {
  @HiveField(0)
  String lectureUID;

  @HiveField(1)
  dynamic subjectID;

  @HiveField(2)
  dynamic semesterID;

  @HiveField(3)
  DateTime date;

  @HiveField(4)
  int startHour;

  @HiveField(5)
  int startMinute;

  @HiveField(6)
  int endHour;

  @HiveField(7)
  int endMinute;

  @HiveField(8)
  String status; // Not Marked, Present, Absent, Cancelled

  @HiveField(9)
  String roomNo;

  @HiveField(10)
  bool isExtraClass;

  Lecture({
    required this.lectureUID,
    required this.subjectID,
    required this.semesterID,
    required this.date,
    required this.startHour,
    required this.startMinute,
    required this.endHour,
    required this.endMinute,
    this.status = "NONE",
    this.roomNo = "",
    this.isExtraClass = false,
  });
}
