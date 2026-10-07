import 'package:flutter/material.dart';
import 'package:planact/app/theme/planact_spacing.dart';
import 'package:planact/features/backup/application/backup_actions.dart';

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
              ? 'تمام اطلاعات فعلی با اطلاعات فایل جایگزین می‌شود. پیش از جایگزینی، نسخه ایمنی ساخته می‌شود. فقط فایل همین نصب و کلید موجود روی همین دستگاه قابل بازیابی است.'
              : 'این فایل حاوی اطلاعات شخصی و مالی رمزنگاری‌شده است؛ آن را در محل امن نگه دارید. متن خام پیامک‌ها صادر نمی‌شود. کلید در همین نصب نگه‌داری می‌شود؛ پس از حذف برنامه یا روی دستگاه دیگر این فایل قابل بازیابی نیست.',
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
      final success = importing
          ? await widget.actions.importBackup()
          : await widget.actions.exportBackup();
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
          _error = 'عملیات انجام نشد. فایل و فضای ذخیره‌سازی را بررسی کنید. بازیابی به کلید همین نصب نیاز دارد.';
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
