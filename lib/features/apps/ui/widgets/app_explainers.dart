import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/ui/info_sheet.dart';

/// Plain-language explainers for the installed apps list, opened from
/// the small glyphs on a row. Same wording as the desktop app's.
abstract final class AppExplainers {
  /// What the "Running" marker on a row does and does not say.
  static Future<void> running(BuildContext context) {
    return InfoSheet.show(
      context,
      icon: LucideIcons.circlePlay,
      title: 'Running on the TV',
      body:
          'The TV shows this app as currently active, but it does not '
          'specify whether it is running in the background or displayed '
          'on the screen.',
    );
  }
}
