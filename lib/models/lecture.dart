import 'package:hive/hive.dart';

part 'lecture.g.dart';

@HiveType(typeId: 1)
class Lecture extends HiveObject {
  @HiveField(0)
  String lectureUID;

  @HiveField(1)
  dynamic subjectID;

  @HiveField(2)
  DateTime date;

  @HiveField(3)
  int startHour;

  @HiveField(4)
  int startMinute;

  @HiveField(5)
  int endHour;

  @HiveField(6)
  int endMinute;

  @HiveField(7)
  String status; // NONE, PRESENT, ABSENT, CANCELLED

  @HiveField(8)
  String roomNo;

  @HiveField(9)
  bool isExtraClass;

  Lecture({
    required this.lectureUID,
    required this.subjectID,
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
