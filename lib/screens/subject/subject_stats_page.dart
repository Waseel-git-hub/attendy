import 'dart:ui' as ui;
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
//  MODELS
import '../../models/subject.dart';
import '../../models/lecture.dart';
//  SCREENS
import '../subject/add_subject_screen.dart';
//  WIDGETS
import '../../widgets/percent_indicator.dart';
import '../../widgets/timeline.dart';
import '../../widgets/extra_lecture_sheet.dart';
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

  String _selectedStatusFilter = "All";
  String? _selectedLecturesMonthKey;
  String _sortOrder = "Newest First";

  String? _selectedMonthKey; //2026-05

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
    final currentMonth = DateFormat('yyyy-MM').format(DateTime.now());
    final uniqueKeys = rawLectures
        .map((l) => DateFormat('yyyy-MM').format(l.date))
        .where((monthStr) => monthStr.compareTo(currentMonth) <= 0)
        .toSet()
        .toList();
    uniqueKeys.sort((a, b) => b.compareTo(a));

    setState(() {
      _allLectures = rawLectures;
      _cacheMonthKeys = uniqueKeys.toList();
    });
  }

  void _showAddExtraLectureSheet(
      BuildContext context, dynamic currentSubjectKey) async {
    // 1. Open the modal sheet
    final entrySaved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => AddExtraLectureSheet(
        subjectKey:
            currentSubjectKey, // Pre-selects this subject in the dropdown
        // initialDate is omitted here, so it automatically defaults to today's date!
      ),
    );

    // 2. Refresh your statistics metrics if a new class was logged
    if (entrySaved == true && mounted) {
      setState(() {});
    }
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
          'Subject Info',
          style: TextStyle(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.bold,
              fontSize: 22),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              final result = await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => AddSubjectScreen(subject: _subject),
                ),
              );
              if (result == true) {
                setState(() {});
              }
            },
          )
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: colorScheme.primary,
          indicatorSize: TabBarIndicatorSize.tab,
          labelColor: colorScheme.primary,
          unselectedLabelColor: colorScheme.onSurfaceVariant,
          labelStyle: TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
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
          _buildAnalyticsTab(context, _subject!, '2026-05', theme),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(
      BuildContext context, Subject subject, ThemeData theme) {
    final colorScheme = theme.colorScheme;

    int presentCount;
    int totalCount;
    int requiredLecture;
    bool isOverall = _selectedMonthKey == null;

    List<dynamic> displayLectures;

    if (isOverall) {
      final overallStat = DatabaseService.getAttendance(subject.key, 'Overall');
      presentCount = overallStat.presentCount;
      totalCount = overallStat.totalCount;
      requiredLecture = DatabaseService.requiredLecture(
          subject.minAttend.toDouble(), totalCount, presentCount);
      displayLectures = _allLectures.take(3).toList(); // Global short preview
    } else {
      final monthlyStat =
          DatabaseService.getAttendance(subject.key, _selectedMonthKey!);
      presentCount = monthlyStat.presentCount;
      totalCount = monthlyStat.totalCount;
      requiredLecture = DatabaseService.requiredLecture(
          subject.minAttend.toDouble(), totalCount, presentCount);

      // Filter your memory array to show ONLY lectures belonging to that specific month string
      displayLectures = _allLectures.where((lecture) {
        final String formatCheck = DateFormat('yyyy-MM').format(lecture.date);
        return formatCheck == _selectedMonthKey;
      }).toList();
    }

    int absentCount = totalCount - presentCount;
    double overallAttendance =
        totalCount > 0 ? (presentCount / totalCount) * 100 : 0.0;

    return PopScope(
      canPop: isOverall,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_selectedMonthKey != null) {
          setState(() {
            _selectedMonthKey = null;
          });
        }
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHigh,
                border: Border.all(color: theme.colorScheme.outlineVariant),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 1. LEFT SIDE: Squircle Icon Container with subtle tinted background
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      border: Border.all(
                          color: colorScheme.outlineVariant, width: 2),
                      color: Color(subject.colorValue)
                          .withOpacity(0.15), // Tinted background
                      borderRadius:
                          BorderRadius.circular(16), // Rounded square look
                    ),
                    child: Center(
                      child: Icon(
                        IconData(subject.iconCodePoint,
                            fontFamily: 'MaterialIcons'),
                        size: 50,
                        color: Color(subject
                            .colorValue), // Vibrant icon accent matching chosen color
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),

                  // 2. RIGHT SIDE: Subject Text Details Hierarchy
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Subject Code/Short Name (e.g., Chem)
                        Center(
                          child: Text(
                            subject.name,
                            style: TextStyle(
                              color: colorScheme.onSurface,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),

                        const SizedBox(height: 8),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Minimum \nAttendance",
                              style: TextStyle(
                                color: colorScheme.onSurfaceVariant,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(width: 12),
                            Text(
                              ':',
                              style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w500,
                                  color: colorScheme.onSurfaceVariant),
                            ),
                            SizedBox(width: 12),
                            Text(
                              "${subject.minAttend}%",
                              style: TextStyle(
                                color: Color(subject.colorValue),
                                fontSize: 22,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _selectedMonthKey == null
                      ? "Overall Overview"
                      : // "May Breakdown"
                      "${DateFormat('MMMM').format(DateFormat('yyyy-MM').parse(_selectedMonthKey!))} Overview",
                  style: TextStyle(
                      color: colorScheme.onSurface,
                      fontSize: 20,
                      fontWeight: FontWeight.w600),
                ),
                if (!isOverall)
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _selectedMonthKey =
                            null; // Step back to parent view container
                      });
                    },
                    icon: const Icon(Icons.clear_rounded, size: 16),
                    label: const Text("Reset View"),
                    style: TextButton.styleFrom(
                      foregroundColor: colorScheme.onPrimaryContainer,
                      backgroundColor: colorScheme.primaryContainer,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 12),
            _buildAttendanceSummaryCard(
                attendancePercentage: overallAttendance,
                targetPercentage: _subject!.minAttend,
                requiredLecturesValue: requiredLecture,
                presentCount: presentCount,
                absentCount: absentCount,
                totalCount: totalCount,
                theme: theme),
            const SizedBox(height: 24),

            // C. MONTHLY OVERVIEW TRACKER SECTION
            if (isOverall) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Monthly Overview",
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 12),
              if (_cacheMonthKeys.isEmpty)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 12.0),
                  child: Center(
                      child: Text("No monthly data tracked yet.",
                          style:
                              TextStyle(color: colorScheme.onSurfaceVariant))),
                )
              else
                ..._cacheMonthKeys.map((monthKey) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10.0),
                    child: _buildMonthlyProgressRow(theme, monthKey),
                  );
                }),
              const SizedBox(height: 4),
            ],

            // D. RECENT HISTORY SHORTLIST VIEW
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Recent Lectures",
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
                TextButton.icon(
                  onPressed: () => _tabController.animateTo(1),
                  label: const Text("View all"),
                  icon: const Icon(Icons.view_headline_rounded, size: 16),
                  style: TextButton.styleFrom(
                    foregroundColor: colorScheme.onPrimaryContainer,
                    backgroundColor: colorScheme.primaryContainer,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ),
            if (_allLectures.isEmpty)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 12.0),
                child: Center(
                    child: Text("No monthly data tracked yet.",
                        style: TextStyle(color: colorScheme.onSurfaceVariant))),
              )
            else
              ...displayLectures
                  .take(3)
                  .map((lecture) => _buildRecentLectureRow(lecture, theme)),
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
      behavior: HitTestBehavior.opaque,
      onTap: () {
        setState(() {
          _selectedMonthKey = monthKey;
        });
      },
      child: Container(
        decoration: BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(12)),
            color: theme.colorScheme.surfaceContainerLow,
            border: BoxBorder.all(
              color: theme.colorScheme.outlineVariant,
            )),
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            const SizedBox(width: 6),
            SizedBox(
                width: 40,
                child: Text(month,
                    style: const TextStyle(fontWeight: FontWeight.w500))),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: percentage,
                  minHeight: 6,
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
            SizedBox(
              width: 40,
              child: Icon(Icons.keyboard_arrow_right),
            )
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
    final colorScheme = theme.colorScheme;

    String dateStr = DateFormat('dd MMM, E').format(lecture.date);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            dateStr,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 16,
            ),
          ),
          Row(
            children: [
              Icon(Icons.circle, size: 12, color: statusColor),
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
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerLow,
            border: Border.all(color: theme.colorScheme.outlineVariant),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              const SizedBox(width: 12),
              CustomCircleProgress(
                percentage: attendancePercentage,
                size: 120,
                strokeWidth: 12,
                fontSize: 30,
                showLabel: true,
                labelColor: (attendancePercentage > _subject!.minAttend ||
                        totalCount == 0)
                    ? colorScheme.onSurface
                    : Colors.orangeAccent, // TODO: Orange color
                showSubLabel: true,
                subLabel: 'Overall',
                progressColor: colorScheme.primary,
                emptyProgressColor: (totalCount != 0)
                    ? Colors.redAccent.shade200 // TODO: Red color
                    : colorScheme.surfaceContainerHigh,
              ),
              const SizedBox(width: 24),

              // Text Details Insights Column
              Expanded(
                  child: Center(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Present',
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 14,
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
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 14,
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
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 14,
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
              ))
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 2. COUNTER CHIP TILES ROW
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: theme.colorScheme.outlineVariant),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                        "${(requiredLecturesValue < 0) ? 'Skippable' : 'Required'} Lectures",
                        style: TextStyle(
                            fontSize: 16,
                            color: theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500)),
                    const SizedBox(width: 16),
                    Text(
                      ((requiredLecturesValue < 0)
                              ? -requiredLecturesValue
                              : requiredLecturesValue)
                          .toString(),
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: (requiredLecturesValue < 0)
                              ? theme.colorScheme.onSurface
                              : Colors.orange.shade200),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

//------------------------------------------------

  Widget _buildLecturesTab(
      BuildContext context, Subject subject, ThemeData theme) {
    final colorScheme = theme.colorScheme;

    final DateTime? parsedFilterMonth = _selectedLecturesMonthKey != null
        ? DateFormat('yyyy-MM').parse(_selectedLecturesMonthKey!)
        : null;

    final lectures = _allLectures.where((lecture) {
      if (_selectedStatusFilter != "All") {
        final dbStatus = _selectedStatusFilter == "Unmarked"
            ? "not marked"
            : _selectedStatusFilter.toLowerCase();
        if (lecture.status.toLowerCase() != dbStatus) return false;
      }
      // 2. Apply Month Filter
      if (_selectedLecturesMonthKey != null) {
        final String lectureMonth = DateFormat('yyyy-MM').format(lecture.date);
        if (lectureMonth != _selectedLecturesMonthKey) return false;
      }

      return true;
    }).toList();

    // 3. Apply Sorting Order
    if (_sortOrder == "Oldest First") {
      lectures.sort((a, b) => a.date.compareTo(b.date));
    } else {
      lectures.sort((a, b) => b.date.compareTo(a.date));
    }

    void showFilterSheet(
        BuildContext context, ThemeData theme, dynamic subjectID) {
      String tempStatus = _selectedStatusFilter;
      String? tempMonth = _selectedLecturesMonthKey;
      String tempSort = _sortOrder;

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        builder: (context) {
          return StatefulBuilder(
            builder: (BuildContext context, StateSetter setModalState) {
              return Padding(
                padding: const EdgeInsets.symmetric(
                    vertical: 20.0, horizontal: 20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top drag handlebar line indicator
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                            color: colorScheme.onSurfaceVariant,
                            borderRadius: BorderRadius.circular(2)),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "Filter Lectures",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // SECTION 1: STATUS CHIPS
                    Text(
                      "Status",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: ["All", "Present", "Absent", "Unmarked"]
                          .map((status) {
                        final isSelected = tempStatus == status;
                        return ChoiceChip(
                          label: Text(status),
                          selected: isSelected,
                          onSelected: (_) =>
                              setModalState(() => tempStatus = status),
                          selectedColor: colorScheme.primaryContainer,
                          backgroundColor: colorScheme.surfaceContainerLow,
                          labelStyle: TextStyle(
                              color: isSelected
                                  ? colorScheme.onPrimaryContainer
                                  : colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide.none),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),

                    // SECTION 2: MONTH SELECTION CHIPS
                    Text(
                      "Month",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          ChoiceChip(
                            label: const Text("All Months"),
                            selected: tempMonth == null,
                            onSelected: (_) =>
                                setModalState(() => tempMonth = null),
                            selectedColor: colorScheme.primaryContainer,
                            backgroundColor: colorScheme.surfaceContainerLow,
                            labelStyle: TextStyle(
                                color: tempMonth == null
                                    ? colorScheme.onPrimaryContainer
                                    : colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w600),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide.none),
                          ),
                          ..._cacheMonthKeys.map((monthKey) {
                            final isSelected = tempMonth == monthKey;
                            final parsedName = DateFormat('MMM yyyy')
                                .format(DateFormat('yyyy-MM').parse(monthKey));
                            return Padding(
                              padding: const EdgeInsets.only(left: 8.0),
                              child: ChoiceChip(
                                label: Text(parsedName),
                                selected: isSelected,
                                onSelected: (_) =>
                                    setModalState(() => tempMonth = monthKey),
                                selectedColor: colorScheme.primaryContainer,
                                backgroundColor:
                                    colorScheme.surfaceContainerLow,
                                labelStyle: TextStyle(
                                    color: isSelected
                                        ? colorScheme.onPrimaryContainer
                                        : colorScheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w600),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    side: BorderSide.none),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // SECTION 3: SORT ENGINE SELECTION CONTROL
                    Text(
                      "Sort By",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      children: ["Newest First", "Oldest First"].map((order) {
                        final isSelected = tempSort == order;
                        return ChoiceChip(
                          label: Text(order),
                          selected: isSelected,
                          onSelected: (_) =>
                              setModalState(() => tempSort = order),
                          selectedColor: colorScheme.primaryContainer,
                          backgroundColor: colorScheme.surfaceContainerLow,
                          labelStyle: TextStyle(
                              color: isSelected
                                  ? colorScheme.onPrimaryContainer
                                  : colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide.none),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 28),

                    // SECTION 4: ACTIONS SEGMENT CONTROL BUTTON ROW
                    Row(
                      children: [
                        Expanded(
                          child: TextButton.icon(
                            style: TextButton.styleFrom(
                              backgroundColor: colorScheme.surfaceContainerHigh,
                              foregroundColor: colorScheme.onSurfaceVariant,
                            ),
                            onPressed: () {
                              setState(() {
                                _selectedStatusFilter = "All";
                                _selectedLecturesMonthKey = null;
                                _sortOrder = "Newest First";
                              });
                              Navigator.pop(context);
                            },
                            label: const Text(
                              "Reset",
                              style: TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 14),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colorScheme.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            onPressed: () {
                              setState(() {
                                _selectedStatusFilter = tempStatus;
                                _selectedLecturesMonthKey = tempMonth;
                                _sortOrder = tempSort;
                              });
                              Navigator.pop(context);
                            },
                            child: const Text(
                              "Apply",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      );
    }

    return Scaffold(
      //TODO: Button
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
            foregroundColor: Colors.white,
            elevation: 2,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            icon: const Icon(Icons.add_rounded),
            label: const Text(
              "Add Extra Lecture",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            onPressed: () {
              _showAddExtraLectureSheet(context, _subject!.key);
            },
          ),
        ),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding:
                const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: colorScheme.outlineVariant, width: 1),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Active filters summary pill indicator
                Expanded(
                  child: Row(
                    children: [
                      Icon(Icons.tune_rounded,
                          size: 16, color: colorScheme.primary),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          _selectedLecturesMonthKey == null
                              ? "All History"
                              : DateFormat('MMMM yyyy')
                                  .format(parsedFilterMonth!),
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurfaceVariant),
                        ),
                      ),
                      if (_selectedStatusFilter != "All") ...[
                        Text(" • ",
                            style:
                                TextStyle(color: colorScheme.onSurfaceVariant)),
                        Text(
                          _selectedStatusFilter,
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _selectedStatusFilter == "Present"
                                  ? Colors.greenAccent
                                  : _selectedStatusFilter == "Absent"
                                      ? Colors.redAccent
                                      : Colors.amberAccent),
                        ),
                      ],
                    ],
                  ),
                ),

                // Interactive Filter Sheet Trigger Button
                InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => showFilterSheet(context, theme, subject.key),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    decoration: BoxDecoration(
                      border: Border.all(color: colorScheme.outlineVariant),
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text("Filter",
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onPrimaryContainer)),
                        const SizedBox(width: 6),
                        Icon(Icons.keyboard_arrow_down_rounded,
                            size: 20, color: colorScheme.onPrimaryContainer),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // B. SCROLLABLE TIMELINE LIST
          Expanded(
            child: lectures.isEmpty
                ? Center(
                    child: Text(
                      "No lectures recorded.",
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
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
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: colorScheme.onSurfaceVariant,
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

    Color statusColor = colorScheme.onSurfaceVariant;
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
                Text(
                  monthStr,
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.bold,
                  ),
                ),
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
                  color: theme.colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: colorScheme.outlineVariant)),
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
                            fontWeight: FontWeight.w600,
                            fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Text(timeString,
                          style: TextStyle(
                              color: colorScheme.onSurfaceVariant,
                              fontSize: 13)),
                    ],
                  ),
                  // Location Label Tag Box
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(12),
                        border:
                            BoxBorder.all(color: colorScheme.outlineVariant)),
                    child: Column(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 16,
                          color: colorScheme.onSurface,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          //TODO : Room No. Default
                          (lecture.roomNo == 'Not Specified')
                              ? '---'
                              : "$lecture.roomNo",
                          style: TextStyle(
                              color: theme.colorScheme.onSurface,
                              fontSize: 12,
                              fontWeight: FontWeight.w500),
                        ),
                      ],
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

//-------------------------------------------------------------------------

  //  Sorry but aukaat ke bahr h iska theme sahi krna 🙂
  Widget _buildAnalyticsTab(
      BuildContext context, Subject subject, String monthKey, ThemeData theme) {
    final colorScheme = theme.colorScheme;
    final List<Map<String, dynamic>> trendData = [];

    for (String mKey in _cacheMonthKeys.reversed.toList()) {
      final monthlyStat = DatabaseService.getAttendance(subject.key, mKey);

      final int mTotal = monthlyStat.totalCount;
      final int mAttended = monthlyStat.presentCount;

      final double ratio = mTotal > 0
          ? double.parse((mAttended / mTotal).toStringAsFixed(2))
          : 0.0;

      // Map "2026-05" into a friendly display name like "May"
      DateTime parsedDate = DateFormat('yyyy-MM').parse(mKey);
      String shortLabel = DateFormat('MMM').format(parsedDate);

      trendData.add({
        "month": shortLabel,
        "ratio": ratio,
      });
    }

    // 3. Render a single clean structure
    if (trendData.isEmpty) {
      return Center(
        child: Text(
          "Not enough analytical history recorded yet.",
          style: TextStyle(
              color: colorScheme.onSurface.withOpacity(0.5), fontSize: 15),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: colorScheme.outlineVariant)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Attendance Trend",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),

              // 📊 Hooked completely up to localized trend data!
              CustomLineChart(dataPoints: trendData),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class CustomLineChart extends StatelessWidget {
  final List<Map<String, dynamic>> dataPoints;

  const CustomLineChart({super.key, required this.dataPoints});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        SizedBox(
          height: 180,
          width: double.infinity,
          child: CustomPaint(
            painter: LineGraphPainter(
                data: dataPoints,
                accentColor: theme.colorScheme.primary,
                theme: theme),
          ),
        ),
      ],
    );
  }
}

class LineGraphPainter extends CustomPainter {
  final List<Map<String, dynamic>> data;
  final Color accentColor;
  final ThemeData theme;
  LineGraphPainter(
      {required this.data, required this.accentColor, required this.theme});

  @override
  void paint(Canvas canvas, Size size) {
    final colorScheme = theme.colorScheme;
    if (data.isEmpty) return;
    final textPainter = TextPainter(textDirection: ui.TextDirection.ltr);

    final double paddingLeft = 40.0;
    final double paddingRight = 20.0;
    final double paddingTop =
        25.0; // Extra padding headroom for point percentage tags
    final double paddingBottom = 25.0;

    final double chartWidth = size.width - paddingLeft - paddingRight;
    final double chartHeight = size.height - paddingTop - paddingBottom;

    // A. DRAW BACKGROUND GRID LINES
    final int gridDivisions = 4;
    final Paint gridPaint = Paint()
      ..color = colorScheme.onSurface.withOpacity(0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (int i = 0; i <= gridDivisions; i++) {
      double ratio = i / gridDivisions;
      double y = paddingTop + chartHeight * (1 - ratio);

      canvas.drawLine(
        Offset(paddingLeft, y),
        Offset(size.width - paddingRight, y),
        gridPaint,
      );

      textPainter.text = TextSpan(
        text: "${(ratio * 100).round()}%",
        style: TextStyle(
            color: colorScheme.onSurface.withOpacity(0.5), fontSize: 10),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(0, y - textPainter.height / 2));
    }

    // B. CALCULATE X & Y PLOTTING POINTS
    // 🛠️ FIX: Safe handling of single data point edge-cases to prevent division-by-zero crashes
    double stepX = data.length > 1 ? chartWidth / (data.length - 1) : 0.0;
    List<Offset> points = [];

    for (int i = 0; i < data.length; i++) {
      // If there's only 1 point, position it right in the horizontal center of the chart space
      double x = data.length > 1
          ? paddingLeft + (i * stepX)
          : paddingLeft + (chartWidth / 2);

      double valueRatio = data[i]["ratio"] ?? 0.0;
      double y = paddingTop + chartHeight * (1 - valueRatio);
      points.add(Offset(x, y));
    }

// C. DRAW CONNECTING TREND LINE
    final Paint linePaint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    if (points.length > 1) {
      final Path path = Path()..moveTo(points.first.dx, points.first.dy);
      for (int i = 1; i < points.length; i++) {
        path.lineTo(points[i].dx, points[i].dy);
      }
      canvas.drawPath(path, linePaint);
    } else if (points.length == 1) {
      final Paint singlePointLinePaint = Paint()
        ..color = accentColor.withOpacity(.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      canvas.drawLine(
        Offset(paddingLeft, points.first.dy),
        Offset(size.width - paddingRight, points.first.dy),
        singlePointLinePaint,
      );
    }
    // D. DRAW LABELS & DOT NODES
    final Paint dotOuterPaint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.fill;
    final Paint dotInnerPaint = Paint()
      ..color = colorScheme.surfaceContainerHigh
      ..style = PaintingStyle.fill;

    for (int i = 0; i < points.length; i++) {
      final offset = points[i];
      final int rawPercent = ((data[i]["ratio"] ?? 0.0) * 100).round();

      // Outer & Inner rings for hollow dot alignment
      canvas.drawCircle(offset, 5.0, dotOuterPaint);
      canvas.drawCircle(offset, 2.5, dotInnerPaint);

      // Percentage numbers directly above nodes
      textPainter.text = TextSpan(
        text: "$rawPercent%",
        style: TextStyle(
            color: colorScheme.onSurface,
            fontSize: 11,
            fontWeight: FontWeight.bold),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(offset.dx - textPainter.width / 2, offset.dy - 18),
      );

      // Month text labels directly below
      final bool isLastItem = (i == data.length - 1);
      textPainter.text = TextSpan(
        text: data[i]["month"],
        style: TextStyle(
          color:
              isLastItem ? accentColor : colorScheme.onSurface.withOpacity(0.7),
          fontSize: 11,
          fontWeight: isLastItem ? FontWeight.bold : FontWeight.normal,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(offset.dx - textPainter.width / 2,
            size.height - textPainter.height),
      );
    }
  }

  @override
  bool shouldRepaint(covariant LineGraphPainter oldDelegate) {
    return oldDelegate.data != data || oldDelegate.accentColor != accentColor;
  }
}
