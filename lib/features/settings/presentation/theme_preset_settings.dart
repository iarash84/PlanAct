import 'package:flutter/material.dart';
import 'package:planact/app/theme/planact_colors.dart';
import 'package:planact/app/theme/planact_spacing.dart';
import 'package:planact/app/theme/planact_radius.dart';
import 'package:planact/app/theme/theme_preset.dart';
import 'package:planact/app/theme/theme_preset_controller.dart';
import 'package:planact/core/localization/planact_localizations.dart';

/// Wraps naturally at narrow widths and large text scales.
class ThemePresetSettings extends StatelessWidget {
  const ThemePresetSettings({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = ThemePresetScope.maybeOf(context);
    if (controller == null) return const SizedBox.shrink();
    final l10n = planActL10n(context);
    final theme = Theme.of(context);
    final labels = {
      ThemePreset.original: l10n.settingsPaletteOriginal,
      ThemePreset.blue: l10n.settingsPaletteBlue,
      ThemePreset.purple: l10n.settingsPalettePurple,
      ThemePreset.earth: l10n.settingsPaletteEarth,
    };
    return Padding(
      padding: const EdgeInsets.all(PlanActSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.settingsPaletteTitle, style: theme.textTheme.titleMedium),
          const SizedBox(height: PlanActSpacing.sm),
          Text(l10n.settingsPaletteDescription),
          const SizedBox(height: PlanActSpacing.sm),
          LayoutBuilder(
            builder: (context, constraints) {
              final minimumWidth = MediaQuery.textScalerOf(context).scale(140);
              final twoColumns =
                  constraints.maxWidth >= minimumWidth * 2 + PlanActSpacing.md;
              final width = twoColumns
                  ? (constraints.maxWidth - PlanActSpacing.md) / 2
                  : constraints.maxWidth;
              return Wrap(
                spacing: PlanActSpacing.md,
                runSpacing: PlanActSpacing.md,
                children: [
                  for (final preset in ThemePreset.values)
                    SizedBox(
                      width: width,
                      child: _PresetTile(
                        label: labels[preset]!,
                        preset: preset,
                        selected: controller.preset == preset,
                        onTap: controller.ready && !controller.busy
                            ? () => controller.select(preset)
                            : null,
                      ),
                    ),
                ],
              );
            },
          ),
          if (controller.busy) const LinearProgressIndicator(),
          if (controller.loadFailed) ...[
            Text(
              l10n.settingsPaletteLoadError,
              semanticsLabel: l10n.settingsPaletteLoadError,
            ),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton(
                onPressed: controller.busy ? null : controller.load,
                child: Text(l10n.commonRetry),
              ),
            ),
          ],
          if (controller.saveFailed)
            Semantics(
              liveRegion: true,
              child: Text(
                l10n.settingsPaletteSaveError,
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ),
        ],
      ),
    );
  }
}

class _PresetTile extends StatelessWidget {
  const _PresetTile({
    required this.label,
    required this.preset,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final ThemePreset preset;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Semantics(
      key: ValueKey('theme-preset-${preset.storageValue}'),
      label: label,
      button: true,
      selected: selected,
      enabled: onTap != null,
      onTap: onTap,
      excludeSemantics: true,
      child: Material(
        color: selected ? scheme.primaryContainer : scheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: PlanActRadius.input,
          side: BorderSide(
            color: selected ? scheme.primary : scheme.outlineVariant,
            width: selected ? 2 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          borderRadius: PlanActRadius.input,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(PlanActSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _PalettePreview(
                  scheme: PlanActColors.scheme(
                    theme.brightness,
                    preset: preset,
                  ),
                ),
                const SizedBox(height: PlanActSpacing.sm),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        label,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: selected
                              ? scheme.onPrimaryContainer
                              : scheme.onSurface,
                        ),
                      ),
                    ),
                    const SizedBox(width: PlanActSpacing.xs),
                    Icon(
                      selected
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      color: selected
                          ? scheme.primary
                          : scheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Decorative miniature only: no domain data or nested interactive controls.
/// Its fixed geometry illustrates the same interface in each actual palette.
class _PalettePreview extends StatelessWidget {
  const _PalettePreview({required this.scheme});

  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Container(
      key: ValueKey('palette-preview-${scheme.primary.toARGB32()}'),
      height: 112,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: PlanActRadius.chip,
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(PlanActSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FractionallySizedBox(
                    widthFactor: .45,
                    child: _PreviewBar(color: scheme.onSurface, height: 5),
                  ),
                  const SizedBox(height: PlanActSpacing.sm),
                  Container(
                    padding: const EdgeInsets.all(PlanActSpacing.sm),
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainer,
                      borderRadius: PlanActRadius.chip,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.event_outlined,
                          size: 16,
                          color: scheme.primary,
                        ),
                        const SizedBox(width: PlanActSpacing.sm),
                        Expanded(
                          child: _PreviewBar(color: scheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: PlanActSpacing.sm),
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: Container(
                      width: 36,
                      height: 16,
                      decoration: BoxDecoration(
                        color: scheme.primary,
                        borderRadius: PlanActRadius.chip,
                      ),
                      child: Icon(Icons.add, size: 12, color: scheme.onPrimary),
                    ),
                  ),
                ],
              ),
            ),
          ),
          ColoredBox(
            color: scheme.surfaceContainer,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: PlanActSpacing.xs),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Container(
                    width: 32,
                    decoration: BoxDecoration(
                      color: scheme.primaryContainer,
                      borderRadius: PlanActRadius.chip,
                    ),
                    child: Icon(
                      Icons.home_outlined,
                      size: 16,
                      color: scheme.onPrimaryContainer,
                    ),
                  ),
                  Icon(
                    Icons.calendar_month_outlined,
                    size: 16,
                    color: scheme.onSurfaceVariant,
                  ),
                  Icon(
                    Icons.more_horiz,
                    size: 16,
                    color: scheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _PreviewBar extends StatelessWidget {
  const _PreviewBar({required this.color, this.height = 4});

  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) => Container(
    height: height,
    decoration: BoxDecoration(color: color, borderRadius: PlanActRadius.chip),
  );
}
