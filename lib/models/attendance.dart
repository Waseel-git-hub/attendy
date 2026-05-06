import 'package:hive/hive.dart';

part 'attendance.g.dart';

@HiveType(typeId: 4)
class AttendanceCount extends HiveObject {
  @HiveField(0)
  dynamic subjectID;

  @HiveField(1)
  String monthKey;

  @HiveField(2)
  int presentCount;

  @HiveField(3)
  int totalCount;

  AttendanceCount({
    required this.subjectID,
    required this.monthKey,
    required this.presentCount,
    required this.totalCount,
  });
}
