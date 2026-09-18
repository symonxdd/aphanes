import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/device_reachability_controller.dart';

/// Re-probes every paired TV when the app comes back to the foreground.
///
/// Coming back to the app is the moment its picture of a TV is likeliest
/// to be stale: the TV was switched on or off while something else was on
/// screen. So the reachability probe is thrown away then, and whatever
/// screen is open and watches it follows: the Apps tab fetches its list
/// again if the TV answers, and the device detail page, which re-fetches
/// on every visit anyway, does the same. The desktop app does this when
/// its window regains focus.
///
/// Only a real return counts, one where the app had been hidden or paused
/// behind another app or the home screen. A system dialog or the
/// notification shade merely makes the app inactive for a moment, and
/// dismissing that is not a reason to ask the TV anything. Still never on
/// a timer.
class ForegroundRecheck extends ConsumerStatefulWidget {
  const ForegroundRecheck({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<ForegroundRecheck> createState() => _ForegroundRecheckState();
}

class _ForegroundRecheckState extends ConsumerState<ForegroundRecheck> {
  late final AppLifecycleListener _lifecycle;
  bool _wasAway = false;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(
      onHide: () => _wasAway = true,
      onPause: () => _wasAway = true,
      onResume: _onResume,
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  void _onResume() {
    if (!_wasAway) {
      return;
    }
    _wasAway = false;
    // The whole family: every TV's probe, not just the active one's, so
    // the Devices tab's dots are right too.
    ref.invalidate(deviceReachabilityProvider);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
