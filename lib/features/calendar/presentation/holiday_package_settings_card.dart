import 'package:flutter/material.dart';
import 'package:planact/app/theme/planact_spacing.dart';
import 'package:planact/core/localization/persian_numbers.dart';
import 'package:planact/features/calendar/application/holiday_package_service.dart';
import 'package:planact/features/calendar/domain/holiday_data_package.dart';

class HolidayPackageSettingsCard extends StatefulWidget {
  const HolidayPackageSettingsCard({
    super.key,
    required this.service,
    required this.onInstalled,
  });
  final HolidayPackageService service;
  final VoidCallback onInstalled;
  @override
  State<HolidayPackageSettingsCard> createState() =>
      _HolidayPackageSettingsCardState();
}

class _HolidayPackageSettingsCardState
    extends State<HolidayPackageSettingsCard> {
  bool _busy = false;
  String? _message;

  Future<void> _import() async {
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final package = await widget.service.prepare();
      if (!mounted || package == null) return;
      final first = widget.service.needsPublisherApproval(package);
      final approved = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('تأیید بستهٔ تعطیلات'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'سال ${PersianNumbers.format(package.year)} · نسخه ${PersianNumbers.format(package.revision)}',
                ),
                Text('منبع: ${package.source}'),
                const Text('اثر انگشت ناشر:'),
                SelectableText(
                  package.fingerprint,
                  textDirection: TextDirection.ltr,
                ),
                Text(
                  first
                      ? 'این ناشر هنوز مورد اعتماد شما نیست. اثر انگشت را از یک مسیر مستقل با ناشر بررسی کنید. تأیید، این کلید را برای بسته‌های بعدی مورد اعتماد قرار می‌دهد؛ امضا به معنی تأیید رسمی منبع نیست.'
                      : 'امضا با ناشر مورد اعتماد یکسان است. دادهٔ این سال جایگزین می‌شود.',
                ),
                const Text(
                  'رخدادها، یادآورها و سوابق شما تغییر نمی‌کنند. بسته‌ها در نسخهٔ پشتیبان شخصی نیستند؛ فایل اصلی را نگه دارید.',
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
              onPressed: () => Navigator.pop(context, true),
              child: Text(first ? 'تأیید ناشر و ورود بسته' : 'ورود بسته'),
            ),
          ],
        ),
      );
      if (!mounted || approved != true) return;
      await widget.service.install(
        package,
        publisherApproved: approved == true,
      );
      if (!mounted) return;
      setState(
        () => _message = 'بستهٔ تعطیلات ذخیره شد و بدون اینترنت در دسترس است.',
      );
      widget.onInstalled();
    } on HolidayPackageException catch (error) {
      if (mounted) setState(() => _message = error.message);
    } catch (_) {
      if (mounted) {
        setState(
          () => _message = 'ورود بسته انجام نشد. فایل و فضای ذخیره‌سازی را بررسی کنید؛ دادهٔ قبلی حفظ شده است.',
        );
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
          leading: const Icon(Icons.event_available_outlined),
          title: const Text('دادهٔ تعطیلات'),
          subtitle: Text(
            widget.service.packages.isEmpty
                ? 'دادهٔ پایه تا سال ۱۴۰۵؛ ورود سال‌های جدید بدون به‌روزرسانی برنامه'
                : 'بسته‌های نصب‌شده: ${widget.service.packages.map((p) => PersianNumbers.format(p.year)).join('، ')}',
          ),
        ),
        if (widget.service.loadError != null)
          Padding(
            padding: const EdgeInsets.all(PlanActSpacing.lg),
            child: Text(widget.service.loadError!),
          ),
        if (_message != null)
          Padding(
            padding: const EdgeInsets.all(PlanActSpacing.lg),
            child: Text(_message!, semanticsLabel: _message),
          ),
        Padding(
          padding: const EdgeInsets.all(PlanActSpacing.lg),
          child: FilledButton.tonalIcon(
            onPressed: _busy ? null : _import,
            icon: _busy
                ? const CircularProgressIndicator(
                    semanticsLabel: 'در حال بررسی و ذخیرهٔ بسته',
                  )
                : const Icon(Icons.file_open_outlined),
            label: Text(_busy ? 'در حال ورود بسته…' : 'ورود بسته از فایل'),
          ),
        ),
      ],
    ),
  );
}
