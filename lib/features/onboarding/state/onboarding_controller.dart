import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/persistence/shared_preferences_provider.dart';

const String _hasSeenOnboardingPrefsKey = 'has_seen_onboarding';

/// Whether the user has already been shown the onboarding screen.
final NotifierProvider<OnboardingController, bool> onboardingControllerProvider =
    NotifierProvider<OnboardingController, bool>(OnboardingController.new);

class OnboardingController extends Notifier<bool> {
  @override
  bool build() {
    return ref
            .watch(sharedPreferencesProvider)
            .getBool(_hasSeenOnboardingPrefsKey) ??
        false;
  }

  Future<void> complete() async {
    state = true;
    await ref
        .read(sharedPreferencesProvider)
        .setBool(_hasSeenOnboardingPrefsKey, true);
  }
}
