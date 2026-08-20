import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/persistence/shared_preferences_provider.dart';
import 'core/theme/app_theme.dart';
import 'features/home/ui/home_page.dart';
import 'features/onboarding/state/onboarding_controller.dart';
import 'features/onboarding/ui/onboarding_page.dart';
import 'features/settings/state/theme_mode_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  final SharedPreferences prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const AphanesApp(),
    ),
  );
}

class AphanesApp extends ConsumerWidget {
  const AphanesApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeMode? chosen = ref.watch(themeModeControllerProvider);
    final Brightness effective =
        chosen == ThemeMode.light
            ? Brightness.light
            : chosen == ThemeMode.dark
            ? Brightness.dark
            : MediaQuery.platformBrightnessOf(context);
    final ThemeData theme = effective == Brightness.dark
        ? AppTheme.dark
        : AppTheme.light;
    final bool hasSeenOnboarding = ref.watch(onboardingControllerProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppTheme.systemOverlayStyle(theme),
      child: MaterialApp(
        title: 'webOS Dev Mode Manager',
        debugShowCheckedModeBanner: false,
        theme: theme,
        // AnimatedSwitcher, not a bare conditional: home is state-driven,
        // not pushed through a Navigator, so nothing would otherwise
        // animate this swap - it would just cut straight to HomePage the
        // instant onboarding completes.
        home: AnimatedSwitcher(
          duration: const Duration(milliseconds: 600),
          switchInCurve: Curves.easeIn,
          switchOutCurve: Curves.easeOut,
          child: hasSeenOnboarding
              ? const HomePage(key: ValueKey('home'))
              : const OnboardingPage(key: ValueKey('onboarding')),
        ),
      ),
    );
  }
}
