import 'package:hive_flutter/hive_flutter.dart';

part 'special_day.g.dart';

@HiveType(typeId: 6)
class SpecialDay extends HiveObject {
  @HiveField(0)
  DateTime date;

  @HiveField(1)
  String reason;

  @HiveField(2)
  bool isLeave;

  SpecialDay({
    required this.date,
    required this.reason,
    this.isLeave = true,
  });
}
