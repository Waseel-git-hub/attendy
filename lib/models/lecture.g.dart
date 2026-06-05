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
      semesterID: fields[2] as dynamic,
      date: fields[3] as DateTime,
      startHour: fields[4] as int,
      startMinute: fields[5] as int,
      endHour: fields[6] as int,
      endMinute: fields[7] as int,
      status: fields[8] as String,
      roomNo: fields[9] as String,
      isExtraClass: fields[10] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, Lecture obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.lectureUID)
      ..writeByte(1)
      ..write(obj.subjectID)
      ..writeByte(2)
      ..write(obj.semesterID)
      ..writeByte(3)
      ..write(obj.date)
      ..writeByte(4)
      ..write(obj.startHour)
      ..writeByte(5)
      ..write(obj.startMinute)
      ..writeByte(6)
      ..write(obj.endHour)
      ..writeByte(7)
      ..write(obj.endMinute)
      ..writeByte(8)
      ..write(obj.status)
      ..writeByte(9)
      ..write(obj.roomNo)
      ..writeByte(10)
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
