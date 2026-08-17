import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Overridden with the real instance in `main()` before the app starts, so
/// synchronous consumers (e.g. [ThemeModeController]) never have to await it.
final Provider<SharedPreferences> sharedPreferencesProvider =
    Provider<SharedPreferences>((Ref ref) {
      throw UnimplementedError(
        'sharedPreferencesProvider must be overridden in main()',
      );
    });
