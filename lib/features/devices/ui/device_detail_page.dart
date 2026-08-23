import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/ui/ambient_backdrop.dart';
import '../../../core/validation/ipv4.dart';
import '../models/device.dart';
import '../models/device_detail.dart';
import '../models/device_info.dart';
import '../models/devmode_status.dart';
import '../state/active_device_controller.dart';
import '../state/device_detail_controller.dart';
import '../state/device_info_cache_controller.dart';
import '../state/device_list_controller.dart';
import '../state/device_reachability_controller.dart';
import 'widgets/device_field_explainers.dart';
import 'widgets/devmode_explainers.dart';
import 'widgets/unreachable_message.dart';

// Shared metrics for every row on this page. Pinned down in one place for
// vertical rhythm: a row carrying an icon button is as tall as that
// button, and a row without one is only as tall as its text, which is
// what used to make the locally-stored fields at the top of this page
// look more loosely spaced than the fetched ones under "From the TV".
// Every row now carries at least an explainer button, at these exact
// metrics, so every row is the same height and the gaps down the page are
// even.

/// The tap box around a row's explainer or action glyph.
///
/// Narrower than it is tall on purpose. The height is the half that keeps
/// every row the same size as its neighbours. The width is pure slack
/// around a 20-wide glyph, and at 36 that slack showed up doubled between
/// two adjacent buttons, which is what left the IP row's edit pencil
/// floating away from the explainer beside it.
const BoxConstraints _rowActionConstraints = BoxConstraints(
  minWidth: 28,
  minHeight: 36,
);

/// Required for [_rowActionConstraints] to mean anything at all.
///
/// [IconButton] defaults to `MaterialTapTargetSize.padded`, which wraps it
/// in a minimum 48-square layout box. That box wins over `constraints`,
/// silently: the IP row's explainer and pencil sat 28 apart no matter what
/// width they were given, because each was really occupying 48 around a
/// 20-wide glyph. Shrink-wrapping hands the sizing back to `constraints`.
///
/// The cost is a tap target below the 48 Material asks for. Accepted here
/// because these are small secondary affordances on a row that is itself
/// tappable for nothing else, and because the row's own 36 minimum height
/// keeps them comfortably hittable in the axis that matters most.
const ButtonStyle _rowActionStyle = ButtonStyle(
  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
);

const EdgeInsets _rowPadding = EdgeInsets.symmetric(vertical: 6);
const double _rowActionIconSize = 20;

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

    ref.listen<DevModeRenewState>(devModeRenewProvider, (
      DevModeRenewState? previous,
      DevModeRenewState next,
    ) {
      final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
      if (next is DevModeRenewSucceeded) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text(
              'Renewal requested. The remaining time updates once the TV '
              'processes it.',
            ),
          ),
        );
        ref.read(devModeRenewProvider.notifier).reset();
      } else if (next is DevModeRenewFailed) {
        messenger.showSnackBar(SnackBar(content: Text(next.message)));
        ref.read(devModeRenewProvider.notifier).reset();
      }
    });

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
                  onInfoTap: () => DeviceFieldExplainers.ipAddress(context),
                  labelAction: IconButton(
                    style: _rowActionStyle,
                    padding: EdgeInsets.zero,
                    constraints: _rowActionConstraints,
                    icon: const Icon(
                      Icons.edit_outlined,
                      size: _rowActionIconSize,
                    ),
                    tooltip: 'Edit IP address',
                    onPressed: () => _editHost(context, ref, device),
                  ),
                ),
                if (device.model != null)
                  _DetailRow(
                    icon: LucideIcons.tv,
                    label: 'Model',
                    value: device.model!,
                    onInfoTap: () => DeviceFieldExplainers.model(context),
                  ),
                _DetailRow(
                  icon: LucideIcons.calendar,
                  label: 'Paired at',
                  value: pairedFormat.format(device.pairedAt),
                  onInfoTap: () => DeviceFieldExplainers.pairedAt(context),
                ),
                // An ordinary row like the rest, rather than the inline
                // "Connected as prisoner" sentence it used to be: the
                // username is a value of this field, so it belongs
                // right-aligned in the value column with every other
                // field's, and its explainer belongs against the label.
                _DetailRow(
                  icon: LucideIcons.user,
                  label: 'Connected as',
                  value: device.username,
                  monospaceValue: true,
                  infoTooltip: 'Why "${device.username}"?',
                  onInfoTap: () =>
                      showUsernameInfoSheet(context, device.username),
                ),
                const SizedBox(height: 32),
                // A section label, unlike anything above it on this page:
                // everything above is instant, locally-stored data:
                // everything below needs a live SSH connection to the TV,
                // with its own loading and failure states, and that
                // difference is worth making visible rather than letting
                // it blend into one flat list.
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      'From the TV',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                _LiveDeviceInfo(device: device),
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

/// Everything this page knows from the TV rather than from local
/// storage: its hardware and firmware facts, plus its Developer Mode
/// session.
///
/// The facts are shown from the stored copy of the last successful fetch
/// the moment the page opens, and a fresh fetch runs behind them every
/// visit regardless. Reopening a TV that has been opened before therefore
/// shows its details immediately, with no spinner - the spinner is
/// reserved for the genuine first visit, when there is nothing to show
/// yet. None of these fields moves without a firmware update, so a stored
/// copy is very nearly always still correct, and a fetch that disagrees
/// simply replaces what is on screen.
///
/// The Developer Mode session is pointedly not treated that way. It is a
/// countdown, so a stored "3 hours remaining" would be actively wrong the
/// next day rather than merely stale, and it is a credential besides. It
/// is re-read every visit, and says so while it does.
///
/// The reachability probe is watched directly here rather than left to
/// deviceDetailProvider's own internal check, so an unreachable TV
/// reports itself in a few seconds (that probe's own timeout) instead of
/// after a full SSH connect attempt that was never going to succeed.
class _LiveDeviceInfo extends ConsumerWidget {
  const _LiveDeviceInfo({required this.device});

  final Device device;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final AsyncValue<bool> reachable = ref.watch(
      deviceReachabilityProvider(device.id),
    );
    final AsyncValue<DeviceDetail> detail = ref.watch(
      deviceDetailProvider(device.id),
    );
    final AsyncValue<Map<String, DeviceInfo>> cache = ref.watch(
      deviceInfoCacheProvider,
    );

    // A completed fetch wins; the stored copy stands in until one
    // arrives. Deliberately in this order, so a TV that changed something
    // never keeps showing the old value once the truth is in.
    final DeviceInfo? info = detail.value?.info ?? cache.value?[device.id];
    final bool unreachable = switch (reachable) {
      AsyncData(:final bool value) => !value,
      AsyncError() => true,
      _ => false,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (info != null) ..._infoRows(context, info),
        _status(theme, detail, cache, unreachable, info != null),
      ],
    );
  }

  List<Widget> _infoRows(BuildContext context, DeviceInfo info) {
    return [
      if (info.modelName != null)
        _DetailRow(
          icon: LucideIcons.tv,
          label: 'Model',
          value: info.modelName!,
          onInfoTap: () => DeviceFieldExplainers.model(context),
        ),
      if (info.firmwareVersion != null)
        _DetailRow(
          icon: LucideIcons.cpu,
          label: 'Firmware',
          value: info.firmwareVersion!,
          onInfoTap: () => DeviceFieldExplainers.firmware(context),
        ),
      if (info.webosVersion != null)
        _DetailRow(
          icon: LucideIcons.tv,
          label: 'webOS version',
          value: info.webosVersion!,
          onInfoTap: () => DeviceFieldExplainers.webosVersion(context),
        ),
      if (info.socName != null)
        _DetailRow(
          icon: LucideIcons.microchip,
          label: 'SoC',
          value: info.socName!,
          onInfoTap: () => DeviceFieldExplainers.soc(context),
        ),
      if (info.otaId != null)
        _DetailRow(
          icon: LucideIcons.hash,
          label: 'OTA ID',
          value: info.otaId!,
          onInfoTap: () => DeviceFieldExplainers.otaId(context),
        ),
    ];
  }

  /// What sits below the facts: either the Developer Mode row, or the
  /// reason there isn't one.
  Widget _status(
    ThemeData theme,
    AsyncValue<DeviceDetail> detail,
    AsyncValue<Map<String, DeviceInfo>> cache,
    bool unreachable,
    bool hasRows,
  ) {
    if (unreachable) {
      // With the stored facts already on screen, a full "not reachable"
      // notice on top of them is noise: it explains an absence that is
      // not there to explain, and the Devices tab and the app bar dot
      // both report reachability already. Only the one value that
      // genuinely cannot be shown says anything.
      if (hasRows) {
        return _DevModeStatusRow(
          device: device,
          status: null,
          placeholder: 'Unreachable',
        );
      }
      // Nothing stored to fall back on, so the section really is empty
      // and the notice is the only thing worth putting in it.
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: UnreachableMessage(deviceName: device.name),
      );
    }
    // Reachability has already passed by this point, so an error here is
    // never the plain "TV is off" case - same reasoning as
    // apps_page.dart's own _loadErrorWidget.
    if (detail case AsyncError(:final Object error)) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          error.toString(),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.error,
          ),
        ),
      );
    }
    // `.value`, not a match on AsyncData: a provider that is refreshing
    // reports AsyncLoading while still carrying the previous answer, and
    // matching on the type alone threw that answer away and fell through
    // to "Checking..." for the whole of every refetch.
    final DeviceDetail? loaded = detail.value;
    if (loaded != null) {
      return _DevModeStatusRow(device: device, status: loaded.devMode);
    }
    // Nothing fetched yet this session. With rows already on screen, the
    // Developer Mode row reports the fetch itself - honest, and what
    // replaces the spinner that used to greet every single visit.
    if (hasRows) {
      return _DevModeStatusRow(
        device: device,
        status: null,
        placeholder: 'Checking...',
      );
    }
    // Nothing to show yet, and the stored copy has not been read back
    // either. Waiting a frame or two for it beats flashing a spinner that
    // a previously-opened TV is about to make pointless.
    if (cache.isLoading) {
      return const SizedBox.shrink();
    }
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}

/// The one row on this page that is never served from the stored copy.
///
/// Built on [_DetailRow] like every other field, which is what keeps it
/// to a single line. It used to put a whole sentence ("No active
/// Developer Mode session found.") where the other rows put a short
/// value, and then follow it with a full-width Renew button, so anything
/// but the shortest status wrapped to two or three lines. The label goes
/// on the left, the status goes in the value column, and renewing moves
/// into the same small action slot the IP address row keeps its edit
/// pencil in.
///
/// A null [status] means there is no session to report yet, and
/// [placeholder] is the value to show instead: that the check is still
/// running, or that it cannot run at all right now. Saying so keeps the
/// row on screen either way, which is the point - a countdown that
/// quietly disappears reads as a missing feature, where one that
/// explains itself reads as a TV that needs turning on.
class _DevModeStatusRow extends ConsumerWidget {
  const _DevModeStatusRow({
    required this.device,
    required this.status,
    this.placeholder,
  });

  final Device device;
  final DevModeStatus? status;

  /// Shown in place of a session while [status] is null.
  final String? placeholder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final DevModeRenewState renewState = ref.watch(devModeRenewProvider);
    final bool renewing = renewState is DevModeRenewInProgress;
    final DevModeStatus? current = status;

    // Short enough to sit in the value column beside the others. What
    // each one means is the explainer's job, not this row's.
    final String value;
    final Duration? countdown = current?.remainingDuration;
    if (current == null) {
      value = placeholder ?? 'Checking...';
    } else if (countdown != null) {
      // Replaced below by a ticking one. Kept as the value anyway so the
      // row is correct for a frame, and correct in a screenshot test.
      value = _formatCountdown(countdown);
    } else if (current.remaining != null) {
      value = current.remaining!;
    } else if (current.hasToken) {
      value = 'Time unknown';
    } else {
      value = 'No session';
    }

    return _DetailRow(
      icon: LucideIcons.shieldCheck,
      label: 'Developer Mode',
      value: value,
      // Counts down locally from what LG reported, rather than asking
      // again every second. The endpoint is only consulted once per
      // visit; this just stops a live session from looking frozen.
      valueOverride: countdown == null
          ? null
          : _SessionCountdown(from: countdown, key: ValueKey(current)),
      onInfoTap: () => DeviceFieldExplainers.developerMode(context),
      labelAction: renewing
          // Sized to the button it replaces, so the row holds still while
          // a renewal is in flight.
          ? const SizedBox(
              width: 28,
              height: 36,
              child: Center(
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          : IconButton(
              style: _rowActionStyle,
              padding: EdgeInsets.zero,
              constraints: _rowActionConstraints,
              icon: const Icon(Icons.refresh, size: _rowActionIconSize),
              tooltip: 'Renew Developer Mode session',
              // Nothing to renew until the current session is known.
              onPressed: current == null
                  ? null
                  : () => ref.read(devModeRenewProvider.notifier).renew(device),
            ),
    );
  }
}

/// Renders [d] as a clock, with hours free to run past 24. A Developer
/// Mode session can be most of a thousand hours long, so days would be
/// the friendlier unit, but LG reports hours and matching that keeps this
/// value comparable with what the TV itself shows.
String _formatCountdown(Duration d) {
  final Duration clamped = d < Duration.zero ? Duration.zero : d;
  final String mm = clamped.inMinutes.remainder(60).toString().padLeft(2, '0');
  final String ss = clamped.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '${clamped.inHours}:$mm:$ss';
}

/// Ticks a session's remaining time down once a second.
///
/// Purely local. LG's endpoint is asked once when the page loads, and
/// this counts down from that answer, so a live session visibly runs
/// rather than sitting frozen at whatever it read on arrival. Being a
/// second or two adrift after a long visit does not matter for a value
/// measured in hours; being obviously stationary looked broken.
class _SessionCountdown extends StatefulWidget {
  const _SessionCountdown({required this.from, super.key});

  final Duration from;

  @override
  State<_SessionCountdown> createState() => _SessionCountdownState();
}

class _SessionCountdownState extends State<_SessionCountdown> {
  late Duration _remaining = widget.from;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (Timer _) {
      if (!mounted) {
        return;
      }
      setState(() {
        _remaining = _remaining - const Duration(seconds: 1);
        if (_remaining <= Duration.zero) {
          _remaining = Duration.zero;
          _ticker?.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Text(
      _remaining == Duration.zero ? 'Expired' : _formatCountdown(_remaining),
      textAlign: TextAlign.end,
      style: theme.textTheme.bodyLarge?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.onInfoTap,
    this.infoTooltip,
    this.labelAction,
    this.monospaceValue = false,
    this.valueOverride,
  });

  /// Replaces the rendered [value] while keeping everything else about
  /// the row identical. For a value that has to animate or tick, which a
  /// plain string cannot do. [value] is still required, and is what a
  /// non-animating build of the same row would show.
  final Widget? valueOverride;

  final IconData icon;
  final String label;
  final String value;

  /// Renders the value in a monospaced face. For values that are literal,
  /// fixed strings rather than prose - a fixed account name, say - where
  /// the face is what marks them as such. Deliberately not paired with a
  /// smaller size, which read as mismatched against the other rows.
  final bool monospaceValue;

  /// Opens this field's explainer sheet. Sits immediately after the label
  /// rather than at the row's end, because the question it answers is
  /// "what is this field", which belongs to the field's name and not to
  /// whatever value it happens to be showing.
  final VoidCallback? onInfoTap;

  /// Overrides the generic "What is <label>?" tooltip, for a field whose
  /// explainer is better named after its value than its label.
  final String? infoTooltip;

  /// Shown right after the explainer, e.g. the IP address row's edit
  /// pencil - an action tied to the field's identity, not its current
  /// value, so it reads naturally next to the label rather than off at
  /// the row's end.
  final Widget? labelAction;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: _rowPadding,
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Text(label, style: theme.textTheme.bodyLarge),
          if (onInfoTap != null) ...[
            // The buttons carry only 4 of slack each side once
            // shrink-wrapped, so the label needs its own small gap for
            // the explainer not to crowd the last letter.
            const SizedBox(width: 4),
            IconButton(
              style: _rowActionStyle,
              padding: EdgeInsets.zero,
              constraints: _rowActionConstraints,
              icon: const Icon(Icons.info_outline, size: _rowActionIconSize),
              tooltip: infoTooltip ?? 'What is "$label"?',
              onPressed: onInfoTap,
            ),
          ],
          ?labelAction,
          const SizedBox(width: 8),
          // Expanded, not Spacer + a bare Text: a long value (an OTA ID
          // is around twenty characters) had nothing to wrap against and
          // overflowed the row instead. This gives it the leftover width
          // to wrap into while still sitting hard against the right edge.
          Expanded(
            child:
                valueOverride ??
                Text(
                  value,
                  textAlign: TextAlign.end,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontFamily: monospaceValue ? 'monospace' : null,
                  ),
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
