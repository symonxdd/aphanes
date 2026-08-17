import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/persistence/shared_preferences_provider.dart';
import 'core/theme/app_theme.dart';
import 'features/home/ui/home_page.dart';
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

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppTheme.systemOverlayStyle(theme),
      child: MaterialApp(
        title: 'webOS Dev Mode Manager',
        debugShowCheckedModeBanner: false,
        theme: theme,
        home: const HomePage(),
      ),
    );
  }
}
