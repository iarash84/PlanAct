import 'package:planact/core/localization/planact_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:planact/app/theme/planact_spacing.dart';
import 'package:planact/features/backup/domain/backup_recovery_key.dart';

Future<bool> confirmRecoveryKey(BuildContext context, String key) async {
  var acknowledged = false;
  var copying = false;
  String? copyFeedback;
  return await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: Text(
              planActL10n(context).recoveryKeyDialogsConfirmRecoveryKeyTitle,
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    planActL10n(context)
                        .recoveryKeyDialogsConfirmRecoveryKeyChildren,
                  ),
                  const SizedBox(height: PlanActSpacing.md),
                  Text(
                    planActL10n(context)
                        .recoveryKeyDialogsConfirmRecoveryKeyChildren2,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: PlanActSpacing.md),
                  Wrap(
                    spacing: PlanActSpacing.sm,
                    runSpacing: PlanActSpacing.sm,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      SelectableText(key, textDirection: TextDirection.ltr),
                      OutlinedButton.icon(
                        onPressed: copying
                            ? null
                            : () async {
                                if (copying) return;
                                final l10n = planActL10n(context);
                                setState(() {
                                  copying = true;
                                  copyFeedback = null;
                                });
                                String feedback;
                                try {
                                  await Clipboard.setData(
                                    ClipboardData(text: key),
                                  );
                                  feedback = l10n
                                      .recoveryKeyDialogsConfirmRecoveryKeyOnPressed;
                                } catch (_) {
                                  feedback = l10n
                                      .recoveryKeyDialogsConfirmRecoveryKeyOnPressed2;
                                }
                                if (!context.mounted) return;
                                setState(() {
                                  copying = false;
                                  copyFeedback = feedback;
                                });
                              },
                        icon: const Icon(Icons.copy_outlined),
                        label: Text(
                          planActL10n(context)
                              .recoveryKeyDialogsConfirmRecoveryKeyLabel,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: PlanActSpacing.sm),
                  Text(
                    planActL10n(context)
                        .recoveryKeyDialogsConfirmRecoveryKeyChildren3,
                  ),
                  if (copying || copyFeedback != null) ...[
                    const SizedBox(height: PlanActSpacing.sm),
                    Semantics(
                      liveRegion: true,
                      child: Text(
                        copying
                            ? planActL10n(context)
                                  .recoveryKeyDialogsConfirmRecoveryKeyChildren4
                            : copyFeedback!,
                      ),
                    ),
                  ],
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      planActL10n(context)
                          .recoveryKeyDialogsConfirmRecoveryKeyTitle2,
                    ),
                    value: acknowledged,
                    onChanged: (value) =>
                        setState(() => acknowledged = value == true),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(planActL10n(context).commonCancel),
              ),
              FilledButton(
                onPressed: acknowledged
                    ? () => Navigator.pop(context, true)
                    : null,
                child: Text(
                  planActL10n(context)
                      .recoveryKeyDialogsConfirmRecoveryKeyActions,
                ),
              ),
            ],
          ),
        ),
      ) ??
      false;
}

Future<String?> requestRecoveryKey(BuildContext context) async {
  final controller = TextEditingController();
  String? error;
  try {
    return await showDialog<String>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(
            planActL10n(context).recoveryKeyDialogsRequestRecoveryKeyTitle,
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  planActL10n(context)
                      .recoveryKeyDialogsRequestRecoveryKeyChildren,
                ),
                const SizedBox(height: PlanActSpacing.md),
                TextField(
                  controller: controller,
                  textDirection: TextDirection.ltr,
                  autocorrect: false,
                  enableSuggestions: false,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: planActL10n(context)
                        .recoveryKeyDialogsRequestRecoveryKeyLabelText,
                    errorText: error,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(planActL10n(context).commonCancel),
            ),
            FilledButton(
              onPressed: () {
                try {
                  final key = BackupRecoveryKey.parse(controller.text);
                  key.dispose();
                  Navigator.pop(context, controller.text.trim());
                } catch (_) {
                  setState(
                    () =>
                        error = planActL10n(context)
                            .recoveryKeyDialogsRequestRecoveryKeyOnPressed,
                  );
                }
              },
              child: Text(
                planActL10n(context)
                    .recoveryKeyDialogsRequestRecoveryKeyActions,
              ),
            ),
          ],
        ),
      ),
    );
  } finally {
    // Dialog route may still be animating out; dispose after its frame.
    controller.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) => controller.dispose());
  }
}

Future<bool> confirmLegacyBackup(BuildContext context) async =>
    await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          planActL10n(context).recoveryKeyDialogsConfirmLegacyBackupTitle,
        ),
        content: Text(
          planActL10n(context).recoveryKeyDialogsConfirmLegacyBackupContent,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(planActL10n(context).commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              planActL10n(context).recoveryKeyDialogsConfirmLegacyBackupActions,
            ),
          ),
        ],
      ),
    ) ??
    false;
