import 'package:flutter/material.dart';
//  MODELS
//  SCREENS
import '../navigation_menu.dart';
import 'Onboarding/onboarding_wizard_parent.dart';
//  SERVICES
import '../services/database_service.dart';
//  WIGDETS
//------------------------------------------------------------------------------

class RootRouter extends StatelessWidget {
  const RootRouter({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool isSetupComplete = DatabaseService.hasActiveSemester();

    if (isSetupComplete) {
      return NavigationMenu();
    } else {
      // If no active semester exists, automatically launch the onboarding flow
      return OnboardingWizardParent();
    }
  }
}
