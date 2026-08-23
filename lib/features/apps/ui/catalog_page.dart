import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/ui/ambient_backdrop.dart';
import '../../devices/models/device.dart';
import '../curated_favorite_apps.dart';
import '../models/catalog_package.dart';
import '../models/luna_operation_progress.dart';
import '../services/app_catalog_service.dart';
import '../services/apps_service.dart';
import '../state/app_operation_controller.dart';
import '../state/catalog_controller.dart';
import '../state/installed_apps_controller.dart';
import 'widgets/catalog_explainer_sheet.dart';
import 'widgets/operation_progress_dialog.dart';

enum _ViewMode { grid, list }

// Built on curatedFavoriteAppIds (a static, code-only list), not the
// catalog's own `featured` flag - that's an editorial pick by the
// webosbrew project, a handful of apps, unrelated to what should surface
// here. Only two modes, deliberately: a third "favorites first" (show
// everything, favorites ranked above the rest) used to sit between these,
// but it meant the control's own visible width changed depending on
// which mode was picked - a real, repeated bug, not just a look this
// didn't like. Two options, both rendered as a real segmented toggle
// (every option always on screen, nothing swapped in/out), sidesteps
// that whole bug class rather than patching it again.
enum _ListMode { favorites, alphabetical }

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
  final FocusNode _searchFocusNode = FocusNode();
  String _query = '';
  bool _searchActive = false;
  _ViewMode _viewMode = _ViewMode.list;
  _ListMode _listMode = _ListMode.favorites;

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  // Explicit FocusNode.requestFocus(), not the TextField's own autofocus:
  // autofocus fires after the field's already built (a later frame than
  // the tap that created it), which several Android/keyboard combinations
  // don't reliably treat as "user-initiated" enough to actually show the
  // keyboard for. Requesting focus here, directly inside the tap's own
  // handler, keeps it tied to the original gesture.
  void _openSearch() {
    setState(() => _searchActive = true);
    _searchFocusNode.requestFocus();
  }

  void _closeSearch() {
    setState(() {
      _searchActive = false;
      _query = '';
      _searchController.clear();
    });
  }

  List<CatalogPackage> _visiblePackages(List<CatalogPackage> packages) {
    Iterable<CatalogPackage> result = packages;
    if (_query.isNotEmpty) {
      result = result.where(
        (CatalogPackage p) => p.title.toLowerCase().contains(_query),
      );
    }
    if (_listMode == _ListMode.favorites) {
      result = result.where(
        (CatalogPackage p) => curatedFavoriteAppIds.contains(p.id),
      );
    }
    final List<CatalogPackage> list = result.toList();
    if (_listMode == _ListMode.favorites) {
      // Ranked by curatedFavoriteAppIds' own order, not alphabetically -
      // that order is deliberate (requested explicitly), not incidental.
      list.sort((CatalogPackage a, CatalogPackage b) {
        return curatedFavoriteAppIds
            .indexOf(a.id)
            .compareTo(curatedFavoriteAppIds.indexOf(b.id));
      });
    } else {
      list.sort(
        (CatalogPackage a, CatalogPackage b) =>
            a.title.toLowerCase().compareTo(b.title.toLowerCase()),
      );
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<CatalogPackage>> catalog = ref.watch(catalogProvider);
    // Whatever's already on the TV, by id - watched here once rather than
    // separately per tile, and passed down as a plain Set rather than
    // making every tile watch installedAppsProvider on its own.
    final Set<String> installedIds =
        ref.watch(installedAppsProvider).value?.map((a) => a.id).toSet() ??
        const {};
    return Scaffold(
      appBar: AppBar(
        // Search replaces the title in place, rather than a permanently
        // visible field: the query being typed sits right in the app bar
        // the whole time, so it's never unclear what's currently
        // searched for - closing search (the back arrow here, not the
        // page's own) clears it and restores the normal title.
        leading: _searchActive
            ? IconButton(
                key: const ValueKey('catalog-search-close'),
                icon: const Icon(LucideIcons.arrowLeft),
                tooltip: 'Close search',
                onPressed: _closeSearch,
              )
            : null,
        title: _searchActive
            ? TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                // Matches the title's own resolved style (whatever the
                // theme's AppBar default actually is), not a guessed
                // value - otherwise typed text visibly differs in size
                // and weight from "Browse catalog" in the same slot.
                style:
                    AppBarTheme.of(context).titleTextStyle ??
                    Theme.of(context).textTheme.titleLarge,
                decoration: const InputDecoration(
                  hintText: 'Search apps',
                  border: InputBorder.none,
                ),
                onChanged: (String value) =>
                    setState(() => _query = value.trim().toLowerCase()),
              )
            : const Text('Browse catalog'),
        // Explicit keys on every action button below: without them, the
        // search icon and the X (clear) icon that replaces it at the
        // same list position are both plain IconButtons, so Flutter's
        // reconciliation reused the same element across the swap -
        // including the search tap's still-playing ripple animation,
        // which then visibly carried over onto the X button. Distinct
        // keys force a genuinely new element for each, not an in-place
        // update of the old one.
        actions: [
          if (_searchActive)
            IconButton(
              key: const ValueKey('catalog-search-clear'),
              icon: const Icon(LucideIcons.x),
              tooltip: 'Clear search',
              onPressed: () => setState(() {
                _query = '';
                _searchController.clear();
              }),
            )
          else ...[
            IconButton(
              key: const ValueKey('catalog-search-open'),
              icon: const Icon(LucideIcons.search),
              tooltip: 'Search',
              onPressed: _openSearch,
            ),
            IconButton(
              key: const ValueKey('catalog-info'),
              icon: const Icon(LucideIcons.info),
              tooltip: 'About this catalog',
              onPressed: () => CatalogExplainerSheet.show(context),
            ),
          ],
        ],
      ),
      body: Stack(
        children: [
          const AmbientBackdrop(),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                  child: Row(
                    children: [
                      // A real 2-segment toggle, both options always on
                      // screen at once - not an anchor button that swaps
                      // its own label depending on what's selected. That
                      // approach (and the 3-option version before it)
                      // kept visibly resizing itself between selections;
                      // rendering every option simultaneously removes the
                      // whole bug class rather than patching it again.
                      SegmentedButton<_ListMode>(
                        showSelectedIcon: false,
                        segments: const [
                          ButtonSegment(
                            value: _ListMode.favorites,
                            icon: Icon(LucideIcons.star),
                            label: Text('Favorites'),
                          ),
                          ButtonSegment(
                            value: _ListMode.alphabetical,
                            icon: Icon(LucideIcons.arrowDownAZ),
                            label: Text('A–Z'),
                          ),
                        ],
                        selected: {_listMode},
                        onSelectionChanged: (Set<_ListMode> selection) =>
                            setState(() => _listMode = selection.first),
                      ),
                      const Spacer(),
                      // Icon reflects the CURRENT view, not the one a tap
                      // switches to: it's read as "you're looking at a
                      // list" the same way the grid icon reads as "you're
                      // looking at a grid".
                      IconButton(
                        tooltip: _viewMode == _ViewMode.grid
                            ? 'Switch to list view'
                            : 'Switch to grid view',
                        icon: Icon(
                          _viewMode == _ViewMode.grid
                              ? LucideIcons.layoutGrid
                              : LucideIcons.list,
                        ),
                        onPressed: () => setState(() {
                          _viewMode = _viewMode == _ViewMode.grid
                              ? _ViewMode.list
                              : _ViewMode.grid;
                        }),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: catalog.when(
                    data: (List<CatalogPackage> packages) {
                      final List<CatalogPackage> visible = _visiblePackages(
                        packages,
                      );
                      if (visible.isEmpty) {
                        return const Center(child: Text('No matching apps'));
                      }
                      return RefreshIndicator(
                        onRefresh: () =>
                            ref.read(catalogProvider.notifier).refresh(),
                        child: _viewMode == _ViewMode.grid
                            ? _CatalogGrid(
                                packages: visible,
                                device: widget.device,
                                installedIds: installedIds,
                              )
                            : _CatalogList(
                                packages: visible,
                                device: widget.device,
                                installedIds: installedIds,
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

class _CatalogList extends StatelessWidget {
  const _CatalogList({
    required this.packages,
    required this.device,
    required this.installedIds,
  });

  final List<CatalogPackage> packages;
  final Device device;
  final Set<String> installedIds;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: packages.length,
      separatorBuilder: (BuildContext _, int _) => const SizedBox(height: 8),
      itemBuilder: (BuildContext context, int index) => _CatalogListTile(
        package: packages[index],
        device: device,
        installed: installedIds.contains(packages[index].id),
      ),
    );
  }
}

class _CatalogListTile extends StatelessWidget {
  const _CatalogListTile({
    required this.package,
    required this.device,
    required this.installed,
  });

  final CatalogPackage package;
  final Device device;
  final bool installed;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: _CatalogIcon(uri: package.iconUri, size: 48, radius: 14),
        title: Text(package.title),
        // Only passed when non-empty - an empty subtitle still reserves a
        // second line's worth of height, which is what made the title sit
        // off-center for entries with no description.
        subtitle: package.shortDescription.isEmpty
            ? null
            : Text(
                package.shortDescription,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
        trailing: installed
            ? Tooltip(
                message: 'Already installed',
                child: Icon(
                  LucideIcons.checkCircle,
                  color: theme.colorScheme.primary,
                ),
              )
            : null,
        onTap: () => _openDetail(context, package, device, installed),
      ),
    );
  }
}

/// Dismisses the keyboard before opening the detail sheet, and again once
/// it closes.
///
/// `FocusScope.unfocus()` alone didn't fix this: it clears the *current*
/// focus but leaves the search field remembered as the scope's
/// `focusedChild`, so Flutter's own route-pop focus restoration handed
/// the keyboard straight back the instant the sheet closed - the actual
/// mechanism behind "tap a result, dismiss the sheet, keyboard pops back
/// up". Handing focus to a disposable, unattached `FocusNode()` instead
/// overwrites that memory with nothing to restore back to. Applied both
/// before showing the sheet and after it closes, since either point
/// could otherwise re-establish it.
Future<void> _openDetail(
  BuildContext context,
  CatalogPackage package,
  Device device,
  bool installed,
) async {
  FocusScope.of(context).requestFocus(FocusNode());
  await _CatalogDetailSheet.show(
    context,
    package: package,
    device: device,
    installed: installed,
  );
  if (context.mounted) {
    FocusScope.of(context).requestFocus(FocusNode());
  }
}

class _CatalogGrid extends StatelessWidget {
  const _CatalogGrid({
    required this.packages,
    required this.device,
    required this.installedIds,
  });

  final List<CatalogPackage> packages;
  final Device device;
  final Set<String> installedIds;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      // A fixed mainAxisExtent, not childAspectRatio: the grid hands each
      // tile a TIGHT box (aspect ratio or not), and this tile's own
      // content is mainAxisSize.min - so an aspect ratio that guessed too
      // tall left genuine empty space pooling at the bottom of every
      // tile, under the top-aligned icon+title. Sizing the box to match
      // the content's actual height (icon + gap + up to 2 title lines +
      // padding) removes that leftover space instead of centering it.
      // 132 undershot by 2px on a real device (system font scale pushes
      // bodyMedium's two lines slightly taller than the plain estimate),
      // so this carries a bit more headroom than the bare calculation.
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 8,
        mainAxisExtent: 144,
      ),
      itemCount: packages.length,
      itemBuilder: (BuildContext context, int index) => _CatalogGridTile(
        package: packages[index],
        device: device,
        installed: installedIds.contains(packages[index].id),
      ),
    );
  }
}

class _CatalogGridTile extends StatelessWidget {
  const _CatalogGridTile({
    required this.package,
    required this.device,
    required this.installed,
  });

  final CatalogPackage package;
  final Device device;
  final bool installed;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => _openDetail(context, package, device, installed),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                _CatalogIcon(uri: package.iconUri, size: 64, radius: 18),
                if (installed)
                  Positioned(
                    right: -4,
                    bottom: -4,
                    child: Tooltip(
                      message: 'Already installed',
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color:
                                theme.cardTheme.color ??
                                theme.colorScheme.surface,
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          LucideIcons.check600,
                          size: 13,
                          color: theme.colorScheme.onPrimary,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              package.title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _CatalogIcon extends StatelessWidget {
  const _CatalogIcon({
    required this.uri,
    required this.size,
    required this.radius,
  });

  final String? uri;
  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) {
    if (uri == null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Container(
          width: size,
          height: size,
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: const Icon(LucideIcons.appWindow),
        ),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Image.network(
        uri!,
        width: size,
        height: size,
        errorBuilder: (BuildContext _, Object _, StackTrace? _) =>
            const Icon(LucideIcons.appWindow),
      ),
    );
  }
}

class _CatalogDetailSheet extends ConsumerWidget {
  const _CatalogDetailSheet({
    required this.package,
    required this.device,
    required this.installed,
  });

  final CatalogPackage package;
  final Device device;
  final bool installed;

  static Future<void> show(
    BuildContext context, {
    required CatalogPackage package,
    required Device device,
    required bool installed,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (BuildContext _) => _CatalogDetailSheet(
        package: package,
        device: device,
        installed: installed,
      ),
    );
  }

  // Takes the services themselves, not a WidgetRef: this is an async*
  // generator, so its body (including everything past the first await)
  // keeps running long after the Install button's own onPressed returns -
  // well past the point this sheet is popped and its ref becomes unsafe
  // to touch. The onPressed handler below reads these out while the ref
  // is still good and hands them in as plain values instead.
  Stream<LunaOperationProgress> _installStream(
    AppCatalogService catalogService,
    AppsService appsService,
  ) async* {
    yield const LunaOperationWorking('Downloading...');
    final Uint8List bytes = await catalogService.downloadAndVerify(
      package.manifest,
    );
    yield* appsService.installBytes(device, bytes);
  }

  /// One field per line (size, requirements, id), each with its own
  /// small icon - a plain Column of rows, not a shared wrapping
  /// paragraph, so every field reads as its own clean line rather than
  /// flowing into the next one.
  Widget _factsColumn(ThemeData theme, TextStyle? mutedStyle) {
    final CatalogManifest manifest = package.manifest;
    final List<Widget> rows = [];

    void addFact(IconData icon, String text, {TextStyle? style}) {
      rows.add(
        Padding(
          padding: EdgeInsets.only(top: rows.isEmpty ? 0 : 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // A couple of px down from a plain top-align: the icon's
              // own glyph box has no leading space above it, while the
              // text next to it does (ordinary font metrics), so lining
              // up both boxes' tops left the icon reading visibly higher
              // than the text's own first line.
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Icon(icon, size: 15, color: theme.colorScheme.primary),
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(text, style: style ?? mutedStyle)),
            ],
          ),
        ),
      );
    }

    // Just the size, no "download" label: the icon already says what it
    // is, and it's the only one of these that needs no qualifier at all.
    addFact(LucideIcons.download, _formatBytes(manifest.ipkSize));
    if (manifest.installedSize != null) {
      addFact(
        LucideIcons.hardDrive,
        '${_formatBytes(manifest.installedSize!)} installed',
      );
    }
    if (package.minWebosRelease != null) {
      addFact(LucideIcons.tv, 'webOS ${package.minWebosRelease}');
    }
    addFact(
      LucideIcons.hash,
      package.id,
      style: mutedStyle?.copyWith(fontFamily: 'monospace'),
    );
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: rows);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final CatalogManifest manifest = package.manifest;
    final String? sourceUrl = manifest.sourceUrl;
    final bool canInstall = manifest.ipkSha256 != null;
    final TextStyle? mutedStyle = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final Widget? sourceButton = sourceUrl == null
        ? null
        : TextButton.icon(
            onPressed: () => launchUrl(
              Uri.parse(sourceUrl),
              mode: LaunchMode.externalApplication,
            ),
            icon: const Icon(LucideIcons.externalLink, size: 16),
            label: const Text('Source'),
          );

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _CatalogIcon(
                  uri: package.detailIconUri ?? package.iconUri,
                  size: 56,
                  radius: 16,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(package.title, style: theme.textTheme.titleLarge),
                      Text(
                        'v${manifest.version}'
                        '${package.openSource ? ' · Open source' : ''}',
                        style: mutedStyle,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              manifest.appDescription.isEmpty
                  ? package.shortDescription
                  : manifest.appDescription,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            _factsColumn(theme, mutedStyle),
            if (manifest.rootRequired) ...[
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    LucideIcons.shieldAlert,
                    size: 18,
                    color: theme.colorScheme.error,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Needs root access on the TV to work.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 20),
            // Checked before the missing-checksum case below: whether
            // this package can be installed at all is moot once it
            // already is. Source still shows either way - it's
            // unrelated to whether installing is possible right now.
            if (installed) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    LucideIcons.checkCircle,
                    size: 18,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Already installed on this TV.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
              if (sourceButton != null) ...[
                const SizedBox(height: 12),
                Align(alignment: Alignment.centerRight, child: sourceButton),
              ],
            ] else
            // A handful of real catalog entries publish no checksum to
            // verify against - installing one of those would mean silently
            // skipping the integrity check this whole flow exists to
            // enforce, so it's blocked here rather than left to fail
            // (or worse, succeed unverified) once Install is tapped.
            // Source still shows even then (own row): it's unrelated to
            // whether installing is possible.
            if (!canInstall) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    LucideIcons.circleAlert,
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
              ),
              if (sourceButton != null) ...[
                const SizedBox(height: 12),
                Align(alignment: Alignment.centerRight, child: sourceButton),
              ],
            ] else
              // End-aligned, not stretched to full width: easier to reach
              // with a thumb than a button spanning the sheet. Source
              // sits directly to Install's left, in the same row, rather
              // than as its own separate line above.
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (sourceButton != null) ...[
                    sourceButton,
                    const SizedBox(width: 8),
                  ],
                  FilledButton(
                    onPressed: () {
                      // Read out of ref while it's still valid, before
                      // popping this sheet - see _installStream's own
                      // comment for why.
                      final AppCatalogService catalogService = ref.read(
                        appCatalogServiceProvider,
                      );
                      final AppsService appsService = ref.read(
                        appsServiceProvider,
                      );
                      final AppOperationController installController = ref
                          .read(installOperationProvider.notifier);
                      Navigator.of(context).pop();
                      OperationProgressDialog.show(
                        context,
                        provider: installOperationProvider,
                        title: 'Installing ${package.title}...',
                        run: () => installController.run(
                          _installStream(catalogService, appsService),
                        ),
                      );
                    },
                    child: const Text('Install'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

/// Formats a byte count for display, e.g. `7.1 MB` or `108 KB`.
String _formatBytes(int bytes) {
  if (bytes < 1024) {
    return '$bytes B';
  }
  final double kb = bytes / 1024;
  if (kb < 1024) {
    return '${kb.toStringAsFixed(kb < 10 ? 1 : 0)} KB';
  }
  final double mb = kb / 1024;
  return '${mb.toStringAsFixed(mb < 10 ? 1 : 0)} MB';
}
