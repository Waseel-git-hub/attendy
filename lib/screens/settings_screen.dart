import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../main.dart';
//  MODELS
//  SCREENS
//  SERVICE
import '../../services/AppTheme.dart';
//  WIGDETS
//------------------------------------------------------------------------------

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  double _minAttendance = 75.0; // Default

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Settings")),
      body: ListView(
        children: [
          // Inside SettingsScreen ListView
          _buildSectionHeader("Personalization"),
          const SizedBox(height: 16),

          ValueListenableBuilder<ThemeMode>(
            valueListenable: themeNotifier,
            builder: (context, currentMode, child) {
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Theme Mode",
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: SegmentedButton<ThemeMode>(
                        segments: const [
                          ButtonSegment(
                            value: ThemeMode.system,
                            icon: Icon(Icons.settings_suggest_outlined),
                            label: Text("System"),
                          ),
                          ButtonSegment(
                            value: ThemeMode.light,
                            icon: Icon(Icons.light_mode_outlined),
                            label: Text("Light"),
                          ),
                          ButtonSegment(
                            value: ThemeMode.dark,
                            icon: Icon(Icons.dark_mode_outlined),
                            label: Text("Dark"),
                          ),
                        ],
                        selected: {currentMode},
                        onSelectionChanged: (Set<ThemeMode> newSelection) {
                          final selectedMode = newSelection.first;
                          themeNotifier.value = selectedMode;
                          try {
                            var box = Hive.box('settingsBox');
                            box.put('themeMode', selectedMode.index);
                          } catch (e) {
                            debugPrint("Hive Error: $e");
                          }
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          ListTile(
            title: const Text("Accent Color"),
            trailing: CircleAvatar(
              backgroundColor: AppTheme().appAccentColor,
              radius: 15,
            ),
            onTap: () {},
          ),
          _buildSectionHeader("Academic Goals"),
          ListTile(
            title: const Text("Minimum Attendance Target"),
            subtitle: Text("${_minAttendance.toInt()}%"),
            trailing: SizedBox(
              width: 150,
              child: Slider(
                value: _minAttendance,
                min: 50,
                max: 100,
                divisions: 10,
                label: "${_minAttendance.toInt()}%",
                onChanged: (value) {
                  setState(() => _minAttendance = value);
                  // Save this value to SharedPreferences/Hive here
                },
              ),
            ),
          ),
          const Divider(),
          _buildSectionHeader("Data Management"),
          ListTile(
            leading: const Icon(Icons.delete_sweep, color: Colors.redAccent),
            title: const Text("Reset All Data"),
            subtitle: const Text("Clear all lectures and attendance stats"),
            onTap: () => _showResetDialog(),
          ),
          const Divider(),
          _buildSectionHeader("About"),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text("Version"),
            trailing: Text("1.0.0"),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.blueAccent,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  void _showResetDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Are you sure?"),
        content: const Text("This will permanently delete all your records."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              // Call your DatabaseService.clearAllData() logic
              Navigator.pop(context);
            },
            child:
                const Text("Reset", style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }
}
