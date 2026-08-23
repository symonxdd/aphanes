import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/device.dart';
import '../state/active_device_controller.dart';
import '../state/device_list_controller.dart';
import '../state/device_reachability_controller.dart';
import 'device_detail_page.dart';
import 'pair_device_page.dart';
import 'widgets/device_card.dart';

class DevicesPage extends ConsumerWidget {
  const DevicesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<Device>> devices = ref.watch(deviceListProvider);

    return devices.when(
      data: (List<Device> list) =>
          list.isEmpty ? const _EmptyState() : _DeviceList(devices: list),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (Object _, StackTrace _) =>
          const Center(child: Text("Couldn't load paired devices.")),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('No devices paired yet'),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (BuildContext _) => const PairDevicePage(),
                ),
              ),
              child: const Text('Pair a device'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Vertical alignment of the list within the viewport, as an [Alignment]
/// y value. Biased above dead center, not centered: perfectly centered
/// read as floating in the middle of the screen rather than sitting at a
/// natural "top of the content" resting point.
const double _listAlignmentY = -0.7;

/// How much empty space that alignment leaves above the list, as a
/// fraction of the total slack. The same conversion [Align] performs
/// internally; named here because the refresh indicator has to place
/// itself against the result.
const double _listTopSlackFraction = (1 + _listAlignmentY) / 2;

const double _listPadding = 16;

class _DeviceList extends ConsumerStatefulWidget {
  const _DeviceList({required this.devices});

  final List<Device> devices;

  @override
  ConsumerState<_DeviceList> createState() => _DeviceListState();
}

class _DeviceListState extends ConsumerState<_DeviceList> {
  final GlobalKey _contentKey = GlobalKey();

  /// Last viewport height handed down by the [LayoutBuilder] below, kept
  /// so [_syncEdgeOffset] can work out how far down the list was pushed
  /// without laying anything out a second time.
  double? _viewportHeight;
  double _edgeOffset = _listPadding;

  /// Puts the refresh spinner where the list actually starts instead of
  /// at the top of an empty screen.
  ///
  /// The list is aligned above center rather than pinned to the top, so
  /// how far down it begins depends on how much shorter than the viewport
  /// it happens to be - which is only knowable once it has been laid out.
  /// Hence measuring it after the frame and feeding the answer back as
  /// the indicator's edge offset. It settles on the first frame and then
  /// only moves again when a device is added or removed.
  void _syncEdgeOffset() {
    final double? viewport = _viewportHeight;
    final RenderObject? object = _contentKey.currentContext?.findRenderObject();
    if (viewport == null || object is! RenderBox || !object.hasSize) {
      return;
    }
    final double slack =
        (viewport - _listPadding * 2 - object.size.height).clamp(
          0.0,
          double.infinity,
        ) *
        _listTopSlackFraction;
    final double next = _listPadding + slack;
    if ((next - _edgeOffset).abs() > 0.5 && mounted) {
      setState(() => _edgeOffset = next);
    }
  }

  /// Re-runs every paired device's reachability probe and waits for all of
  /// them, so the refresh spinner stays up for as long as the checks
  /// actually take rather than snapping away immediately.
  ///
  /// Invalidating the whole family (not just the rows visible here) is
  /// deliberate: the Apps tab and the device detail page read the same
  /// per-device providers, so a pull here is also what brings those back
  /// in line without needing to visit them and pull again.
  Future<void> _recheckAll() async {
    ref.invalidate(deviceReachabilityProvider);
    await Future.wait(<Future<bool>>[
      for (final Device device in widget.devices)
        ref.read(deviceReachabilityProvider(device.id).future),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String? activeId = ref.watch(activeDeviceProvider);
    WidgetsBinding.instance.addPostFrameCallback(
      (Duration _) => _syncEdgeOffset(),
    );
    final Widget content = Column(
      key: _contentKey,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Align, not the Column's own crossAxisAlignment: the cards below
        // fill the available width regardless of that setting (ListTile's
        // own default behavior), so aligning this label needs to be
        // independent of it to reliably sit left rather than centered.
        Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 12),
            child: Text(
              'Paired devices',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        for (final Device device in widget.devices)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: DeviceCard(
              device: device,
              selected: device.id == activeId,
              onTap: () =>
                  ref.read(activeDeviceProvider.notifier).select(device.id),
              onInfoTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (BuildContext _) => DeviceDetailPage(
                    deviceId: device.id,
                  ),
                ),
              ),
            ),
          ),
      ],
    );

    // A short list (the common case - one or two TVs) pinned to the top
    // of an otherwise empty screen read as forgotten/unfinished. Centering
    // it when it fits, while still scrolling normally once it doesn't,
    // needs the list's own height available to compare against - hence
    // LayoutBuilder handing that down as the ConstrainedBox's minHeight.
    return RefreshIndicator(
      onRefresh: _recheckAll,
      edgeOffset: _edgeOffset,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          // Recorded, not acted on, during build: _syncEdgeOffset reads it
          // after the frame, where changing state is safe.
          _viewportHeight = constraints.maxHeight;
          return SingleChildScrollView(
            // The list usually fits on one screen and so would not scroll
            // at all by default, which is exactly the case where a
            // pull-to-refresh gesture has to keep working.
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(_listPadding),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight - _listPadding * 2,
              ),
              child: Align(
                alignment: const Alignment(0, _listAlignmentY),
                child: content,
              ),
            ),
          );
        },
      ),
    );
  }
}
