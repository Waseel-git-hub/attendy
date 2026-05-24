import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../main.dart';
//  MODELS
//  SCREENS
//  SERVICE
import '../../services/backup_service.dart';
import '../../services/AppTheme.dart';
//  WIGDETS
import '../widgets/bug_sheet.dart';
//------------------------------------------------------------------------------

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
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
                    const SizedBox(height: 5),
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

          const Divider(),
          _buildSectionHeader("Data Management"),
          ListTile(
            leading: const Icon(Icons.backup),
            title: const Text("Backup Data"),
            subtitle: const Text("Backup all lectures and attendance stats"),
            onTap: () async {
              await BackupService.exportBackup();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Backup file ready to share!")),
              );
            },
          ),
          const SizedBox(height: 6),
          ListTile(
            leading: Icon(Icons.restore),
            title: Text('Restore Data'),
            subtitle: Text('Import existing lectures and attendance stats'),
            onTap: () async {
              bool success = await BackupService.importBackup();
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text("Database profile restored successfully!")),
                );
              }
            },
          ),

          const Divider(),
          _buildSectionHeader("About"),
          ListTile(
            leading: Icon(Icons.info_outline),
            title: const Text("Version"),
            trailing: Text("0.0.1"),
          ),
          ListTile(
            leading: Icon(Icons.dangerous, color: Colors.redAccent.shade200),
            title: const Text('Report'),
            subtitle: const Text('Reports bugs and give Feedback'),
            onTap: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                builder: (context) => const BugReportSheet(),
              );
            },
          )
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
}
