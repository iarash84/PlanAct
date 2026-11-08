import 'package:flutter/material.dart';
import 'package:planact/app/theme/planact_spacing.dart';
import 'package:planact/core/localization/planact_localizations.dart';
import 'package:planact/core/localization/persian_numbers.dart';
import 'package:planact/features/inbox/application/android_sms_source.dart';
import 'package:planact/features/inbox/application/inbox_use_cases.dart';
import 'package:planact/features/inbox/application/sms_ingestion.dart';
import 'package:planact/features/inbox/presentation/sms_scan_card.dart';
import 'package:planact/features/inbox/presentation/sms_sync_controller.dart';

/// One consent and daily-control surface. History remains an explicit action.
class SmsAutomaticSyncCard extends StatefulWidget {
  const SmsAutomaticSyncCard({
    super.key,
    required this.controller,
    required this.inbox,
    required this.source,
    required this.onCheck,
    required this.onChanged,
  });
  final SmsSyncController controller;
  final InboxUseCases inbox;
  final AndroidSmsSource source;
  final Future<void> Function() onCheck;
  final Future<void> Function() onChanged;

  @override
  State<SmsAutomaticSyncCard> createState() => _SmsAutomaticSyncCardState();
}

class _SmsAutomaticSyncCardState extends State<SmsAutomaticSyncCard> {
  late final Future<SmsScan?> _history = SmsIngestion(
    widget.inbox,
    widget.source,
  ).load();

  Future<void> _setup() async {
    final command = await showDialog<Future<void>>(
      context: context,
      builder: (context) => _SmsSetupDialog(
        onStart: (days, automatic) =>
            widget.controller.setup(days: days, automatic: automatic),
      ),
    );
    if (command == null) return;
    await command;
    if (!mounted) return;
    await widget.onChanged();
  }

  Future<void> _activate() async {
    final l10n = planActL10n(context);
    final command = await showDialog<Future<void>>(
      context: context,
      builder: (context) => AlertDialog(
        scrollable: true,
        title: Text(l10n.smsManualActivationTitle),
        content: Text(l10n.smsManualActivationBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () {
              final command = widget.controller.activateManualFromNow();
              Navigator.pop(context, command);
            },
            child: Text(l10n.smsManualActivate),
          ),
        ],
      ),
    );
    if (command == null) return;
    await command;
    if (!mounted) return;
    await widget.onChanged();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.controller,
    builder: (context, _) {
      final controller = widget.controller;
      final l10n = planActL10n(context);
      final available =
          controller.ready &&
          !controller.busy &&
          !controller.changing &&
          controller.access == true;
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(PlanActSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.smsControlsTitle,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (controller.access == true) Text(l10n.inboxPageBuildSubtitle4),
              if (!controller.manualReady)
                FutureBuilder<SmsScan?>(
                  future: _history,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Text(l10n.smsScanCardLoadMessage);
                    }
                    final legacyRange =
                        snapshot.data != null && !snapshot.data!.newOnly;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          legacyRange
                              ? l10n.smsManualActivationBody
                              : l10n.smsSetupDescription,
                        ),
                        FilledButton(
                          onPressed:
                              available &&
                                  snapshot.connectionState ==
                                      ConnectionState.done
                              ? (legacyRange ? _activate : _setup)
                              : null,
                          child: Text(
                            legacyRange
                                ? l10n.smsManualActivationTitle
                                : l10n.smsSetupOpen,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              OutlinedButton.icon(
                onPressed: available && controller.manualReady
                    ? widget.onCheck
                    : null,
                icon: const Icon(Icons.sync),
                label: Text(l10n.smsCheckNewMessages),
              ),
              if (controller.manualReady) ...[
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.smsAutomaticTitle),
                  value: controller.enabled,
                  onChanged:
                      controller.ready &&
                          !controller.busy &&
                          !controller.changing &&
                          (controller.enabled || controller.access == true)
                      ? controller.setEnabled
                      : null,
                ),
                Text(l10n.smsAutomaticDescription),
              ],
              if (controller.busy || controller.changing) ...[
                const LinearProgressIndicator(),
                Text(l10n.smsCheckingMessages),
              ],
              if (controller.access == false)
                Text(l10n.smsAutomaticPermissionRequired),
              if (controller.error != null)
                Semantics(liveRegion: true, child: Text(controller.error!)),
              if (controller.error == null &&
                  !controller.busy &&
                  controller.lastNewSuggestions != null)
                Semantics(
                  liveRegion: true,
                  child: Text(
                    controller.lastNewSuggestions == 0
                        ? l10n.smsNoNewSuggestions
                        : l10n.smsNewSuggestionsCount(
                            PersianNumbers.format(
                              controller.lastNewSuggestions.toString(),
                            ),
                          ),
                  ),
                ),
              FutureBuilder<SmsScan?>(
                future: _history,
                builder: (context, snapshot) {
                  if (!controller.manualReady && snapshot.data == null) {
                    return const SizedBox.shrink();
                  }
                  return ExpansionTile(
                    key: const PageStorageKey('inbox-sms-history'),
                    tilePadding: EdgeInsets.zero,
                    title: Text(l10n.smsOlderMessages),
                    children: [
                      SmsScanCard(
                        key: ValueKey(controller.revision),
                        inbox: widget.inbox,
                        source: widget.source,
                        access: available,
                        onChanged: widget.onChanged,
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _SmsSetupDialog extends StatefulWidget {
  const _SmsSetupDialog({required this.onStart});
  final Future<void> Function(int days, bool automatic) onStart;
  @override
  State<_SmsSetupDialog> createState() => _SmsSetupDialogState();
}

class _SmsSetupDialogState extends State<_SmsSetupDialog> {
  int? _days;
  bool _automatic = false;

  @override
  Widget build(BuildContext context) {
    final l10n = planActL10n(context);
    return AlertDialog(
      scrollable: true,
      title: Text(l10n.smsSetupOpen),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.smsSetupDescription),
          Wrap(
            spacing: PlanActSpacing.sm,
            children: [
              for (final option in [
                (7, l10n.smsScanCardDaysActions2),
                (30, l10n.smsScanCardDaysActions3),
                (0, l10n.smsScanCardDaysActions),
              ])
                ChoiceChip(
                  label: Text(option.$2),
                  selected: _days == option.$1,
                  onSelected: (_) => setState(() => _days = option.$1),
                ),
            ],
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.smsAutomaticTitle),
            value: _automatic,
            onChanged: (value) => setState(() => _automatic = value),
          ),
          Text(l10n.smsAutomaticDescription),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(
          onPressed: _days == null
              ? null
              : () {
                  final command = widget.onStart(_days!, _automatic);
                  Navigator.pop(context, command);
                },
          child: Text(l10n.smsSetupStart),
        ),
      ],
    );
  }
}
