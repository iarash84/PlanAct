import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planact/app/planact_app.dart';
import 'package:planact/app/theme/planact_theme.dart';
import 'package:planact/features/help/presentation/help_faq_page.dart';

void main() {
  Widget app() => MaterialApp(
    locale: const Locale('fa'),
    supportedLocales: const [Locale('fa')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    theme: PlanActTheme.light(),
    home: const PlanActApp(),
  );

  testWidgets('More page includes help FAQ and opens a readable RTL route', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(NavigationDestination, 'بیشتر'));
    await tester.pumpAndSettle();

    final helpTitle = find.text('راهنما و سوالات متداول');
    expect(helpTitle, findsOneWidget);
    await tester.tap(helpTitle.first);
    await tester.pumpAndSettle();

    expect(find.byType(HelpFaqPage), findsOneWidget);
    expect(find.byType(ExpansionTile), findsWidgets);
    final tiles = tester.widgetList<ExpansionTile>(find.byType(ExpansionTile));
    for (final tile in tiles) {
      expect(tile.initiallyExpanded, isFalse);
    }
    final firstQuestion = find.text('پلن‌اکت برای چه کاری است؟');
    expect(firstQuestion, findsOneWidget);
    expect(Directionality.of(tester.element(firstQuestion)), TextDirection.rtl);
    expect(tester.takeException(), isNull);
  });

  testWidgets('drawer opens help and Back retains the current tab', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(NavigationDestination, 'تقویم'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('shell-menu')));
    await tester.pumpAndSettle();
    final help = find.byKey(const ValueKey('navigation-help'));
    await tester.ensureVisible(help);
    await tester.pumpAndSettle();
    await tester.tap(help);
    await tester.pumpAndSettle();
    expect(find.byType(HelpFaqPage), findsOneWidget);
    expect(find.byType(Drawer), findsNothing);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.byType(HelpFaqPage), findsNothing);
    expect(find.widgetWithText(AppBar, 'تقویم'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final dark in [false, true]) {
    testWidgets('account help explains consent and recovery dark=$dark', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          theme: dark ? PlanActTheme.dark() : PlanActTheme.light(),
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: MediaQuery(
              data: const MediaQueryData(textScaler: TextScaler.linear(2)),
              child: const HelpFaqPage(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      for (final question in [
        'چگونه یک تعهد جدید بسازم؟',
        'تفاوت زمان‌بندی با اعتبار جلسات چیست؟',
        'چگونه یک رخداد را تکمیل، لغو یا جابه‌جا کنم؟',
        'چگونه حساب‌ها و تراکنش‌های هر حساب را مدیریت کنم؟',
        'شماره کارت، شبا و شماره حساب چگونه محافظت می‌شوند؟',
        'تفاوت موجودی دفتر با گزارش موجودی بانک چیست؟',
        'بررسی گزارش موجودی چه چیزی را تغییر می‌دهد؟',
        'مقایسه با موجودی بانک چگونه انجام می‌شود؟',
        'لغو تطبیق‌های قبلی چه زمانی لازم است؟',
        'تفاوت ویرایش شرح با اصلاح یا لغو تراکنش چیست؟',
        'چرا نسخه‌های قبلی تراکنش اصلاح‌شده را در مالی نمی‌بینم؟',
        'تعیین ارتباط تراکنش با تطبیق پرداخت چه فرقی دارد؟',
        'چرا تکمیل یک رخداد به‌تنهایی به معنی پرداخت‌شدن آن نیست؟',
        'مبالغ چگونه ذخیره و نمایش داده می‌شوند؟',
        'اعلان تشخیص پیامک با دریافت خودکار چه فرقی دارد؟',
        'پیامک بانکی چگونه وارد صندوق ورودی می‌شود؟',
        'چگونه برای یک رخداد یادآوری تنظیم کنم؟',
        'چرا تراکنش‌ها در تقویم دیده نمی‌شوند؟',
        'تفاوت یادداشت تقویم با فهرست کارهای تعهد چیست؟',
        'چرا فایل پشتیبان و کلید بازیابی باید جداگانه نگهداری شوند؟',
      ]) {
        final tile = find.byKey(ValueKey(question));
        await tester.scrollUntilVisible(tile, 250, maxScrolls: 100);
        await tester.pumpAndSettle();
        await tester.tap(find.text(question));
        await tester.pumpAndSettle();
        final answer = tester.widget<Text>(
          find.descendant(of: tile, matching: find.byType(Text)).last,
        );
        expect(answer.data, isNotEmpty);
        expect(answer.data, isNot(contains('شاهد')));
        final requiredCopy = <String, List<String>>{
          'چگونه یک تعهد جدید بسازم؟': ['منوی کناری', 'پس از ساخت'],
          'تفاوت زمان‌بندی با اعتبار جلسات چیست؟': [
            'اعتبار ایجاد نمی‌کند',
            'ندارد',
          ],
          'چگونه یک رخداد را تکمیل، لغو یا جابه‌جا کنم؟': [
            'هماهنگ',
            'نباید فعال بماند',
          ],
          'تفاوت ویرایش شرح با اصلاح یا لغو تراکنش چیست؟': [
            'همان تراکنش',
            'جایگزین',
            'خودکار',
          ],
          'چرا نسخه‌های قبلی تراکنش اصلاح‌شده را در مالی نمی‌بینم؟': [
            'پیش‌فرض خاموش',
            'نسخهٔ قدیمی را برنمی‌گرداند',
          ],
          'چرا تکمیل یک رخداد به‌تنهایی به معنی پرداخت‌شدن آن نیست؟': [
            'لغوشدن آن فرق دارد',
            'تأیید',
          ],
          'مبالغ چگونه ذخیره و نمایش داده می‌شوند؟': [
            'پیش‌فرض ریال',
            'گرد نمی‌شود',
          ],
          'پیامک بانکی چگونه وارد صندوق ورودی می‌شود؟': [
            'به‌تنهایی رضایت خواندن نیست',
            'ابتدا خاموش',
            'بررسی دستی',
          ],
          'اعلان تشخیص پیامک با دریافت خودکار چه فرقی دارد؟': [
            'جدا',
            'تضمین نمی‌شود',
          ],
          'چرا تراکنش‌ها در تقویم دیده نمی‌شوند؟': [
            'پیش‌فرض خاموش',
            'ماه و هفته',
          ],
          'چرا فایل پشتیبان و کلید بازیابی باید جداگانه نگهداری شوند؟': [
            'نمی‌تواند آن را بازیابی کند',
            'هر خروجی جدید',
          ],
          'بررسی گزارش موجودی چه چیزی را تغییر می‌دهد؟': [
            'پیشنهاد قابل تغییر',
            'فقط تأیید نهایی',
          ],
        };
        for (final phrase in requiredCopy[question] ?? <String>[]) {
          expect(answer.data, contains(phrase), reason: question);
        }
        expect(answer.data, isNot(contains('提醒')));
        expect(Directionality.of(tester.element(tile)), TextDirection.rtl);
        if (question.startsWith('بررسی گزارش')) {
          expect(answer.data, contains('تراکنش یا موجودی دفتر تغییر نمی‌کند'));
        }
        if (question.startsWith('لغو')) {
          expect(answer.data, contains('خالص اثر لغو هر حساب'));
          expect(answer.data, contains('گزارش یا پیامک خودکار ذخیره نمی‌شود'));
        }
        expect(tester.takeException(), isNull);
        await tester.scrollUntilVisible(tile, 250, maxScrolls: 100);
        await tester.pumpAndSettle();
        await tester.tap(find.text(question));
        await tester.pumpAndSettle();
      }
    });
  }
}
