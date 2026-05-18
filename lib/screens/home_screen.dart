import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:hive_flutter/hive_flutter.dart';
//  MODELS
import '../models/lecture.dart';
import '../models/subject.dart';
//  SCREENS
//  SERVICES
import '../services/database_service.dart';
//  WIGDETS
import '../widgets/lecture_card.dart';
import '../widgets/timeline.dart';
//------------------------------------------------------------------------------

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DateTime _selectedDate = DateTime.now();
  int _currentPageIndex = 500;

  List<DateTime> _getWeekDatesForPage(int pageIndex) {
    DateTime baseMonday =
        DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1));
    DateTime targetMonday =
        baseMonday.add(Duration(days: (pageIndex - 500) * 7));
    return List.generate(7, (i) => targetMonday.add(Duration(days: i)));
  }

  void _showAddExtraLectureSheet(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    DateTime selectedDate = _selectedDate;
    TimeOfDay selectedStartTime = const TimeOfDay(hour: 9, minute: 0);
    TimeOfDay selectedEndTime = TimeOfDay(
        hour: selectedStartTime.hour + 1, minute: selectedStartTime.minute);
    bool customEndTime = false;
    dynamic _selectedSubjectId;
    Subject? _selectedSubject;
    final TextEditingController roomController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Allows sheet to push up when keyboard opens
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          // Allows local state updates inside the sheet
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                top: 20,
                left: 20,
                right: 20,
              ),
              child: SingleChildScrollView(
                // FIXED: Prevents keyboard compression layout crashes
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Add Extra Lecture",
                      style: TextStyle(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                          fontSize: 28),
                    ),
                    const SizedBox(height: 15),

                    // 1. SUBJECT DROPDOWN (Fetched dynamically from your subjects)

                    ValueListenableBuilder(
                      valueListenable: DatabaseService.subjectBox.listenable(),
                      builder: (context, Box<Subject> box, _) {
                        if (box.values.isEmpty) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: const Text(
                              "No subjects found! Add them in settings first.",
                              style: TextStyle(
                                color: Colors.redAccent,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        }

                        return DropdownButtonFormField<dynamic>(
                          value: _selectedSubjectId,
                          selectedItemBuilder: (BuildContext context) {
                            return box.values.map((Subject subject) {
                              return Row(
                                children: [
                                  Icon(
                                    IconData(subject.iconCodePoint,
                                        fontFamily: 'MaterialIcons'),
                                    color: Color(subject.colorValue),
                                    size: 20,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    subject.name,
                                    style: TextStyle(
                                        color: theme.colorScheme.onSurface),
                                  ),
                                ],
                              );
                            }).toList();
                          },

                          decoration: InputDecoration(
                            labelText: "Select Subject",
                            labelStyle: TextStyle(
                              color: colorScheme.onSurface.withOpacity(0.6),
                            ),
                            filled: true,
                            fillColor: colorScheme.surfaceContainerHighest,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          dropdownColor: colorScheme.surfaceContainerHigh,

                          // RICH DROPDOWN MENU LIST ITEMS
                          items: box.values.map((Subject subject) {
                            return DropdownMenuItem<dynamic>(
                              value: subject.key,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Renders the icon with its unique color inside the menu selector tray
                                  Icon(
                                    IconData(subject.iconCodePoint,
                                        fontFamily: 'MaterialIcons'),
                                    color: Color(subject.colorValue),
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    subject.name,
                                    style: const TextStyle(fontSize: 15),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),

                          onChanged: (dynamic val) {
                            setModalState(() {
                              _selectedSubjectId = val;
                              _selectedSubject =
                                  DatabaseService.getSubjectById(val);
                            });
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 15),

                    // 2. DATE PICKER ROW
                    ListTile(
                      leading: const Icon(Icons.calendar_month),
                      title: const Text("Date"),
                      subtitle:
                          Text(DateFormat('yyyy-MM-dd').format(selectedDate)),
                      trailing: const Icon(Icons.edit, size: 20),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime.now()
                              .subtract(const Duration(days: 365)),
                          lastDate:
                              DateTime.now().add(const Duration(days: 365)),
                        );
                        if (picked != null) {
                          setModalState(() => selectedDate = picked);
                        }
                      },
                    ),

                    // 3. START TIME PICKER ROW
                    ListTile(
                      leading: const Icon(Icons.access_time),
                      title: const Text("Start Time"),
                      subtitle: Text(selectedStartTime.format(context)),
                      trailing: const Icon(Icons.edit, size: 20),
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: selectedStartTime,
                        );
                        if (picked != null) {
                          setModalState(() {
                            selectedStartTime = picked;
                            if (!customEndTime) {
                              selectedEndTime = TimeOfDay(
                                  hour: picked.hour + 1, minute: picked.minute);
                            }
                          });
                        }
                      },
                    ),

                    // 4. END TIME PICKER ROW
                    ListTile(
                      leading: const Icon(Icons.access_time),
                      title: const Text("End Time"),
                      subtitle: Text(selectedEndTime.format(context)),
                      trailing: const Icon(Icons.edit, size: 20),
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: selectedEndTime,
                        );
                        if (picked != null) {
                          setModalState(() {
                            customEndTime = true;
                            selectedEndTime = picked;
                          });
                        }
                      },
                    ),

                    // 5. ROOM TEXT FIELD
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: TextFormField(
                        controller: roomController,
                        textCapitalization: TextCapitalization.none,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface),
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.room),
                          labelText: "Room No.",
                          hintText: "101, 205, A-15",
                          labelStyle: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.6),
                          ),
                          filled: true,
                          fillColor: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // 6. ACTION BUTTONS
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text("Cancel"),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).colorScheme.primary,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () async {
                            if (_selectedSubjectId == null) return;

                            // Extract value safely or set default fallback text
                            String roomText = roomController.text.trim().isEmpty
                                ? 'Not Specified'
                                : roomController.text.trim();

                            await DatabaseService.lectureInput(
                              _selectedSubjectId,
                              DateTime(
                                selectedDate.year,
                                selectedDate.month,
                                selectedDate.day,
                              ),
                              selectedStartTime.hour,
                              selectedStartTime.minute,
                              selectedEndTime.hour,
                              selectedEndTime.minute,
                              'Not Marked',
                              roomText, // FIXED: Replaced 'None' with the typed room controller data!
                              isExtraClass: true,
                            );

                            if (mounted) {
                              Navigator.pop(context);
                              setState(() {});
                            }
                          },
                          child: const Text("Save Lecture"),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildHeader(),
          _buildDateSelector(),
          _buildLectureList(),
          _addExtraButton(),
        ],
      ),
    );
  }

  Widget _buildDateSelector() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final double screenWidth = MediaQuery.of(context).size.width;
    final double itemWidth = (screenWidth - (16 * 2) - (8 * 3)) / 7;

    return SliverToBoxAdapter(
      child: Container(
        height: 85,
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: PageView.builder(
          controller: PageController(initialPage: 500),
          onPageChanged: (int index) {
            setState(() {
              int pageDifference = index - _currentPageIndex;
              _selectedDate =
                  _selectedDate.add(Duration(days: pageDifference * 7));
              _currentPageIndex = index;
            });
          },
          itemBuilder: (context, pageIndex) {
            final weekDates = _getWeekDatesForPage(pageIndex);

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(7, (index) {
                  final date = weekDates[index];
                  bool isSelected = date.year == _selectedDate.year &&
                      date.month == _selectedDate.month &&
                      date.day == _selectedDate.day;

                  return GestureDetector(
                    onTap: () => setState(() => _selectedDate = date),
                    child: Container(
                      width: itemWidth > 0 ? itemWidth : 48.103896103896105,
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: colorScheme.onSurface.withOpacity(0.04),
                            blurRadius: 1,
                          ),
                        ],
                        color: isSelected
                            ? colorScheme.primary
                            : colorScheme.primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            DateFormat('EEE').format(date).toUpperCase(),
                            style: TextStyle(
                              color: (isSelected)
                                  ? Colors.white
                                  : colorScheme.onSurface.withOpacity(0.55),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "${date.day}",
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : colorScheme.onSurface,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            );
          },
        ),
      ),
    );
  }

  // 3. The List: Combining Timeline + LectureCard
  Widget _buildLectureList() {
    return FutureBuilder(
      // 1. Trigger the generation first
      future: DatabaseService.generateLecturesForDate(_selectedDate),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SliverToBoxAdapter(
            child: Center(child: CircularProgressIndicator()),
          );
        }

        // 2. Now that generation is done, fetch the sorted list
        final List<Lecture> lectures =
            DatabaseService.getLectures(specificDate: _selectedDate);

        if (lectures.isEmpty) {
          return const SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: EdgeInsets.only(top: 100),
                child: Text("No classes scheduled",
                    style: TextStyle(color: Colors.white38)),
              ),
            ),
          );
        }

        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final lecture = lectures[index];

                return IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TimelineIndicatorTrack(
                        leftWidth: 55,
                        showTopLine: true,
                        showBottomLine: index != lectures.length - 1,
                        lineColor: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.15),
                        leftWidget: _buildTimeColumn(lecture),
                        indicatorNode: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withOpacity(0.3),
                              width: 4,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 12),

                      // 3. The Lecture Card
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: ValueListenableBuilder(
                            // We listen to the box so the UI updates when status is saved
                            valueListenable:
                                DatabaseService.lectureBox.listenable(),
                            builder: (context, box, _) {
                              return LectureCard(
                                  lecture: lecture,
                                  onTap: () {
                                    print("Lecture Tapped");
                                  });
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
              childCount: lectures.length,
            ),
          ),
        );
      },
    );
  }

  Widget _buildTimeColumn(Lecture lecture) {
    final colorScheme = Theme.of(context).colorScheme;
    String startTime =
        '${lecture.startHour}:${lecture.startMinute.toString().padLeft(2, '0')}';
    String endTime =
        '${lecture.endHour}:${lecture.endMinute.toString().padLeft(2, '0')}';
    return SizedBox(
      width: 50,
      child: Padding(
        padding: const EdgeInsets.only(top: 20),
        child: Column(
          children: [
            const SizedBox(height: 52),
            Text(startTime,
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontSize: 16,
                )),
            Text(
              endTime,
              style: TextStyle(
                  color: colorScheme.onSurface.withOpacity(0.6), fontSize: 12),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return SliverAppBar(
      pinned: true,
      expandedHeight: 80,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        title: const Text("This Week",
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: false,
      ),
    );
  }

  Widget _addExtraButton() {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(
          16, 8, 16, 32), // 32 bottom padding gives breathing room
      sliver: SliverToBoxAdapter(
        child: InkWell(
          onTap: () => _showAddExtraLectureSheet(context),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                width: 1.5,
                style: BorderStyle.solid, // Change to dashed if using a package
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.add_circle_outline_rounded,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  "Add Extra Lecture",
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
