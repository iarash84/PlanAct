import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:planact/app/theme/planact_radius.dart';
import 'package:planact/app/theme/planact_spacing.dart';
import 'package:planact/core/localization/persian_numbers.dart';

class AboutPage extends StatefulWidget {
  const AboutPage({super.key, this.loadPackageInfo = PackageInfo.fromPlatform});

  final Future<PackageInfo> Function() loadPackageInfo;

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  static bool _licenseRegistered = false;
  late Future<PackageInfo> _packageInfo;

  @override
  void initState() {
    super.initState();
    _packageInfo = widget.loadPackageInfo();
    if (!_licenseRegistered) {
      LicenseRegistry.addLicense(() async* {
        final text = await rootBundle.loadString('assets/licenses/planact.txt');
        yield LicenseEntryWithLineBreaks(['PlanAct'], text);
      });
      _licenseRegistered = true;
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('درباره پلن‌اکت')),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: PlanActSpacing.contentWidth,
        ),
        child: ListView(
          padding: const EdgeInsets.all(PlanActSpacing.page),
          children: [
            Center(
              child: ClipRRect(
                borderRadius: PlanActRadius.card,
                child: Image.asset(
                  'assets/icons/app_icon.png',
                  width: 96,
                  height: 96,
                  semanticLabel: 'نشان پلن‌اکت',
                ),
              ),
            ),
            const SizedBox(height: PlanActSpacing.lg),
            Text(
              'پلن‌اکت',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: PlanActSpacing.sm),
            const Text(
              'دستیار شخصی فارسی برای مدیریت تعهدها، برنامه‌ها و امور مالی روزمره؛ با تقویم شمسی و امکانات اصلی آفلاین.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: PlanActSpacing.xl),
            const _AboutSection(
              title: 'از برنامه تا واقعیت',
              text:
                  'چه چیزی قرار بود اتفاق بیفتد؟ در واقعیت چه اتفاقی افتاد؟ اکنون چه چیزی نیاز به توجه دارد؟\n'
                  'پلن‌اکت برنامه‌ریزی، زمان‌بندی، یادآوری، اقدام، ثبت نتیجه و تطبیق پرداخت‌ها را به هم پیوند می‌دهد تا بتوانید برنامه و عملکرد واقعی خود را کنار هم ببینید.',
            ),
            const _AboutSection(
              title: 'بخش‌های برنامه',
              text:
                  'امروز: مرور کارهای پیش رو و موارد نیازمند توجه.\n'
                  'تعهدها و تقویم: ثبت برنامه‌های یک‌باره و تکرارشونده، نمایش نوبت‌ها و ثبت نتیجهٔ آن‌ها.\n'
                  'اعتبار جلسات: پیگیری اعتبار و مصرف جلسات بسته‌ها، جدا از زمان‌بندی.\n'
                  'مالی: حساب‌ها، درآمد، هزینه، انتقال بین حساب‌ها و ارتباط پرداخت‌ها با تعهدها.\n'
                  'گزارش‌ها: مرور برنامه و عملکرد، پرداخت‌ها و گردش مالی در بازهٔ انتخابی.\n'
                  'صندوق ورودی: بررسی و تأیید پیشنهادهای استخراج‌شده از پیامک‌های بانکی.',
            ),
            const _AboutSection(
              title: 'حریم خصوصی و دسترسی‌ها',
              text:
                  'اطلاعات شخصی و مالی به‌صورت پیش‌فرض روی دستگاه شما نگهداری می‌شود. استفاده از امکانات اصلی به حساب ابری یا اینترنت نیاز ندارد.\n'
                  'خواندن پیامک‌های بانکی با اجازهٔ شما و انتخاب محدودهٔ ورود انجام می‌شود؛ پیشنهادها پیش از ثبت مالی نیاز به بررسی و تأیید دارند.\n'
                  'برای دریافت یادآوری، دسترسی اعلان‌ها و تنظیمات دستگاه را بررسی کنید. قفل برنامه را می‌توانید در تنظیمات فعال کنید؛ دسترسی آن به امکانات احراز هویت دستگاه وابسته است.',
            ),
            const _AboutSection(
              title: 'پشتیبان‌گیری و بازیابی',
              text:
                  'از منوی «بیشتر» می‌توانید پشتیبان رمزگذاری‌شده تهیه کنید یا اطلاعات را بازیابی کنید. پشتیبان‌گیری با اقدام شما انجام می‌شود؛ نگهداری محلی به‌تنهایی جای پشتیبان را نمی‌گیرد.\n'
                  'فایل پشتیبان و کلید بازیابی آن را جداگانه و در جای امن نگه دارید. برای بازیابی پشتیبان جدید روی دستگاه دیگر، هر دو لازم‌اند؛ بدون کلید، بازیابی ممکن نیست. فایل و کلید را در اختیار دیگران نگذارید.',
            ),
            const _AboutSection(
              title: 'وضعیت توسعه',
              text: 'پلن‌اکت در حال توسعه است. وجود یک قابلیت در برنامه به معنی تکمیل همهٔ بررسی‌های انتشار نیست؛ یادآوری‌ها، بازیابی روی دستگاه جدید و دسترسی‌های بومی همچنان به بررسی روی دستگاه نیاز دارند.',
            ),
            FutureBuilder<PackageInfo>(
              future: _packageInfo,
              builder: (context, snapshot) {
                final info = snapshot.data;
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(PlanActSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'نسخهٔ نصب‌شده',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: PlanActSpacing.sm),
                        if (snapshot.hasError) ...[
                          Semantics(
                            liveRegion: true,
                            child: const Text('خواندن اطلاعات نسخه انجام نشد.'),
                          ),
                          TextButton.icon(
                            onPressed: () => setState(() {
                              _packageInfo = widget.loadPackageInfo();
                            }),
                            icon: const Icon(Icons.refresh),
                            label: const Text('تلاش دوباره'),
                          ),
                        ] else if (info == null)
                          const Text('در حال خواندن اطلاعات نسخه…')
                        else
                          Text(
                            'نسخه: ${PersianNumbers.format(info.version)}\nشمارهٔ ساخت: ${info.buildNumber.isEmpty ? 'نامشخص' : PersianNumbers.format(info.buildNumber)}',
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: PlanActSpacing.xl),
            const _AboutSection(
              title: 'سازنده و مجوز',
              text:
                  'حقوق اثر: Iarash، ۲۰۲۶\n'
                  'مجوز پلن‌اکت: PolyForm Noncommercial 1.0.0\n'
                  'این مجوز دارای محدودیت استفادهٔ تجاری است. شرایط کامل مجوز برنامه و مجوز کتابخانه‌های به‌کاررفته را در بخش زیر بخوانید.',
            ),
            OutlinedButton.icon(
              onPressed: () =>
                  showLicensePage(context: context, applicationName: 'پلن‌اکت'),
              icon: const Icon(Icons.description_outlined),
              label: const Text('مشاهدهٔ مجوزها'),
            ),
          ],
        ),
      ),
    ),
  );
}

class _AboutSection extends StatelessWidget {
  const _AboutSection({required this.title, required this.text});
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: PlanActSpacing.xl),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: PlanActSpacing.sm),
        Text(text),
      ],
    ),
  );
}
