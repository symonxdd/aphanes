import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/device.dart';
import '../state/active_device_controller.dart';
import '../state/device_list_controller.dart';
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

class _DeviceList extends ConsumerWidget {
  const _DeviceList({required this.devices});

  final List<Device> devices;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final String? activeId = ref.watch(activeDeviceProvider);
    final Widget content = Column(
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
        for (final Device device in devices)
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
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight - 32,
            ),
            // Biased above dead center, not Center: perfectly centered
            // read as floating in the middle of the screen rather than
            // sitting at a natural "top of the content" resting point.
            child: Align(alignment: const Alignment(0, -0.7), child: content),
          ),
        );
      },
    );
  }
}
