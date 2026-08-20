import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/ui/ambient_backdrop.dart';
import '../../../core/validation/ipv4.dart';
import '../models/device.dart';
import '../state/active_device_controller.dart';
import '../state/device_list_controller.dart';
import 'widgets/devmode_explainers.dart';

class DeviceDetailPage extends ConsumerWidget {
  const DeviceDetailPage({required this.deviceId, super.key});

  final String deviceId;

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Device device,
  ) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text('Remove "${device.name}"?'),
        content: const Text(
          'Reconnecting later will need pairing again from the TV\'s '
          'Developer Mode app.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Remove device'),
          ),
        ],
      ),
    );
    if (confirmed ?? false) {
      await ref.read(deviceListProvider.notifier).remove(device.id);
      ref.read(activeDeviceProvider.notifier).clearIfMatches(device.id);
      if (context.mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  Future<void> _editHost(
    BuildContext context,
    WidgetRef ref,
    Device device,
  ) async {
    final List<Device> otherDevices = (ref.read(deviceListProvider).value ?? const [])
        .where((Device d) => d.id != device.id)
        .toList();
    final String? newHost = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (BuildContext context) =>
          _EditHostSheet(currentHost: device.host, otherDevices: otherDevices),
    );
    if (newHost != null && context.mounted) {
      await ref.read(deviceListProvider.notifier).updateHost(device.id, newHost);
    }
  }

  Future<void> _renameDevice(
    BuildContext context,
    WidgetRef ref,
    Device device,
  ) async {
    final String? newName = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (BuildContext context) =>
          _RenameDeviceSheet(currentName: device.name),
    );
    if (newName != null && context.mounted) {
      await ref.read(deviceListProvider.notifier).rename(device.id, newName);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    // Watched (not a constructor snapshot): re-derives the live device on
    // every rebuild, so editing the host or renaming it updates this page
    // immediately, rather than only after leaving and reopening it.
    final List<Device> devices = ref.watch(deviceListProvider).value ?? const [];
    Device? found;
    for (final Device d in devices) {
      if (d.id == deviceId) {
        found = d;
        break;
      }
    }
    if (found == null) {
      // Only reachable for the one frame between removal and this page
      // popping itself - _confirmDelete already pops right after removing.
      return const Scaffold(body: SizedBox.shrink());
    }
    // A separate, genuinely non-nullable binding: null-promotion on
    // `found` above doesn't survive into the onPressed closures below.
    final Device device = found;
    // MediaQuery's alwaysUse24HourFormat reflects the device's actual
    // system clock setting, independent of locale - DateFormat's own
    // add_jm()/add_Hm() only vary by locale, which wouldn't necessarily
    // match what the user actually has their phone's clock set to.
    final bool use24Hour = MediaQuery.of(context).alwaysUse24HourFormat;
    final DateFormat pairedFormat = use24Hour
        ? DateFormat.yMMMd().add_Hm()
        : DateFormat.yMMMd().add_jm();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Flexible(child: Text(device.name, overflow: TextOverflow.ellipsis)),
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              icon: const Icon(Icons.edit_outlined, size: 24),
              tooltip: 'Rename device',
              onPressed: () => _renameDevice(context, ref, device),
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          const AmbientBackdrop(),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                const SizedBox(height: 16),
                Center(
                  child: Icon(
                    Icons.tv,
                    size: 64,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 32),
                _DetailRow(
                  icon: LucideIcons.network,
                  label: 'IP address',
                  value: device.host,
                  labelAction: IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                    icon: const Icon(Icons.edit_outlined, size: 22),
                    tooltip: 'Edit IP address',
                    onPressed: () => _editHost(context, ref, device),
                  ),
                ),
                if (device.model != null)
                  _DetailRow(
                    icon: LucideIcons.tv,
                    label: 'Model',
                    value: device.model!,
                  ),
                _DetailRow(
                  icon: LucideIcons.calendar,
                  label: 'Paired at',
                  value: pairedFormat.format(device.pairedAt),
                ),
                // Same outer padding as _DetailRow above (not a ListTile,
                // whose enforced minimum tile height reserved noticeably
                // more vertical room even with contentPadding zeroed out -
                // that's what read as extra spacing above this row only).
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Icon(
                        LucideIcons.user,
                        size: 20,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text.rich(
                          TextSpan(
                            text: 'Connected as ',
                            style: theme.textTheme.bodyLarge,
                            children: [
                              // Same size as "Connected as" - monospace is
                              // what sets it apart as a literal, fixed
                              // value, not a smaller size (which read as
                              // visually mismatched next to the other
                              // detail rows on this page).
                              TextSpan(
                                text: device.username,
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  fontFamily: 'monospace',
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 36,
                          minHeight: 36,
                        ),
                        icon: const Icon(Icons.info_outline, size: 24),
                        tooltip: 'Why "${device.username}"?',
                        onPressed: () =>
                            showUsernameInfoSheet(context, device.username),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                // Dark mode's default errorContainer fill reads far more
                // intense than light mode's, so dark instead uses a plain
                // text-and-icon treatment (no fill) - same shape as the
                // low-emphasis destructive button in lm_plus_locator's
                // account sheet, below its own "Log out" button.
                if (isDark)
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: theme.colorScheme.error,
                      minimumSize: const Size.fromHeight(48),
                    ),
                    onPressed: () => _confirmDelete(context, ref, device),
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Remove device'),
                  )
                else
                  FilledButton.tonalIcon(
                    style: FilledButton.styleFrom(
                      backgroundColor: theme.colorScheme.errorContainer,
                      foregroundColor: theme.colorScheme.onErrorContainer,
                      minimumSize: const Size.fromHeight(48),
                    ),
                    onPressed: () => _confirmDelete(context, ref, device),
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Remove device'),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.labelAction,
  });

  final IconData icon;
  final String label;
  final String value;

  /// Shown right after the label, e.g. the IP address row's edit pencil -
  /// an action tied to the field's identity, not its current value, so it
  /// reads naturally next to the label rather than off at the row's end.
  final Widget? labelAction;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Text(label, style: theme.textTheme.bodyLarge),
          if (labelAction != null) ...[const SizedBox(width: 4), labelAction!],
          const Spacer(),
          Text(
            value,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// Prompts for a new IP address for an already-paired TV. The saved SSH
/// key stays valid regardless of address - only the network path to reach
/// the TV can go stale (e.g. a DHCP lease renewing to a different
/// address), so this is the recovery path for that, without needing to
/// pair again from the TV's Developer Mode app.
///
/// A bottom sheet, not an [AlertDialog]: a dialog's height is capped to a
/// fraction of the screen, which the three explanatory paragraphs plus the
/// field overflowed once the keyboard opened and shrank the space further.
/// A sheet grows with its content and resizes cleanly against the keyboard
/// via the same viewInsets.bottom padding every other sheet in this app
/// already uses.
class _EditHostSheet extends StatefulWidget {
  const _EditHostSheet({required this.currentHost, required this.otherDevices});

  final String currentHost;
  final List<Device> otherDevices;

  @override
  State<_EditHostSheet> createState() => _EditHostSheetState();
}

class _EditHostSheetState extends State<_EditHostSheet>
    with SingleTickerProviderStateMixin {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _controller = TextEditingController(
    text: widget.currentHost,
  );
  late final AnimationController _detailsController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
  );
  bool _showDetails = false;

  static const List<String> _detailParagraphs = [
    'Most home networks hand out IP addresses through DHCP, on a lease '
        'that renews periodically. When that lease renews, a device can '
        'be handed a different address than before - this is the most '
        'common reason a previously paired TV\'s address changes.',
    'If this TV\'s address was instead set manually to always stay the '
        'same (a static IP, usually configured by whoever manages the '
        'home network), it will never change on its own, and this '
        'screen shouldn\'t need touching.',
    'Either way, the saved pairing key stays valid: updating the '
        'address here reconnects to the same TV without pairing again '
        'from its Developer Mode app.',
  ];

  // Deliberately no autofocus and no manual requestFocus() either: both
  // trigger a still-open Android/Flutter engine race (flutter/flutter
  // #166386) where the keyboard opens and immediately closes again if the
  // field is focused too soon after a previous field's keyboard was
  // dismissed - reported to happen even with a delayed requestFocus, not
  // just autofocus specifically. The only workaround confirmed to fully
  // avoid it is not focusing programmatically at all.

  @override
  void dispose() {
    _controller.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  void _toggleDetails() {
    setState(() => _showDetails = !_showDetails);
    if (_showDetails) {
      _detailsController.forward();
    } else {
      _detailsController.reverse();
    }
  }

  void _save() {
    if (_formKey.currentState?.validate() ?? false) {
      Navigator.of(context).pop(_controller.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextStyle? bodyStyle = theme.textTheme.bodyMedium;
    final TextStyle? mutedStyle = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          24,
          8,
          24,
          24 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Edit IP address', style: theme.textTheme.headlineSmall),
              const SizedBox(height: 16),
              Text(
                'A TV\'s address can change over time. Updating it here '
                'reconnects without pairing again.',
                style: bodyStyle,
              ),
              const SizedBox(height: 4),
              Center(
                child: TextButton(
                  onPressed: _toggleDetails,
                  child: Text(_showDetails ? 'Collapse' : 'Read more'),
                ),
              ),
              const SizedBox(height: 4),
              SizeTransition(
                sizeFactor: CurvedAnimation(
                  parent: _detailsController,
                  curve: Curves.easeInOut,
                ),
                alignment: Alignment.topLeft,
                child: FadeTransition(
                  opacity: _detailsController,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final String paragraph in _detailParagraphs)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Text(paragraph, style: mutedStyle),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _controller,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "TV's IP address",
                ),
                onFieldSubmitted: (String _) => _save(),
                validator: (String? value) {
                  final String host = value?.trim() ?? '';
                  if (host.isEmpty) {
                    return 'IP address is required';
                  }
                  if (!ipv4Pattern.hasMatch(host)) {
                    return 'Enter a valid IP address';
                  }
                  if (widget.otherDevices.any((Device d) => d.host == host)) {
                    return 'Another paired TV already uses this address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _save,
                    child: const Text('Save'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Prompts for a new display name for an already-paired TV. Purely
/// cosmetic - unlike the host, it isn't used to reach the TV, so there's
/// no need to check it against other paired devices.
class _RenameDeviceSheet extends StatefulWidget {
  const _RenameDeviceSheet({required this.currentName});

  final String currentName;

  @override
  State<_RenameDeviceSheet> createState() => _RenameDeviceSheetState();
}

class _RenameDeviceSheetState extends State<_RenameDeviceSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _controller = TextEditingController(
    text: widget.currentName,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    if (_formKey.currentState?.validate() ?? false) {
      Navigator.of(context).pop(_controller.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          24,
          8,
          24,
          24 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Rename device', style: theme.textTheme.headlineSmall),
              const SizedBox(height: 16),
              TextFormField(
                controller: _controller,
                decoration: const InputDecoration(labelText: 'Device name'),
                onFieldSubmitted: (String _) => _save(),
                validator: (String? value) =>
                    (value == null || value.trim().isEmpty)
                    ? 'Name is required'
                    : null,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(onPressed: _save, child: const Text('Save')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
