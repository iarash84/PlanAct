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
          importing ? 'بازیابی نسخه پشتیبان؟' : 'ذخیره نسخه پشتیبان؟',
        ),
        content: Text(
          importing
              ? 'تمام اطلاعات فعلی با اطلاعات فایل جایگزین می‌شود. پیش از جایگزینی، نسخه ایمنی ساخته می‌شود. فایل جدید به کلید بازیابی خودش نیاز دارد؛ فایل قدیمی فقط با کلید نصب اصلی قابل بازیابی است.'
              : 'این فایل حاوی اطلاعات شخصی و مالی رمزنگاری‌شده است؛ آن را در محل امن نگه دارید. متن خام پیامک‌ها صادر نمی‌شود. در مرحله بعد کلید مستقل این نسخه نمایش داده می‌شود؛ آن را جدا و امن نگه دارید.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('انصراف'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(importing ? 'تأیید بازیابی' : 'تأیید ذخیره'),
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
                  ? 'اطلاعات با موفقیت بازیابی شد.'
                  : 'نسخه پشتیبان ذخیره شد.',
            ),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _retryImport = importing;
          _error = 'عملیات انجام نشد. فایل، کلید بازیابی و فضای ذخیره‌سازی را بررسی کنید و دوباره تلاش کنید. فایل قدیمی به کلید نصب اصلی نیاز دارد.';
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
          title: const Text('پشتیبان‌گیری و بازیابی'),
          subtitle: Text(
            widget.message ?? 'نسخه رمزنگاری‌شده محلی؛ بدون متن خام پیامک',
          ),
        ),
        if (_busy)
          const LinearProgressIndicator(
            semanticsLabel: 'در حال پشتیبان‌گیری یا بازیابی',
          ),
        ListTile(
          leading: const Icon(Icons.file_upload_outlined),
          title: const Text('ذخیره نسخه پشتیبان'),
          enabled: !_busy,
          onTap: _busy ? null : () => _run(false),
        ),
        ListTile(
          leading: const Icon(Icons.file_download_outlined),
          title: const Text('بازیابی از فایل'),
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
                  child: const Text('تلاش دوباره'),
                ),
              ],
            ),
          ),
      ],
    ),
  );
}
