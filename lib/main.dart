import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/constants/app_strings.dart';
import 'core/theme/app_theme.dart';
import 'features/onboarding/presentation/screens/onboarding_screen.dart';
import 'features/reader/presentation/screens/home_screen.dart';
import 'features/settings/presentation/controllers/settings_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi SharedPreferences untuk persistensi lokal
  final sharedPreferences = await SharedPreferences.getInstance();
  final hasCompletedOnboarding =
      sharedPreferences.getBool('has_completed_onboarding') ?? false;

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
      ],
      child: LexiReadApp(hasCompletedOnboarding: hasCompletedOnboarding),
    ),
  );
}

/// Root widget aplikasi LexiRead
class LexiReadApp extends StatelessWidget {
  final bool hasCompletedOnboarding;

  const LexiReadApp({
    super.key,
    this.hasCompletedOnboarding = false,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: hasCompletedOnboarding
          ? const HomeScreen()
          : const OnboardingScreen(),
    );
  }
}
