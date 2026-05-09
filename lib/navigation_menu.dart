import 'package:flutter/material.dart';
//  SCREENS
import '../screens/home_screen.dart';
import 'screens/timetable/timetable_screen.dart';
import '../screens/subject/subject_screen.dart';
import '../screens/calendar_screen.dart';
import '../screens/settings_screen.dart';
//------------------------------------------------------------------------------

class NavigationMenu extends StatefulWidget {
  const NavigationMenu({super.key});

  @override
  State<NavigationMenu> createState() => _NavigationMenuState();
}

class _NavigationMenuState extends State<NavigationMenu> {
  int _selectedIndex = 0;

  // List of screens
  final List<Widget> _screens = [
    const HomeScreen(), // Index 0
    const TimetableScreen(), // Index 1
    const SubjectScreen(), // Index 2
    AttendanceCalendar(), // Index 3
    const SettingsScreen(), // Index 4
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return PopScope(
        canPop: _selectedIndex == 0,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;
          if (_selectedIndex != 0) {
            setState(() {
              _selectedIndex = 0; // Switch to Home tab
            });
          }
        },
        child: Scaffold(
          body: _screens[_selectedIndex],
          bottomNavigationBar: BottomNavigationBar(
            selectedItemColor: colorScheme.primary,
            unselectedItemColor: colorScheme.onSurface,
            currentIndex: _selectedIndex,
            onTap: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_rounded),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.calendar_month_rounded), // Book/Subject icon
                label: 'Timetable',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.book_outlined),
                label: 'Subjects',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.calendar_month),
                label: 'Calendar',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.settings),
                label: 'Settings',
              ),
            ],
          ),
        ));
  }
}
