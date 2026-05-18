import 'package:attendance_tracker/models/lecture.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
//  MODELS
import '../../models/subject.dart';
//  SCREENS
import '../subject/add_subject_screen.dart';
//  WIDGETS
import '../../widgets/percent_indicator.dart';
import '../../widgets/timeline.dart';
//  SERVICES
import '../../services/database_service.dart';
//------------------------------------------------------------

class SubjectStatsPage extends StatefulWidget {
  final dynamic subjectKey; // Pass the Hive key of the chosen subject

  const SubjectStatsPage({super.key, required this.subjectKey});

  @override
  State<SubjectStatsPage> createState() => _SubjectStatsPageState();
}

class _SubjectStatsPageState extends State<SubjectStatsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Subject? _subject;

  List<String> _cacheMonthKeys = [];
  List<Lecture> _allLectures = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _subject = DatabaseService.getSubjectById(widget.subjectKey);
    _loadSubjectDataEngine();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadSubjectDataEngine() {
    final rawLectures = DatabaseService.getLectures(subjectID: _subject!.key);

    // Unique months
    final uniqueKeys = rawLectures
        .map((l) {
          final date = l.date ?? DateTime.now();
          return DateFormat('yyyy-MM').format(date);
        })
        .toSet()
        .toList();
    uniqueKeys.sort((a, b) => b.compareTo(a));

    setState(() {
      _allLectures = rawLectures;
      _cacheMonthKeys = uniqueKeys.take(3).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _subject!.name,
          style: TextStyle(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.bold,
              fontSize: 20),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddSubjectScreen(subject: _subject),
                ),
              );
            }, // For edit/delete operations later
          )
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: colorScheme.primary,
          indicatorSize: TabBarIndicatorSize.tab,
          labelColor: colorScheme.primary,
          unselectedLabelColor: colorScheme.onSurface.withOpacity(0.6),
          labelStyle: TextStyle(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.bold,
              fontSize: 15),
          tabs: const [
            Tab(text: "Overview"),
            Tab(text: "Lectures"),
            Tab(text: "Analytics"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(context, _subject!, theme),
          _buildLecturesTab(context, _subject!, theme),
          const Center(
              child: Text(
                  "Analytics Tab View (Coming Next)")), //_buildAnalyticsTab(context, _subject!, '2026-05', theme),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(
      BuildContext context, Subject subject, ThemeData theme) {
    final colorScheme = theme.colorScheme;

    final overallStat = DatabaseService.getAttendance(_subject!.key, 'Overall');

    int presentCount = overallStat.presentCount;
    int totalCount = overallStat.totalCount;
    int absentCount = totalCount - presentCount;
    double overallAttendance =
        totalCount > 0 ? (presentCount / totalCount) * 100 : 0.0;

    int requiredLecture = DatabaseService.requiredLecture(
        subject.minAttend.toDouble(), totalCount, presentCount);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Overall Overview",
                  style: TextStyle(
                      color: colorScheme.onSurface,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          _buildAttendanceSummaryCard(
              attendancePercentage: overallAttendance,
              targetPercentage: _subject!.minAttend,
              requiredLecturesValue: requiredLecture,
              presentCount: presentCount,
              absentCount: absentCount,
              totalCount: totalCount,
              theme: theme),
          const SizedBox(height: 25),

          // C. MONTHLY OVERVIEW TRACKER SECTION
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Monthly Overview",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              TextButton(onPressed: () {}, child: const Text("View all")),
            ],
          ),
          const SizedBox(height: 10),
          if (_cacheMonthKeys.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 12.0),
              child: Center(
                  child: Text("No monthly data tracked yet.",
                      style: TextStyle(
                          color: colorScheme.onSurface.withOpacity(0.6)))),
            )
          else
            ..._cacheMonthKeys.map((monthKey) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10.0),
                child: _buildMonthlyProgressRow(theme, monthKey),
              );
            }),
          const SizedBox(height: 25),

          // D. RECENT HISTORY SHORTLIST VIEW
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Recent Lectures",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              TextButton(
                  onPressed: () => _tabController.animateTo(1),
                  child: const Text("View all")),
            ],
          ),
          const SizedBox(height: 10),
          if (_allLectures.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 12.0),
              child: Center(
                  child: Text("No monthly data tracked yet.",
                      style: TextStyle(
                          color: colorScheme.onSurface.withOpacity(0.6)))),
            )
          else
            ..._allLectures
                .take(3)
                .map((lecture) => _buildRecentLectureRow(lecture, theme)),
        ],
      ),
    );
  }

  Widget _buildStatMetricChip(
      String label, int value, Color color, ThemeData theme) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(12),
          border:
              Border.all(color: theme.colorScheme.onSurface.withOpacity(0.1)),
        ),
        child: Column(
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: 11,
                    color: theme.colorScheme.onSurface.withOpacity(0.9))),
            const SizedBox(height: 6),
            Text(
              value.toString(),
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlyProgressRow(ThemeData theme, String monthKey) {
    final stats = DatabaseService.getAttendance(_subject!.key, monthKey);
    double percentage =
        stats.totalCount > 0 ? stats.presentCount / stats.totalCount : 0.0;
    DateTime parsedDate = DateFormat('yyyy-MM').parse(monthKey);
    String month = DateFormat('MMM').format(parsedDate);

    return GestureDetector(
      onTap: () {
        print("$month tapped");
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          children: [
            SizedBox(
                width: 40,
                child: Text(month,
                    style: const TextStyle(fontWeight: FontWeight.w500))),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: percentage,
                  minHeight: 8,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
                ),
              ),
            ),
            const SizedBox(width: 15),
            SizedBox(
              width: 40,
              child: Text(
                "${(percentage * 100).toStringAsFixed(0)}%",
                textAlign: Alignment.centerRight.x > 0
                    ? TextAlign.end
                    : TextAlign.start,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentLectureRow(Lecture lecture, ThemeData theme) {
    Color statusColor = Colors.orangeAccent;
    if (lecture.status == 'Present') {
      statusColor = Colors.greenAccent.shade400;
    } else if (lecture.status == 'Absent') {
      statusColor = Colors.redAccent.shade200;
    }

    String dateStr = DateFormat('dd MMM, E').format(lecture.date);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: theme.hoverColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.onSurface.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(dateStr,
              style:
                  const TextStyle(fontWeight: FontWeight.w500, fontSize: 15)),
          Row(
            children: [
              Icon(Icons.circle, size: 10, color: statusColor),
              const SizedBox(width: 8),
              Text(lecture.status,
                  style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14)),
              const SizedBox(width: 8),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildAttendanceSummaryCard({
    required double attendancePercentage,
    required int targetPercentage,
    required int requiredLecturesValue,
    required int presentCount,
    required int absentCount,
    required int totalCount,
    required ThemeData theme,
  }) {
    final colorScheme = theme.colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. TOP MAIN SUMMARY BLOCK
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHigh,
            border:
                Border.all(color: theme.colorScheme.onSurface.withOpacity(0.1)),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              CustomCircleProgress(
                percentage: attendancePercentage,
                size: 120,
                strokeWidth: 12,
                fontSize: 30,
                showLabel: true,
                labelColor: (attendancePercentage > _subject!.minAttend ||
                        totalCount == 0)
                    ? colorScheme.onSurface
                    : Colors.orangeAccent,
                showSubLabel: true,
                subLabel: 'Overall',
                progressColor: Colors.greenAccent.shade400,
                emptyProgressColor: (totalCount != 0)
                    ? Colors.redAccent.shade200
                    : colorScheme.onSurface.withOpacity(0.1),
              ),
              const SizedBox(width: 65),

              // Text Details Insights Column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Present',
                      style: TextStyle(
                        color: colorScheme.onSurface.withOpacity(0.65),
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      "$presentCount lectures",
                      style: TextStyle(
                        color: Colors.greenAccent.shade400,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Absent",
                      style: TextStyle(
                        color: colorScheme.onSurface.withOpacity(0.65),
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      "$absentCount lectures",
                      style: TextStyle(
                        color: Colors.redAccent.shade200,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Total",
                      style: TextStyle(
                        color: colorScheme.onSurface.withOpacity(0.65),
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      "$totalCount lectures",
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
        const SizedBox(height: 12),

        // 2. COUNTER CHIP TILES ROW
        Row(
          children: [
            _buildStatMetricChip(
                "${(requiredLecturesValue < 0) ? 'Skippable' : 'Required'} Lectures",
                (requiredLecturesValue < 0)
                    ? -requiredLecturesValue
                    : requiredLecturesValue,
                (requiredLecturesValue < 0)
                    ? theme.colorScheme.onSurface
                    : Colors.orange.shade200,
                theme),
          ],
        ),
      ],
    );
  }

//------------------------------------------------

  Widget _buildLecturesTab(
      BuildContext context, Subject subject, ThemeData theme) {
    final colorScheme = theme.colorScheme;
    String _selectedStatusFilter = "All";
    final lectures = _selectedStatusFilter == "All"
        ? _allLectures
        : _allLectures.where((l) => l.status == _selectedStatusFilter).toList();

    return Scaffold(
      floatingActionButtonLocation: lectures.isNotEmpty
          ? FloatingActionButtonLocation.endFloat
          : FloatingActionButtonLocation.centerTop,
      floatingActionButton: Padding(
        padding: EdgeInsets.symmetric(
            horizontal: 10, vertical: lectures.isNotEmpty ? 10 : 300),
        child: SizedBox(
          width: 200,
          height: 55,
          child: FloatingActionButton.extended(
            backgroundColor: colorScheme.primary,
            elevation: 2,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            icon: Icon(Icons.add_rounded, color: colorScheme.onSurface),
            label: Text(
              "Add Extra Lecture",
              style: TextStyle(
                  color: colorScheme.onSurface,
                  fontSize: 16,
                  fontWeight: FontWeight.bold),
            ),
            onPressed: () {
              print('Floating button tapped');
            },
          ),
        ),
      ),
      body: Column(
        children: [
          // FILTER BAR
          Container(
            padding:
                const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
            height: 64,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [],
            ),
          ),

          // B. SCROLLABLE TIMELINE LIST
          Expanded(
            child: lectures.isEmpty
                ? Center(
                    child: Text(
                      "No $_selectedStatusFilter lectures recorded.",
                      style: const TextStyle(color: Colors.grey, fontSize: 15),
                    ),
                  )
                : ListView.builder(
                    padding:
                        const EdgeInsets.only(left: 16, right: 16, bottom: 90),
                    itemCount: lectures.length,
                    itemBuilder: (context, index) {
                      final lecture = lectures[index];

                      // Month Section Header grouping logic
                      bool showMonthHeader = false;
                      if (index == 0) {
                        showMonthHeader = true;
                      } else {
                        final prevLectureDate = lectures[index - 1].date;
                        if (lecture.date.month != prevLectureDate.month ||
                            lecture.date.year != prevLectureDate.year) {
                          showMonthHeader = true;
                        }
                      }

                      bool isLastCardInList = (index == lectures.length - 1);
                      bool isLast = false;
                      if (isLastCardInList) {
                        isLast = true;
                      } else {
                        final nextLecture = lectures[index + 1].date;

                        if (lecture.date.month != nextLecture.month ||
                            lecture.date.year != nextLecture.year) {
                          isLast = true;
                        }
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (showMonthHeader) ...[
                            Padding(
                              padding: const EdgeInsets.only(
                                  top: 16.0, bottom: 12.0, left: 4.0),
                              child: Text(
                                DateFormat('MMMM yyyy').format(lecture.date),
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onSurface.withOpacity(0.5),
                                ),
                              ),
                            ),
                          ],
                          _buildTimelineCardRow(
                              lecture, theme, index, lectures.length, isLast),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineCardRow(Lecture lecture, ThemeData theme, int index,
      int totalCount, bool isLast) {
    final status = lecture.status;
    final colorScheme = theme.colorScheme;

    Color statusColor = colorScheme.onSurface.withOpacity(0.6);
    IconData statusIcon = Icons.question_mark_rounded;
    if (status == 'Present') {
      statusColor = Colors.greenAccent.shade400;
      statusIcon = Icons.check_circle_rounded;
    } else if (status == "Absent") {
      statusColor = Colors.redAccent.shade200;
      statusIcon = Icons.cancel_rounded;
    } else if (status == "Cancelled") {
      statusColor = const Color.fromARGB(255, 211, 149, 67);
      statusIcon = Icons.timelapse_rounded;
    }

    final String dayStr = DateFormat('dd').format(lecture.date);
    final String monthStr =
        DateFormat('MMM').format(lecture.date).toUpperCase();

    final String timeString =
        "${lecture.startHour}:${lecture.startMinute.toString().padLeft(2, '0')} – ${lecture.endHour}:${lecture.endMinute.toString().padLeft(2, '0')}";

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // LEFT DATE & LINE PART
          TimelineIndicatorTrack(
            leftWidth: 45.0,
            showTopLine: true, // Hides top connector tracking line on entry #0
            showBottomLine: !isLast,
            lineColor: statusColor.withOpacity(
                0.2), // Track color maps nicely to your attendance states
            leftWidget: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(dayStr,
                    style:
                        TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                Text(monthStr,
                    style: TextStyle(
                        fontSize: 11,
                        color: colorScheme.onSurface.withOpacity(0.6),
                        fontWeight: FontWeight.bold)),
              ],
            ),
            indicatorNode: Icon(statusIcon, size: 22, color: statusColor),
          ),

          // 3. Right Side: Card Information Box
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        status,
                        style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Text(timeString,
                          style: TextStyle(
                              color: colorScheme.onSurface.withOpacity(0.4),
                              fontSize: 13)),
                    ],
                  ),
                  // Location Label Tag Box
                  Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 20,
                            color: colorScheme.onSurface.withOpacity(0.8),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "${(lecture.roomNo == '') ? '---' : lecture.roomNo}",
                            style: TextStyle(
                                color: theme.colorScheme.onSurface
                                    .withOpacity(0.8),
                                fontSize: 12,
                                fontWeight: FontWeight.w500),
                          ),
                        ],
                      )),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

//-------------------------------------------------------------------------
}
