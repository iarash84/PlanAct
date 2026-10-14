import 'package:planact/core/localization/planact_localizations.dart';
import 'package:planact/core/localization/persian_copy.g.dart';
import 'package:flutter/material.dart';
import 'package:planact/app/theme/planact_spacing.dart';
import 'package:planact/features/backup/application/backup_actions.dart';
import 'package:planact/features/backup/application/recovery_backup_actions.dart';
import 'package:planact/features/backup/presentation/recovery_key_dialogs.dart';

class BackupSettingsCard extends StatefulWidget {
  const BackupSettingsCard({super.key, required this.actions, this.message});
  final BackupActions actions;
  final String? message;
  @override
  State<BackupSettingsCard> createState() => _BackupSettingsCardState();
}

class _BackupSettingsCardState extends State<BackupSettingsCard> {
  bool _busy = false;
  String? _error;
  bool? _retryImport;

  Future<void> _run(bool importing) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          importing
              ? PersianCopy.backupSettingsCardConfirmedTitle
              : PersianCopy.backupSettingsCardConfirmedTitle2,
        ),
        content: Text(
          importing
              ? PersianCopy.backupSettingsCardConfirmedContent
              : PersianCopy.backupSettingsCardConfirmedContent2,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(PersianCopy.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              importing
                  ? PersianCopy.backupSettingsCardConfirmedActions
                  : PersianCopy.backupSettingsCardConfirmedActions2,
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final actions = widget.actions;
      final bool success;
      if (actions is RecoveryBackupActions) {
        success = importing
            ? await actions.importRecoveryBackup(
                requestKey: () async =>
                    mounted ? requestRecoveryKey(context) : null,
                confirmLegacy: () async =>
                    mounted ? confirmLegacyBackup(context) : false,
              )
            : await actions.exportRecoveryBackup(
                (key) async =>
                    mounted ? confirmRecoveryKey(context, key) : false,
              );
      } else {
        success = importing
            ? await actions.importBackup()
            : await actions.exportBackup();
      }
      if (mounted && success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              importing
                  ? PersianCopy.backupSettingsCardRunContent
                  : PersianCopy.backupSettingsCardRunContent2,
            ),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _retryImport = importing;
          _error = PersianCopy.backupSettingsCardRunMessage;
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Card(
    child: Column(
      children: [
        ListTile(
          leading: const Icon(Icons.backup_outlined),
          title: Text(planActL10n(context).backupSettingsCardBuildTitle),
          subtitle: Text(
            widget.message ??
                planActL10n(context).backupSettingsCardBuildSubtitle,
          ),
        ),
        if (_busy)
          LinearProgressIndicator(
            semanticsLabel: planActL10n(context)
                .backupSettingsCardBuildSemanticsLabel,
          ),
        ListTile(
          leading: const Icon(Icons.file_upload_outlined),
          title: Text(planActL10n(context).fileBackupActionsPathDialogTitle),
          enabled: !_busy,
          onTap: _busy ? null : () => _run(false),
        ),
        ListTile(
          leading: const Icon(Icons.file_download_outlined),
          title: Text(planActL10n(context).backupSettingsCardBuildTitle2),
          enabled: !_busy,
          onTap: _busy ? null : () => _run(true),
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.all(PlanActSpacing.md),
            child: Column(
              children: [
                Text(_error!),
                TextButton(
                  onPressed: _busy ? null : () => _run(_retryImport!),
                  child: Text(planActL10n(context).commonRetry),
                ),
              ],
            ),
          ),
      ],
    ),
  );
}
