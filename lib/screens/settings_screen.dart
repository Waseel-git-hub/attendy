import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../main.dart';
//  MODELS
//  SCREENS
//  SERVICE
import '../../services/backup_service.dart';
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Settings",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: ListView(
        children: [
          _buildSectionHeader("Personalization", colorScheme.primary),
          const SizedBox(height: 4),
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
          const Divider(),
          _buildSectionHeader("Data Management", colorScheme.primary),
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
          _buildSectionHeader("About", colorScheme.primary),
          ListTile(
            leading: Icon(Icons.info_outline),
            title: const Text("Version"),
            trailing: Text(
              "Beta 0.0.8",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
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

  Widget _buildSectionHeader(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 16,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
