import 'package:attendance_tracker/models/lecture.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
//  MODELS
import '../../models/subject.dart';
//  SCREENS
import '../subject/add_subject_screen.dart';
//  WIDGETS
import '../../widgets/percent_indicator.dart';
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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _subject = DatabaseService.getSubjectById(widget.subjectKey);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
          _buildOverviewTab(context, _subject!),
          _buildLecturesTab(context, _subject),
          const Center(child: Text("Analytics Tab View (Coming Next)")),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(BuildContext context, Subject subject) {
    final theme = Theme.of(context);
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
          _buildMonthlyProgressRow("May", 0.82, theme),
          _buildMonthlyProgressRow("Apr", 0.70, theme),
          _buildMonthlyProgressRow("Mar", 0.65, theme),
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
          _buildRecentLectureRow(
              "16 May, Thu", "Present", Colors.greenAccent.shade400),
          _buildRecentLectureRow(
              "14 May, Tue", "Absent", Colors.redAccent.shade200),
          _buildRecentLectureRow(
              "12 May, Sun", "Cancelled", Colors.orangeAccent),
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

  Widget _buildMonthlyProgressRow(
      String month, double percentage, ThemeData theme) {
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

  Widget _buildRecentLectureRow(
      String dateStr, String status, Color statusColor) {
    final theme = Theme.of(context);
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
              Text(status,
                  style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14)),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward_ios_rounded,
                  size: 14, color: Colors.grey),
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
                labelColor: (attendancePercentage < _subject!.minAttend)
                    ? Colors.orangeAccent
                    : colorScheme.onSurface,
                showSubLabel: true,
                subLabel: 'Overall',
                progressColor: Colors.greenAccent.shade400,
                emptyProgressColor: Colors.redAccent.shade200,
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

// Define this variable at the very top of your state class to hold the active filter:
  String _selectedFilter = "All";

  Widget _buildLecturesTab(BuildContext context, dynamic subject) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // 1. Fetch filtered history using your ultimate master engine!
    final lectures = DatabaseService.getLectures(
      subjectID: subject.key,
      statusFilter: _selectedFilter,
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      // Bottom Floating Action Button to add extra lectures seamlessly
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: FloatingActionButton.extended(
            backgroundColor: colorScheme.primary,
            elevation: 2,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            icon: const Icon(Icons.add_rounded, color: Colors.white),
            label: const Text(
              "Add Extra Lecture",
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold),
            ),
            onPressed: () {},
          ),
        ),
      ),
      body: Column(
        children: [
          // A. FILTER CHIPS CAROUSEL BAR
          Container(
            padding:
                const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
            height: 64,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildFilterChip("All", colorScheme.primary),
                const SizedBox(width: 8),
                _buildFilterChip("Present", Colors.greenAccent.shade400),
                const SizedBox(width: 8),
                _buildFilterChip("Absent", Colors.redAccent.shade200),
                const SizedBox(width: 8),
                _buildFilterChip("Cancelled", Colors.orangeAccent),
              ],
            ),
          ),

          // B. SCROLLABLE TIMELINE LIST
          Expanded(
            child: lectures.isEmpty
                ? Center(
                    child: Text(
                      "No $_selectedFilter lectures recorded.",
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
                          _buildTimelineCardRow(lecture, theme),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // Helper: Builds the interactive Filter Chip UI
  Widget _buildFilterChip(String label, Color activeColor) {
    final isSelected = _selectedFilter == label;
    final theme = Theme.of(context);

    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (bool selected) {
        if (selected) {
          setState(() {
            _selectedFilter =
                label; // Re-runs master function filter query automatically!
          });
        }
      },
      labelStyle: TextStyle(
        color: isSelected
            ? Colors.white
            : theme.colorScheme.onSurface.withOpacity(0.7),
        fontWeight: FontWeight.bold,
        fontSize: 13,
      ),
      selectedColor: activeColor.withOpacity(0.85),
      backgroundColor: theme.colorScheme.surfaceContainerLow,
      showCheckmark: false,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side:
            BorderSide(color: isSelected ? Colors.transparent : Colors.white10),
      ),
    );
  }

// Helper: Builds the individual timeline entry item row
  Widget _buildTimelineCardRow(Lecture lecture, ThemeData theme) {
    final status = lecture.status;

    Color statusColor = Colors.grey;
    IconData statusIcon = Icons.question_mark_rounded;
    if (status == 'Present') {
      statusColor = Colors.greenAccent.shade400;
      statusIcon = Icons.check_circle_rounded;
    } else if (status == "Absent") {
      statusColor = Colors.redAccent.shade200;
      statusIcon = Icons.cancel_rounded;
    } else if (status == "Cancelled") {
      statusColor = Colors.orangeAccent;
      statusIcon = Icons.timelapse_rounded;
    }

    final DateTime lectureDate = lecture.date ?? DateTime.now();
    final String dayStr = DateFormat('dd').format(lecture.date);
    final String monthStr =
        DateFormat('MMM').format(lecture.date).toUpperCase();

    final String startMinStr = lecture.startMinute.toString().padLeft(2, '0');
    final String endMinStr = lecture.endMinute.toString().padLeft(2, '0');
    final String timeString =
        "${lecture.startHour}:$startMinStr – ${lecture.endHour}:$endMinStr";

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Left Side: Date Display Block
          SizedBox(
            width: 45,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(dayStr,
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold)),
                Text(monthStr,
                    style: const TextStyle(
                        fontSize: 11,
                        color: Colors.grey,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ),

          // 2. Center Side: Continuous Timeline Tracking Track
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Column(
              children: [
                const SizedBox(height: 6),
                Icon(statusIcon, size: 20, color: statusColor),
                Expanded(
                  child: Container(
                    width: 2.5,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: statusColor
                        .withOpacity(0.3), // Keeps track connected downward
                  ),
                ),
              ],
            ),
          ),

          // 3. Right Side: Card Information Box
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerLow,
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
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 13)),
                    ],
                  ),
                  // Location Label Tag Box
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest
                          .withOpacity(0.4),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      "${(lecture.roomNo == '') ? '--' : lecture.roomNo}",
                      style: TextStyle(
                          color: theme.colorScheme.onSurface.withOpacity(0.8),
                          fontSize: 12,
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
