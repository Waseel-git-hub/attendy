// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lecture.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class LectureAdapter extends TypeAdapter<Lecture> {
  @override
  final int typeId = 1;

  @override
  Lecture read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Lecture(
      lectureUID: fields[0] as String,
      subjectID: fields[1] as dynamic,
      date: fields[2] as DateTime,
      startHour: fields[3] as int,
      startMinute: fields[4] as int,
      endHour: fields[5] as int,
      endMinute: fields[6] as int,
      status: fields[7] as String,
      roomNo: fields[8] as String,
      isExtraClass: fields[9] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, Lecture obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.lectureUID)
      ..writeByte(1)
      ..write(obj.subjectID)
      ..writeByte(2)
      ..write(obj.date)
      ..writeByte(3)
      ..write(obj.startHour)
      ..writeByte(4)
      ..write(obj.startMinute)
      ..writeByte(5)
      ..write(obj.endHour)
      ..writeByte(6)
      ..write(obj.endMinute)
      ..writeByte(7)
      ..write(obj.status)
      ..writeByte(8)
      ..write(obj.roomNo)
      ..writeByte(9)
      ..write(obj.isExtraClass);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LectureAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
