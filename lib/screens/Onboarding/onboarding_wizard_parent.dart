import 'package:flutter/material.dart';
import '../../models/DTO/draft.dart';
import '../../services/database_service.dart';
import '../../screens/router.dart';
import '../Onboarding/semester_page.dart';
import '../../screens/timetable/timetable_setup.dart';
import '../Onboarding/subject_page.dart';
import '../../services/backup_service.dart';

class OnboardingWizardParent extends StatefulWidget {
  const OnboardingWizardParent({Key? key}) : super(key: key);

  @override
  State<OnboardingWizardParent> createState() => _OnboardingWizardParentState();
}

class _OnboardingWizardParentState extends State<OnboardingWizardParent> {
  final PageController _pageController = PageController();
  final SetupDraft _setupDraft = SetupDraft();
  int _currentStepIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _navigateToStep(int stepIndex) {
    setState(() {
      _currentStepIndex = stepIndex;
    });
    _pageController.animateToPage(
      stepIndex,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _handleFinalCommit() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await DatabaseService.commitInitialSetup(_setupDraft);

      if (!mounted) return;
      Navigator.pop(context); // Close loading spinner safe window context

      // Clear out layout historical stack frames and force reload the root application tree
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const RootRouter()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close spinner tracking context frame

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Failed to save configuration database tracking logs: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return PopScope(
      // 💡 Crucial: Block native pop if we are deep inside the wizard steps
      canPop: _currentStepIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;

        if (_currentStepIndex > 0) {
          _navigateToStep(_currentStepIndex - 1);
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              // Visual Step Progress Bar indicator line loop block
              LinearProgressIndicator(
                value: (_currentStepIndex) / 3,
                backgroundColor: colorScheme.surfaceVariant,
                color: colorScheme.primary,
              ),

              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics:
                      const NeverScrollableScrollPhysics(), // Enforce validation routing steps
                  children: [
                    _buildIntroPage(theme),
                    OnboardingSubjectsSetupScreen(
                      setupDraft: _setupDraft,
                      onNext: () => _navigateToStep(2),
                    ),
                    SetupTimetableScreen(
                      setupDraft: _setupDraft,
                      isFromOnboarding: true,
                      onNext: () => _navigateToStep(3),
                      onBack: () => _navigateToStep(1),
                    ),
                    OnboardingSemesterSetupScreen(
                      setupDraft: _setupDraft,
                      onComplete: _handleFinalCommit,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIntroPage(ThemeData theme) {
    final colorScheme = theme.colorScheme;
    final bool isReturningUser = DatabaseService.hasAnySemesterHistory();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),
          ShaderMask(
            // 1. Define the gradient shape and directions
            shaderCallback: (Rect bounds) {
              return LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  colorScheme.primary,
                  colorScheme.tertiary, // A second theme color for blending
                ],
              ).createShader(bounds);
            },
            // 2. Set the blend mode so it only highlights the visible parts of the asset
            blendMode: BlendMode.srcIn,

            // 3. Place your icon or image asset as the child
            child: isReturningUser
                ? const Icon(
                    Icons.celebration_rounded,
                    size: 120,
                  )
                : Image.asset(
                    'assets/images/ic_launcher_monochrome.png',
                    width: 120,
                    height: 120,
                  ),
          ),
          const SizedBox(height: 32),
          Text(
            isReturningUser ? 'Semester Completed!' : 'Welcome to Attendy',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            isReturningUser
                ? 'Your previous semester has ended. Let\'s get you set up for the new one! You can start completely fresh or import existing copy.'
                : 'Keep your college attendance on track effortlessly. Set up your semester timetable to get started.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onSurface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.arrow_forward_rounded),
                label: Text(
                  isReturningUser ? 'Set Up New Semester' : 'Get Started',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
                onPressed: () {
                  _setupDraft.reset();
                  _navigateToStep(1);
                },
              ),
              const SizedBox(height: 14),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  backgroundColor: colorScheme.surfaceContainerLow,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(color: theme.colorScheme.outlineVariant),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.history_toggle_off_rounded),
                label: const Text(
                  'Import Existing Structure',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                onPressed: () {
                  BackupService.importBackup();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
