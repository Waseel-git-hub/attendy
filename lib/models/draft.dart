class SubjectDraft {
  final dynamic temporaryId;
  String name;
  int iconCodePoint;
  int colorValue;
  int minAttend;

  SubjectDraft({
    required this.temporaryId,
    required this.name,
    required this.iconCodePoint,
    required this.colorValue,
    this.minAttend = 75,
  });
}

class TimetableEntryDraft {
  String timeSlotKey;
  int dayOfWeek; // 1 = Mon, 7 = Sun
  int startHour;
  int startMinute;
  int endHour;
  int endMinute;
  String roomNo;
  dynamic subjectTemporaryId; // Links back to SubjectDraft.temporaryId

  TimetableEntryDraft({
    required this.timeSlotKey,
    required this.dayOfWeek,
    required this.startHour,
    required this.startMinute,
    required this.endHour,
    required this.endMinute,
    this.roomNo = '',
    this.subjectTemporaryId,
  });

  factory TimetableEntryDraft.create({
    required int dayOfWeek,
    required int startHour,
    required int startMinute,
    required int endHour,
    required int endMinute,
    String roomNo = '',
    dynamic subjectTemporaryId,
  }) {
    // Pad left minutes to keep formatting predictable (e.g., "05" instead of "5")
    final sMin = startMinute.toString().padLeft(2, '0');
    final eMin = endMinute.toString().padLeft(2, '0');
    final key = "$dayOfWeek-$startHour:$sMin-$endHour:$eMin";

    return TimetableEntryDraft(
      timeSlotKey: key,
      dayOfWeek: dayOfWeek,
      startHour: startHour,
      startMinute: startMinute,
      endHour: endHour,
      endMinute: endMinute,
      roomNo: roomNo,
      subjectTemporaryId: subjectTemporaryId,
    );
  }
}

class SetupDraft {
  String semesterName = '';
  DateTime? startDate;
  DateTime? endDate;

  List<SubjectDraft> subjects = [];
  List<TimetableEntryDraft> timetableSlots =
      []; // Tracks the draft schedule slots

  void reset() {
    semesterName = '';
    startDate = null;
    endDate = null;
    subjects.clear();
    timetableSlots.clear();
  }
}
