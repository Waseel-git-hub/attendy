// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'special_day.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SpecialDayAdapter extends TypeAdapter<SpecialDay> {
  @override
  final int typeId = 6;

  @override
  SpecialDay read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SpecialDay(
      date: fields[0] as DateTime,
      reason: fields[1] as String,
      isLeave: fields[2] as bool,
      groupID: fields[3] as String,
    );
  }

  @override
  void write(BinaryWriter writer, SpecialDay obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.date)
      ..writeByte(1)
      ..write(obj.reason)
      ..writeByte(2)
      ..write(obj.isLeave)
      ..writeByte(3)
      ..write(obj.groupID);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SpecialDayAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
