import 'package:attendance_tracker/screens/timetable/timetable_input_screen.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
//  MODELS
import '../../models/timetable.dart';
import '../../models/subject.dart';
//  SCREENS
//  SERVICES
import '../../services/database_service.dart';
//  WIDGETS
import '../../widgets/timetable_block.dart';
//------------------------------------------------------------------------------

class TimetableScreen extends StatefulWidget {
  const TimetableScreen({super.key});

  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen> {
  final double hourHeight = 80.0;
  final double columnWidth = 120.0;
  final double timeBarWidth = 70.0;
  final double headerHeight = 60.0;
  final int startHour = 8;

  final ScrollController _horizontalController = ScrollController();
  final ScrollController _verticalController = ScrollController();
  final ScrollController _headerScrollController = ScrollController();
  final ScrollController _timeBarScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _horizontalController.addListener(() {
      if (_headerScrollController.hasClients) {
        _headerScrollController.jumpTo(_horizontalController.offset);
      }
    });
    _verticalController.addListener(() {
      if (_timeBarScrollController.hasClients) {
        _timeBarScrollController.jumpTo(_verticalController.offset);
      }
    });
  }

  @override
  void dispose() {
    _horizontalController.dispose();
    _verticalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    /*  final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
*/

    return Scaffold(
      appBar: AppBar(
        title: const Text("Timetable",
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
              onPressed: () {}, icon: const Icon(Icons.calendar_month_outlined))
        ],
      ),
      body: Column(
        children: [
          _buildTopHeader(),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStickyTimeBar(),
                Expanded(
                  child: _buildMainGrid(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- UI COMPONENTS ---

  Widget _buildTopHeader() {
    return Row(
      children: [
        SizedBox(width: timeBarWidth, height: headerHeight),
        Expanded(
          child: SingleChildScrollView(
            controller: _headerScrollController,
            scrollDirection: Axis.horizontal,
            physics: BouncingScrollPhysics(),
            child: Row(
              children:
                  ["MON", "TUE", "WED", "THU", "FRI", "SAT", "SUN"].map((day) {
                return SizedBox(
                  width: columnWidth,
                  height: headerHeight,
                  child: Center(
                    child: Text(
                      day,
                      style: TextStyle(
                          color:
                              Theme.of(context).colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.1),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStickyTimeBar() {
    return SingleChildScrollView(
      controller: _timeBarScrollController,
      scrollDirection: Axis.vertical,
      physics: const NeverScrollableScrollPhysics(),
      child: Container(
        width: timeBarWidth,
        decoration: BoxDecoration(
          border:
              Border(right: BorderSide(color: Colors.white.withOpacity(0.05))),
        ),
        child: Column(
          children: List.generate(15, (index) {
            int hour = index + startHour - 1;
            return SizedBox(
              height: hourHeight,
              child: Text(
                "${hour > 12 ? hour - 12 : hour} ${hour >= 12 ? 'PM' : 'AM'}",
                style: const TextStyle(color: Colors.white38, fontSize: 11),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildMainGrid() {
    return SingleChildScrollView(
      controller: _horizontalController,
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: SingleChildScrollView(
        controller: _verticalController,
        scrollDirection: Axis.vertical,
        physics: const BouncingScrollPhysics(),
        child: ValueListenableBuilder(
          valueListenable: DatabaseService.timetableBox.listenable(),
          builder: (context, Box<TimetableEntry> box, _) {
            return SizedBox(
              height: hourHeight * 15,
              width: columnWidth * 7,
              child: Stack(
                children: [
                  _buildGridLines(),
                  ...List.generate(
                      7, (i) => _buildColumnTouchSensor(context, i + 1)),
                  ...box.values
                      .map((entry) => _buildPositionedBlock(entry))
                      .toList(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildGridLines() {
    return Column(
      children: List.generate(
          15,
          (index) => Container(
                height: hourHeight,
                decoration: BoxDecoration(
                  border: Border(
                      bottom:
                          BorderSide(color: Colors.white.withOpacity(0.15))),
                ),
              )),
    );
  }

  Widget _buildColumnTouchSensor(BuildContext context, int dayIndex) {
    return Positioned(
      left: (dayIndex - 1) * columnWidth,
      top: 0,
      bottom: 0,
      width: columnWidth,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _showAddPrompt(context, dayIndex),
        child: Container(
          decoration: BoxDecoration(
            border: Border(
                right: BorderSide(color: Colors.white.withOpacity(0.03))),
          ),
        ),
      ),
    );
  }

  // --- POSITIONING LOGIC ---

  Widget _buildPositionedBlock(TimetableEntry entry) {
    final Subject? subject = DatabaseService.getSubjectById(entry.subjectId);

    final double top = ((entry.startHour - startHour) * hourHeight) +
        (entry.startMinute / 60 * hourHeight);

    final int durationMin = (entry.endHour * 60 + entry.endMinute) -
        (entry.startHour * 60 + entry.startMinute);
    final double height = (durationMin / 60) * hourHeight;

    final double left = (entry.dayOfWeek - 1) * columnWidth;

    return SubjectBlock(
      title: subject?.name ?? "Unknown",
      room: entry.roomNo,
      color: Color(subject?.colorValue ?? 0xFF6366F1),
      top: top,
      height: height,
      left: left,
      width: columnWidth - 4,
      onTap: () {
        _showAddPrompt(context, entry.dayOfWeek, entry: entry);
      },
      onHold: () {},
    );
  }

  void _showAddPrompt(BuildContext context, int dayIndex,
      {TimetableEntry? entry}) {
    final isEditing = entry != null;
    final dayName = [
      "Monday",
      "Tuesday",
      "Wednesday",
      "Thursday",
      "Friday",
      "Saturday",
      "Sunday",
    ][dayIndex - 1];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C23),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          isEditing ? "Edit Class" : "Add Class to $dayName?",
          style: const TextStyle(color: Colors.white, fontSize: 18),
        ),
        content: isEditing
            ? Text("Do you want to modify this lecture?",
                style: const TextStyle(color: Colors.white70))
            : null,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                const Text("Cancel", style: TextStyle(color: Colors.white38)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close Dialog

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddTimetableScreen(
                    initialDay: dayIndex,
                    prevEntry: entry,
                  ),
                ),
              );
            },
            child: Text(isEditing ? "Edit" : "Add"),
          ),
        ],
      ),
    );
  }
}
