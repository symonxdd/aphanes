import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../state/seed_color_controller.dart';

/// A curated spread across the hue wheel, the brand default first. Each is
/// just a seed - [ColorScheme.fromSeed] handles turning any of these into
/// a full, correctly-toned light/dark palette regardless of how saturated
/// the input itself is.
const List<Color> _presetColors = [
  AppTheme.seed,
  Color(0xFFEA580C),
  Color(0xFFF59E0B),
  Color(0xFF16A34A),
  Color(0xFF0D9488),
  Color(0xFF2563EB),
  Color(0xFF4F46E5),
  Color(0xFFDB2777),
  Color(0xFF475569),
];

class AccentColorSheet extends ConsumerWidget {
  const AccentColorSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (BuildContext _) => const AccentColorSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final Color current = ref.watch(seedColorProvider);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Accent color', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 4),
            Text(
              'Regenerates the whole app\'s palette from a single color, '
              'so every screen stays consistent.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final Color preset in _presetColors)
                  _SwatchDot(
                    color: preset,
                    selected: preset.toARGB32() == current.toARGB32(),
                    onTap: () =>
                        ref.read(seedColorProvider.notifier).set(preset),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: () => _pickCustomColor(context, ref, current),
              icon: const Icon(Icons.colorize_outlined),
              label: const Text('Custom color'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickCustomColor(
    BuildContext context,
    WidgetRef ref,
    Color current,
  ) async {
    final Color? picked = await showDialog<Color>(
      context: context,
      builder: (BuildContext context) => _CustomColorDialog(initial: current),
    );
    if (picked != null) {
      await ref.read(seedColorProvider.notifier).set(picked);
    }
  }
}

class _SwatchDot extends StatelessWidget {
  const _SwatchDot({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: selected
              ? Border.all(
                  color: Theme.of(context).colorScheme.onSurface,
                  width: 2,
                )
              : null,
        ),
        child: selected
            ? Icon(
                Icons.check,
                color: ThemeData.estimateBrightnessForColor(color) ==
                        Brightness.dark
                    ? Colors.white
                    : Colors.black,
              )
            : null,
      ),
    );
  }
}

class _CustomColorDialog extends StatefulWidget {
  const _CustomColorDialog({required this.initial});

  final Color initial;

  @override
  State<_CustomColorDialog> createState() => _CustomColorDialogState();
}

class _CustomColorDialogState extends State<_CustomColorDialog> {
  late Color _pickedColor = widget.initial;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Custom accent color'),
      content: SingleChildScrollView(
        child: ColorPicker(
          pickerColor: _pickedColor,
          onColorChanged: (Color color) =>
              setState(() => _pickedColor = color),
          enableAlpha: false,
          labelTypes: const [],
          pickerAreaHeightPercent: 0.7,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () =>
              setState(() => _pickedColor = AppTheme.seed),
          child: const Text('Reset to default'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_pickedColor),
          child: const Text('Select'),
        ),
      ],
    );
  }
}
