import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:hive_flutter/hive_flutter.dart';
//  MODELS
import '../models/lecture.dart';
//  SCREENS
//  SERVICES
import '../services/database_service.dart';
//  WIGDETS
import '../widgets/lecture_card.dart';
//------------------------------------------------------------------------------

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DateTime _selectedDate = DateTime.now();

  List<DateTime> _getWeekDates() {
    DateTime now = DateTime.now();
    DateTime lastSunday = now.subtract(Duration(days: (now.weekday % 7) - 1));
    return List.generate(7, (index) => lastSunday.add(Duration(days: index)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildHeader(),
          _buildDateSelector(),
          _buildLectureList(),
        ],
      ),
    );
  }

  // 2. Date Picker: Horizontal list from bottom image
  Widget _buildDateSelector() {
    final weekDates = _getWeekDates();
    return SliverToBoxAdapter(
      child: Container(
        height: 75,
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: 7,
          itemBuilder: (context, index) {
            final date = weekDates[index];
            bool isSelected = date.day == _selectedDate.day;
            return GestureDetector(
              onTap: () => setState(() => _selectedDate = date),
              child: Container(
                width: 50,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  border: Border.all(
                      color: Theme.of(context).colorScheme.onSurface,
                      width: 0.2),
                  boxShadow: [
                    BoxShadow(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.3)),
                  ],
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(DateFormat('EEE').format(date).toUpperCase(),
                        style: TextStyle(
                            color: isSelected ? Colors.white : Colors.white38,
                            fontSize: 12)),
                    Text("${date.day}",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
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
            DatabaseService.getLecturesForDate(_selectedDate);

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
                      // 1. Time Display (e.g., 09:00)
                      _buildTimeColumn(lecture),

                      // 2. The Vertical Timeline Bar
                      _buildTimelineBar(Theme.of(context).colorScheme.primary,
                          index == lectures.length - 1),

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
        lecture.startHour.toString() + ":" + lecture.startMinute.toString();
    String endTime =
        lecture.endHour.toString() + ":" + lecture.endMinute.toString();
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

  Widget _buildTimelineBar(Color color, bool isLast) {
    return Column(
      children: [
        Container(
            width: 2,
            height: 90,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.15)),
        // The colored node
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: color.withOpacity(0.3), width: 4),
          ),
        ),
        // The line segment below the dot (extends to the next item)
        Expanded(
          child: Container(
            width: 2,
            color: isLast
                ? Colors.transparent
                : Theme.of(context).colorScheme.onSurface.withOpacity(0.15),
          ),
        ),
      ],
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
}
