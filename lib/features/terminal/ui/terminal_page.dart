import 'package:flutter/material.dart';

import '../../../core/ui/not_planned_message.dart';

/// Not currently planned - see Milestone 4's scope decision (device info
/// on the device detail page instead) for why. Left in the bottom nav
/// rather than removed, since a terminal could still be worth building
/// later if there is real demand for it.
class TerminalPage extends StatelessWidget {
  const TerminalPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const NotPlannedMessage();
  }
}
