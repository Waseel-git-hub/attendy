// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'timetable.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TimetableEntryAdapter extends TypeAdapter<TimetableEntry> {
  @override
  final int typeId = 3;

  @override
  TimetableEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TimetableEntry(
      dayOfWeek: fields[0] as int,
      startHour: fields[1] as int,
      startMinute: fields[2] as int,
      endHour: fields[3] as int,
      endMinute: fields[4] as int,
      roomNo: fields[5] as String,
      subjectId: fields[6] as dynamic,
    );
  }

  @override
  void write(BinaryWriter writer, TimetableEntry obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.dayOfWeek)
      ..writeByte(1)
      ..write(obj.startHour)
      ..writeByte(2)
      ..write(obj.startMinute)
      ..writeByte(3)
      ..write(obj.endHour)
      ..writeByte(4)
      ..write(obj.endMinute)
      ..writeByte(5)
      ..write(obj.roomNo)
      ..writeByte(6)
      ..write(obj.subjectId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TimetableEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
