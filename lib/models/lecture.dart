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
  String status; // NONE, PRESENT, ABSENT, CANCELLED

  @HiveField(4)
  String roomNo;

  @HiveField(5)
  bool isExtraClass;

  Lecture({
    required this.lectureUID,
    required this.subjectID,
    required this.date,
    this.status = "NONE",
    this.roomNo = "",
    this.isExtraClass = false,
  });
}
