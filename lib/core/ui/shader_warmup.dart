import 'dart:async';

import 'package:flutter/material.dart';

/// Forces a one-time compile of a couple of paint effects the app's first
/// pairing screen is otherwise the first to need: an outlined text field's
/// focus border, and a filled button's ripple and elevation shadow. On
/// Android that first-use compile is a real, if small, cost even with
/// Impeller (the engine still has to build a pipeline the first time it
/// sees a specific combination of effects), and it is what the visible
/// hitch on the very first "Pair a device" tap is - every screen reached
/// before that point (the home shell, in practice) never needed those two
/// widgets, so nothing had paid that cost yet.
///
/// Mounted once, briefly, fully off-screen (a large negative offset inside
/// a [Stack], which clips it away) and nearly transparent rather than
/// [Offstage] or zero opacity - both of those skip the paint step
/// entirely, which would defeat the point. Removes itself a moment after
/// its first real frame, so it never keeps costing anything afterward.
class ShaderWarmup extends StatefulWidget {
  const ShaderWarmup({super.key});

  @override
  State<ShaderWarmup> createState() => _ShaderWarmupState();
}

class _ShaderWarmupState extends State<ShaderWarmup> {
  bool _done = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Long enough to sit after the home shell's own entrance animation
    // settles, so this never competes with it for a frame.
    _timer = Timer(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() => _done = true);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_done) {
      return const SizedBox.shrink();
    }
    return Positioned(
      left: -200,
      top: -200,
      child: IgnorePointer(
        child: Opacity(
          opacity: 0.01,
          child: SizedBox(
            width: 120,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  decoration: const InputDecoration(labelText: 'warmup'),
                ),
                FilledButton(onPressed: () {}, child: const Text('warmup')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
