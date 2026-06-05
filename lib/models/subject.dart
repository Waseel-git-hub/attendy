import 'package:hive/hive.dart';

part 'subject.g.dart';

@HiveType(typeId: 0)
class Subject extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  dynamic semesterID;

  @HiveField(2)
  int iconCodePoint;

  @HiveField(3)
  int colorValue;

  @HiveField(4)
  int minAttend;

  Subject({
    required this.name,
    required this.semesterID,
    required this.iconCodePoint,
    required this.colorValue,
    this.minAttend = 75,
  });
}
