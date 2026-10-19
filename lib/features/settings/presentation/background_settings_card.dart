import 'dart:async';

import 'package:flutter/material.dart';
import 'package:planact/app/app_settings.dart';
import 'package:planact/app/theme/planact_radius.dart';
import 'package:planact/app/theme/planact_spacing.dart';
import 'package:planact/core/localization/planact_localizations.dart';

class BackgroundSettingsCard extends StatefulWidget {
  const BackgroundSettingsCard({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final AppBackground value;
  final Future<void> Function(AppBackground background) onChanged;

  @override
  State<BackgroundSettingsCard> createState() => _BackgroundSettingsCardState();
}

class _BackgroundSettingsCardState extends State<BackgroundSettingsCard> {
  late AppBackground _selected;
  bool _saving = false;
  bool _saveFailed = false;

  @override
  void initState() {
    super.initState();
    _selected = widget.value;
  }

  @override
  void didUpdateWidget(covariant BackgroundSettingsCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) _selected = widget.value;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = planActL10n(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.settingsBackground,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(l10n.settingsBackgroundDescription),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final background in AppBackground.values)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: _option(background, l10n),
                    ),
                  ),
              ],
            ),
            if (_saving) const LinearProgressIndicator(),
            if (_saveFailed)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  l10n.settingsBackgroundSaveError,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _option(AppBackground background, AppLocalizations l10n) {
    final theme = Theme.of(context);
    final selected = _selected == background;
    final label = _label(background, l10n);
    return Semantics(
      key: ValueKey('background-option-${background.storageValue}'),
      label: label,
      selected: selected,
      checked: selected,
      inMutuallyExclusiveGroup: true,
      container: true,
      child: InkWell(
        borderRadius: PlanActRadius.chip,
        onTap: _saving ? null : () => unawaited(_select(background)),
        child: AnimatedContainer(
          duration: PlanActMotion.duration(context, PlanActMotion.short),
          curve: PlanActMotion.curve,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(
              alpha: 0.24,
            ),
            borderRadius: PlanActRadius.chip,
            border: Border.all(
              color: selected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outlineVariant,
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: PlanActRadius.chip,
                    child: SizedBox(
                      width: double.infinity,
                      height: 76,
                      child: _preview(background),
                    ),
                  ),
                  if (selected)
                    PositionedDirectional(
                      top: 4,
                      end: 4,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(2),
                          child: Icon(
                            Icons.check,
                            key: ValueKey(
                              'background-selected-${background.storageValue}',
                            ),
                            size: 14,
                            color: theme.colorScheme.onPrimary,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: selected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface,
                  fontWeight: selected ? FontWeight.w600 : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _preview(AppBackground background) {
    final assetPath = background.assetPath;
    if (assetPath == null) {
      return ColoredBox(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: Center(
          child: Icon(
            Icons.wallpaper_outlined,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }
    return Image.asset(
      assetPath,
      fit: BoxFit.cover,
      cacheWidth: 160,
      excludeFromSemantics: true,
    );
  }

  String _label(AppBackground background, AppLocalizations l10n) =>
      switch (background) {
        AppBackground.none => l10n.settingsBackgroundNone,
        AppBackground.botanicalPaper => l10n.settingsBackgroundBotanical,
        AppBackground.persianWaves => l10n.settingsBackgroundPersianWaves,
        AppBackground.nightWaves => l10n.settingsBackgroundNightWaves,
      };

  Future<void> _select(AppBackground? background) async {
    final onChanged = widget.onChanged;
    if (background == null || background == _selected || _saving) {
      return;
    }
    setState(() {
      _saving = true;
      _saveFailed = false;
    });
    try {
      await onChanged(background);
      if (mounted) setState(() => _selected = background);
    } catch (_) {
      if (mounted) setState(() => _saveFailed = true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
