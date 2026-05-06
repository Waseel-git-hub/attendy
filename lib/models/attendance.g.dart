// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'attendance.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AttendanceAdapter extends TypeAdapter<AttendanceCount> {
  @override
  final int typeId = 4;

  @override
  AttendanceCount read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AttendanceCount(
      subjectID: fields[0] as dynamic,
      monthKey: fields[1] as String,
      presentCount: fields[2] as int,
      totalCount: fields[3] as int,
    );
  }

  @override
  void write(BinaryWriter writer, AttendanceCount obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.subjectID)
      ..writeByte(1)
      ..write(obj.monthKey)
      ..writeByte(2)
      ..write(obj.presentCount)
      ..writeByte(3)
      ..write(obj.totalCount);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AttendanceAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
