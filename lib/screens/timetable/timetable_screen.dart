import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
//  MODELS
import '../../models/timetable.dart';
import '../../models/subject.dart';
//  SCREENS
import '../../screens/timetable/timetable_setup.dart';
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
  final double timeBarWidth = 40.0;
  final double headerHeight = 40.0;

  late int startHour;
  late int endHour;
  late Map<int, bool> visibleDays;

  final ScrollController _verticalController = ScrollController();
  final ScrollController _timeBarScrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    // 💡 LOAD PERSISTED CONFIGURATIONS FROM HIVE
    startHour = DatabaseService.settingsBox.get('startHour', defaultValue: 8);
    endHour = DatabaseService.settingsBox.get('endHour', defaultValue: 18);

    // Hive maps look like Map<dynamic, dynamic>, so we cast it safely back to Map<int, bool>
    final rawDays = DatabaseService.settingsBox.get('visibleDays');
    visibleDays = Map<int, bool>.from(rawDays ??
        {1: true, 2: true, 3: true, 4: true, 5: true, 6: false, 7: false});

    _verticalController.addListener(() {
      if (_timeBarScrollController.hasClients) {
        _timeBarScrollController.jumpTo(_verticalController.offset);
      }
    });
  }

  @override
  void dispose() {
    _verticalController.dispose();
    _timeBarScrollController.dispose();
    super.dispose();
  }

  int get activeDaysCount =>
      visibleDays.values.where((visible) => visible).length;
  int get totalHoursCount => endHour - startHour + 2;

  // 🛠️ PERSISTED SHEET SELECTION
  void _openFilterSettings() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            final List<String> dayNames = [
              "Mon",
              "Tue",
              "Wed",
              "Thu",
              "Fri",
              "Sat",
              "Sun"
            ];

            return Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Show Days",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8.0, // Gap between adjacent chips horizontally
                    runSpacing: 4.0, // Gap between lines vertically
                    alignment: WrapAlignment
                        .start, // Aligns chips neatly to the left boundary
                    children: List.generate(7, (index) {
                      int dayNum = index + 1;
                      bool isSelected = visibleDays[dayNum] ?? false;
                      return FilterChip(
                        label: Text(dayNames[index]),
                        selected: isSelected,
                        onSelected: (bool value) async {
                          if (!value && activeDaysCount <= 1)
                            return; // Prevent breaking grid empty layouts

                          setModalState(() => visibleDays[dayNum] = value);
                          setState(() => visibleDays[dayNum] = value);

                          // 💾 Save immediately to settings Box
                          await DatabaseService.settingsBox
                              .put('visibleDays', visibleDays);
                        },
                      );
                    }),
                  ),
                  const SizedBox(height: 20),
                  const Text("Select Active Time",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          decoration: const InputDecoration(
                              labelText: "Start Hour",
                              border: OutlineInputBorder()),
                          value: startHour,
                          items: List.generate(
                              13,
                              (i) => DropdownMenuItem(
                                  value: i + 6,
                                  child: Text(
                                      "${i + 6 == 12 ? 12 : (i + 6) % 12} ${i + 6 >= 12 ? 'PM' : 'AM'}"))),
                          onChanged: (val) async {
                            if (val != null && val < endHour) {
                              setModalState(() => startHour = val);
                              setState(() => startHour = val);
                              // 💾 Update persistent storage instance
                              await DatabaseService.settingsBox
                                  .put('startHour', startHour);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          decoration: const InputDecoration(
                              labelText: "End Hour",
                              border: OutlineInputBorder()),
                          value: endHour,
                          items: List.generate(
                              13,
                              (i) => DropdownMenuItem(
                                  value: i + 13,
                                  child: Text(
                                      "${i + 13 == 12 ? 12 : (i + 13) % 12} ${i + 13 >= 12 ? 'PM' : 'AM'}"))),
                          onChanged: (val) async {
                            if (val != null && val > startHour) {
                              setModalState(() => endHour = val);
                              setState(() => endHour = val);
                              // 💾 Update persistent storage instance
                              await DatabaseService.settingsBox
                                  .put('endHour', endHour);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Timetable",
            style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Filter View Settings',
            icon: const Icon(Icons.tune_rounded),
            onPressed: _openFilterSettings,
          ),
          IconButton(
            tooltip: 'Edit Timetable',
            icon: const Icon(Icons.edit_calendar_rounded),
            onPressed: () async {
              // 1. Show a quick loader while production records are fetched and mapped
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) =>
                    const Center(child: CircularProgressIndicator()),
              );

              try {
                // 2. Generate the editable memory draft from live production boxes
                final currentDraft =
                    await DatabaseService.generateDraftFromProduction();

                if (!context.mounted) return;
                Navigator.pop(context);

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SetupTimetableScreen(
                      setupDraft: currentDraft,
                      isFromOnboarding: false,
                      onNext: () {},
                      onBack: () => Navigator.pop(context),
                    ),
                  ),
                );
              } catch (e) {
                if (!context.mounted) return;
                Navigator.pop(context); // Dismiss loader safely
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to load timetable data: $e')),
                );
              }
            },
          )
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final double dynamicColumnWidth =
              (constraints.maxWidth - timeBarWidth) / activeDaysCount;

          return Column(
            children: [
              _buildTopHeader(theme, dynamicColumnWidth),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStickyTimeBar(colorScheme.onSurface),
                    Expanded(
                      child: _buildMainGrid(
                          colorScheme.onSurface, dynamicColumnWidth),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // --- UI COMPONENTS ---

  Widget _buildTopHeader(ThemeData theme, double columnWidth) {
    final colorScheme = theme.colorScheme;
    final List<String> shortDays = [
      "MON",
      "TUE",
      "WED",
      "THU",
      "FRI",
      "SAT",
      "SUN"
    ];

    return Row(
      children: [
        SizedBox(width: timeBarWidth, height: headerHeight),
        ...List.generate(7, (index) {
          int dayNum = index + 1;
          if (!(visibleDays[dayNum] ?? true)) return const SizedBox.shrink();

          return SizedBox(
            width: columnWidth,
            height: headerHeight,
            child: Center(
              child: Text(
                shortDays[index],
                style: TextStyle(
                    color: colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                    fontSize: 12),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildStickyTimeBar(Color color) {
    return SingleChildScrollView(
      controller: _timeBarScrollController,
      scrollDirection: Axis.vertical,
      physics: const NeverScrollableScrollPhysics(),
      child: Container(
        width: timeBarWidth,
        decoration: BoxDecoration(
          border: Border(right: BorderSide(color: color.withOpacity(0.2))),
        ),
        child: Column(
          children: List.generate(totalHoursCount, (index) {
            int hour = index + startHour - 1;
            String period = hour >= 12 ? 'PM' : 'AM';
            int displayHour = hour > 12 ? hour - 12 : hour;
            if (hour == 12) displayHour = 12;

            return SizedBox(
              height: hourHeight,
              child: Align(
                alignment: Alignment.topCenter,
                // 💡 Translate shifts the text block upwards slightly
                // so the line cuts right through the center of the text
                child: Transform.translate(
                  offset: const Offset(0, -7.0),
                  child: Text(
                    "$displayHour \n$period",
                    style: TextStyle(
                      color: color.withOpacity(0.6),
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildMainGrid(Color color, double columnWidth) {
    return SingleChildScrollView(
      controller: _verticalController,
      scrollDirection: Axis.vertical,
      physics: const BouncingScrollPhysics(),
      child: ValueListenableBuilder(
        valueListenable: DatabaseService.timetableBox.listenable(),
        builder: (context, Box<TimetableEntry> box, _) {
          final entriesToRender = box.values.where((entry) {
            bool isDayVisible = visibleDays[entry.dayOfWeek] ?? true;
            bool isInsideTimeframe =
                entry.startHour >= startHour && entry.endHour <= endHour;
            return isDayVisible && isInsideTimeframe;
          }).toList();

          return SizedBox(
            height: hourHeight * totalHoursCount,
            width: columnWidth * activeDaysCount,
            child: Stack(
              children: [
                _buildGridLines(color),
                ...entriesToRender
                    .map((entry) => _buildPositionedBlock(entry, columnWidth))
                    .toList(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildGridLines(Color color) {
    return Column(
      children: List.generate(
        totalHoursCount,
        (index) => Container(
          height: hourHeight,
          decoration: BoxDecoration(
              border:
                  Border(bottom: BorderSide(color: color.withOpacity(0.1)))),
        ),
      ),
    );
  }

  Widget _buildPositionedBlock(TimetableEntry entry, double columnWidth) {
    final Subject? subject = DatabaseService.getSubjectById(entry.subjectID);

    final double top = ((entry.startHour - startHour + 1) * hourHeight) +
        (entry.startMinute / 60 * hourHeight);
    final int durationMin = (entry.endHour * 60 + entry.endMinute) -
        (entry.startHour * 60 + entry.startMinute);
    final double height = (durationMin / 60) * hourHeight;

    int visibleDaysBefore = 0;
    for (int i = 1; i < entry.dayOfWeek; i++) {
      if (visibleDays[i] ?? true) visibleDaysBefore++;
    }
    final double left = visibleDaysBefore * columnWidth;

    return SubjectBlock(
      title: _getShortName(subject?.name),
      room: entry.roomNo,
      color: Color(subject?.colorValue ?? 0xFF6366F1),
      top: top,
      height: height,
      left: left,
      width: columnWidth - 2,
      onTap: () {},
      onHold: () {},
    );
  }

  String _getShortName(String? name) {
    name = name?.trim();

    // Split name by spaces (e.g., "Digital Electronics" -> ["Digital", "Electronics"])
    List<String> words = name!.split(RegExp(r'\s+'));

    if (words.length > 1) {
      // Take the first letter of every word and make it uppercase (e.g., "DSA")
      return words.map((word) => word[0].toUpperCase()).join();
    } else {
      // If it's just one word (like "Mathematics"), take the first 4 letters
      return name.length > 4
          ? "${name.substring(0, 4).toUpperCase()}"
          : name.toUpperCase();
    }
  }
}
