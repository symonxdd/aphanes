import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/ui/ambient_backdrop.dart';
import '../../devices/models/device.dart';
import '../models/catalog_package.dart';
import '../models/luna_operation_progress.dart';
import '../state/app_operation_controller.dart';
import '../state/catalog_controller.dart';
import '../state/installed_apps_controller.dart';
import 'widgets/operation_progress_dialog.dart';

/// Browses the public Homebrew app store catalog and installs straight
/// from it - pushed like `PairDevicePage`, not a sheet, since it needs its
/// own scrollable list plus a search field.
class CatalogPage extends ConsumerStatefulWidget {
  const CatalogPage({required this.device, super.key});

  final Device device;

  @override
  ConsumerState<CatalogPage> createState() => _CatalogPageState();
}

class _CatalogPageState extends ConsumerState<CatalogPage> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<CatalogPackage>> catalog = ref.watch(
      catalogProvider,
    );
    return Scaffold(
      appBar: AppBar(title: const Text('Browse catalog')),
      body: Stack(
        children: [
          const AmbientBackdrop(),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Search apps',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (String value) =>
                        setState(() => _query = value.trim().toLowerCase()),
                  ),
                ),
                Expanded(
                  child: catalog.when(
                    data: (List<CatalogPackage> packages) {
                      final List<CatalogPackage> filtered = _query.isEmpty
                          ? packages
                          : packages
                                .where(
                                  (CatalogPackage p) => p.title
                                      .toLowerCase()
                                      .contains(_query),
                                )
                                .toList();
                      if (filtered.isEmpty) {
                        return const Center(child: Text('No matching apps'));
                      }
                      return RefreshIndicator(
                        onRefresh: () =>
                            ref.read(catalogProvider.notifier).refresh(),
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: filtered.length,
                          separatorBuilder: (BuildContext _, int _) =>
                              const SizedBox(height: 12),
                          itemBuilder: (BuildContext context, int index) =>
                              _CatalogTile(
                                package: filtered[index],
                                device: widget.device,
                              ),
                        ),
                      );
                    },
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (Object _, StackTrace _) =>
                        const Center(child: Text("Couldn't load the catalog.")),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CatalogTile extends StatelessWidget {
  const _CatalogTile({required this.package, required this.device});

  final CatalogPackage package;
  final Device device;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        leading: _CatalogIcon(uri: package.iconUri),
        title: Text(package.title),
        subtitle: Text(
          package.shortDescription,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        onTap: () =>
            _CatalogDetailSheet.show(context, package: package, device: device),
      ),
    );
  }
}

class _CatalogIcon extends StatelessWidget {
  const _CatalogIcon({required this.uri});

  final String? uri;

  @override
  Widget build(BuildContext context) {
    if (uri == null) {
      return const CircleAvatar(child: Icon(Icons.apps));
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        uri!,
        width: 40,
        height: 40,
        errorBuilder: (BuildContext _, Object _, StackTrace? _) =>
            const Icon(Icons.apps),
      ),
    );
  }
}

class _CatalogDetailSheet extends ConsumerWidget {
  const _CatalogDetailSheet({required this.package, required this.device});

  final CatalogPackage package;
  final Device device;

  static Future<void> show(
    BuildContext context, {
    required CatalogPackage package,
    required Device device,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (BuildContext _) =>
          _CatalogDetailSheet(package: package, device: device),
    );
  }

  Stream<LunaOperationProgress> _installStream(WidgetRef ref) async* {
    yield const LunaOperationWorking('Downloading...');
    final Uint8List bytes = await ref
        .read(appCatalogServiceProvider)
        .downloadAndVerify(package.manifest);
    yield* ref.read(appsServiceProvider).installBytes(device, bytes);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final String? sourceUrl = package.manifest.sourceUrl;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _CatalogIcon(uri: package.iconUri),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(package.title, style: theme.textTheme.titleLarge),
                      Text(
                        'v${package.manifest.version}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              package.manifest.appDescription.isEmpty
                  ? package.shortDescription
                  : package.manifest.appDescription,
              style: theme.textTheme.bodyMedium,
            ),
            if (sourceUrl != null) ...[
              const SizedBox(height: 4),
              TextButton.icon(
                onPressed: () => launchUrl(
                  Uri.parse(sourceUrl),
                  mode: LaunchMode.externalApplication,
                ),
                icon: const Icon(Icons.open_in_new, size: 16),
                label: const Text('Source'),
              ),
            ],
            const SizedBox(height: 16),
            // A handful of real catalog entries publish no checksum to
            // verify against - installing one of those would mean silently
            // skipping the integrity check this whole flow exists to
            // enforce, so it's blocked here rather than left to fail
            // (or worse, succeed unverified) once Install is tapped.
            if (package.manifest.ipkSha256 == null)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 18,
                    color: theme.colorScheme.error,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "This package doesn't publish a checksum, so it "
                      "can't be installed from here.",
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ),
                ],
              )
            else
              FilledButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  OperationProgressDialog.show(
                    context,
                    provider: installOperationProvider,
                    title: 'Installing ${package.title}...',
                    run: () => ref
                        .read(installOperationProvider.notifier)
                        .run(_installStream(ref)),
                  );
                },
                child: const Text('Install'),
              ),
          ],
        ),
      ),
    );
  }
}
