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
            title: const Text('کلید بازیابی این نسخه'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'این کلید را در محل امن و جدا از فایل پشتیبان نگه دارید. '
                    'هر نسخه کلید تازه‌ای دارد. برای بازیابی روی نصب جدید فقط فایل و همین کلید لازم است. '
                    'برنامه کلید را نگه نمی‌دارد.',
                  ),
                  const SizedBox(height: PlanActSpacing.md),
                  Text(
                    'اگر کلید گم شود، این نسخهٔ پشتیبان دیگر قابل بازیابی نیست.',
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
                                setState(() {
                                  copying = true;
                                  copyFeedback = null;
                                });
                                String feedback;
                                try {
                                  await Clipboard.setData(
                                    ClipboardData(text: key),
                                  );
                                  feedback = 'کلید کپی شد.';
                                } catch (_) {
                                  feedback =
                                      'کپی کلید انجام نشد. دوباره تلاش کنید.';
                                }
                                if (!context.mounted) return;
                                setState(() {
                                  copying = false;
                                  copyFeedback = feedback;
                                });
                              },
                        icon: const Icon(Icons.copy_outlined),
                        label: const Text('کپی کلید'),
                      ),
                    ],
                  ),
                  const SizedBox(height: PlanActSpacing.sm),
                  const Text(
                    'کلید حساس است؛ برنامه‌های دیگر ممکن است به کلیپ‌بورد دسترسی داشته باشند.',
                  ),
                  if (copying || copyFeedback != null) ...[
                    const SizedBox(height: PlanActSpacing.sm),
                    Semantics(
                      liveRegion: true,
                      child: Text(copying ? 'در حال کپی کلید…' : copyFeedback!),
                    ),
                  ],
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'کلید را جدا و امن نگه داشتم و خطر گم‌شدن آن را می‌پذیرم.',
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
                child: const Text('انصراف'),
              ),
              FilledButton(
                onPressed: acknowledged
                    ? () => Navigator.pop(context, true)
                    : null,
                child: const Text('ادامه و ذخیره فایل'),
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
          title: const Text('ورود کلید بازیابی'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'کلید همین فایل را وارد کنید. بدون کلید درست، اطلاعات فعلی جایگزین نمی‌شود.',
                ),
                const SizedBox(height: PlanActSpacing.md),
                TextField(
                  controller: controller,
                  textDirection: TextDirection.ltr,
                  autocorrect: false,
                  enableSuggestions: false,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'کلید بازیابی',
                    errorText: error,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('انصراف'),
            ),
            FilledButton(
              onPressed: () {
                try {
                  final key = BackupRecoveryKey.parse(controller.text);
                  key.dispose();
                  Navigator.pop(context, controller.text.trim());
                } catch (_) {
                  setState(() => error = 'کلید کامل و دقیق را وارد کنید.');
                }
              },
              child: const Text('بازیابی با این کلید'),
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
        title: const Text('نسخه قدیمی وابسته به نصب'),
        content: const Text(
          'این فایل قالب ۱ است و فقط با کلید نصب اصلی بازیابی می‌شود. '
          'کلید بازیابی جدید برای آن کار نمی‌کند. پس از حذف نصب یا از دست رفتن دستگاه ممکن است قابل بازیابی نباشد. '
          'فایل قدیمی بازنویسی نمی‌شود.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('انصراف'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('ادامه با کلید نصب اصلی'),
          ),
        ],
      ),
    ) ??
    false;
