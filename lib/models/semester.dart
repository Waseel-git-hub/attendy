import 'package:hive_flutter/hive_flutter.dart';

part 'semester.g.dart';

@HiveType(typeId: 5)
class Semester extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  DateTime startDate;

  @HiveField(2)
  DateTime endDate;

  @HiveField(3)
  bool isActive;

  Semester({
    required this.name,
    required this.startDate,
    required this.endDate,
    this.isActive = true,
  });
}
