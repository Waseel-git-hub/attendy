import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../main.dart';
import 'package:package_info_plus/package_info_plus.dart';
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
            leading: const Icon(Icons.backup_outlined),
            title: const Text("Export Data"),
            subtitle:
                const Text("Share full backup or clean timetable template"),
            onTap: () {
              showModalBottomSheet(
                context: context,
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                builder: (context) {
                  return SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 20, horizontal: 16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            child: Text(
                              "Choose Export Mode",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color:
                                    Theme.of(context).colorScheme.onBackground,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Option 1: Full Backup
                          ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Theme.of(context)
                                  .colorScheme
                                  .primaryContainer,
                              child: Icon(Icons.storage,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onPrimaryContainer),
                            ),
                            title: const Text("Full Personal Backup"),
                            subtitle: const Text(
                                "Exports everything—including marked history, leaves, and percentages."),
                            onTap: () async {
                              Navigator.pop(context); // Close sheet
                              try {
                                await BackupService.exportBackup(
                                    structureOnly: false);
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text("Export failed: $e")),
                                );
                              }
                            },
                          ),
                          const Divider(height: 16, indent: 72),

                          // Option 2: Clean Structure Template
                          ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Theme.of(context)
                                  .colorScheme
                                  .secondaryContainer,
                              child: Icon(Icons.calendar_view_week,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSecondaryContainer),
                            ),
                            title: const Text("Clean Structure Template"),
                            subtitle: const Text(
                                "Keeps timetable, extra classes, and holidays, but resets all marks to 'Not Marked'."),
                            onTap: () async {
                              Navigator.pop(context); // Close sheet
                              try {
                                await BackupService.exportBackup(
                                    structureOnly: true);
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text("Export failed: $e")),
                                );
                              }
                            },
                          ),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  );
                },
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
          FutureBuilder<PackageInfo>(
            future: PackageInfo.fromPlatform(),
            builder: (context, snapshot) {
              String versionText = "Cannot Load Version";

              if (snapshot.hasData) {
                versionText =
                    "Beta v${snapshot.data!.version}.${snapshot.data!.buildNumber}";
              }

              return ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text("Version"),
                trailing: Text(
                  versionText,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            },
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
