import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planact/core/localization/persian_copy.g.dart';
import 'package:planact/core/localization/persian_date_formatter.dart';
import 'package:planact/core/presentation/persian_money_text.dart';
import 'package:planact/l10n/generated/app_localizations.dart';
import 'package:planact/l10n/generated/app_localizations_fa.dart';

import '../../tool/generate_persian_copy.dart' as generator;

void main() {
  final catalog = jsonDecode(
    File('lib/l10n/app_fa.arb').readAsStringSync(),
  ) as Map<String, dynamic>;

  test('Persian remains the only exposed locale and template', () {
    expect(AppLocalizations.supportedLocales.map((l) => l.languageCode), [
      'fa',
    ]);
    expect(catalog['@@locale'], 'fa');
    final copy = AppLocalizationsFa();
    expect(copy.commonSave, 'ذخیره');
    expect(copy.commonCancel, 'انصراف');
    expect(copy.commonRetry, 'تلاش دوباره');
    expect(
      copy.appLockAuthenticationReason,
      'برای ورود به پلن‌اکت هویت خود را تأیید کنید.',
    );
    expect(copy.commitmentTitleRequired, 'عنوان تعهد را وارد کنید.');
    expect(copy.occurrenceCancelled, 'لغوشده');
    expect(copy.calendarPageTodayButtonLabel, 'امروز');
    expect(copy.holidayDataCoverageTitle, 'سال‌ها و منابع تعطیلات');
    expect(
      copy.holidayPackageSettingsCardBuildSubtitle,
      'ورود سال‌های جدید بدون به‌روزرسانی برنامه',
    );
    expect(
      copy.holidayDataYearOrigin('۱۴۰۷', copy.holidayDataOriginImported),
      'سال ۱۴۰۷؛ بستهٔ واردشده',
    );
    expect(copy.commitmentBrowseExpand, 'نمایش تمام‌صفحه');
    expect(copy.commitmentBrowseCollapse, 'نمایش کوچک‌تر');
    expect(
      copy.commitmentBrowseOpenError,
      'نمایش جزئیات انجام نشد؛ برای تلاش دوباره تعهد را انتخاب کنید.',
    );
  });

  test(
    'default resource generation is reproducible and framework independent',
    () {
      final expected = generator.render(catalog);
      expect(
        File('lib/core/localization/persian_copy.g.dart')
            .readAsStringSync()
            .replaceAll('\r\n', '\n'),
        expected,
      );
      expect(expected, isNot(contains('import ')));
      final native = File(
        'android/app/src/main/res/values/planact_alarm_strings.xml',
      ).readAsStringSync().replaceAll('\r\n', '\n');
      expect(native, generator.renderAndroid(catalog));
      expect(native, contains('تعویق ۱۰ دقیقه'));
      expect(PersianCopy.commitmentTitleRequired, 'عنوان تعهد را وارد کنید.');
      expect(PersianDateFormatter.monthNames, [
        'فروردین',
        'اردیبهشت',
        'خرداد',
        'تیر',
        'مرداد',
        'شهریور',
        'مهر',
        'آبان',
        'آذر',
        'دی',
        'بهمن',
        'اسفند',
      ]);
      expect(PersianDateFormatter.compactWeekdayNames, [
        'ش',
        'ی',
        'د',
        'س',
        'چ',
        'پ',
        'ج',
      ]);
      expect(PersianMoneyText.amount(-1234567, 'IRR'), '-۱,۲۳۴,۵۶۷ ریال');
    },
  );

  test('all migrated Persian templates preserve the pre-migration copy', () {
    // Frozen from the original source expressions before their replacement,
    // including punctuation and placeholder order. Intentional copy changes
    // must update this baseline with explicit review, not regenerate it in CI.
    // New user-approved Undo/Inbox/SMS/browse/note messages are separately marked and are not part
    // of the frozen pre-migration source. All catalog metadata is still checked.
    final templates =
        catalog.entries
            .where((entry) => !entry.key.startsWith('@'))
            .where(
              (entry) =>
                  !const {
                    'undo-2026-10-14',
                    'inbox-default-2026-10-14',
                    'sms-sync-2026-10-14',
                    'sms-permission-2026-10-14',
                    'interaction-2026-10-14',
                    'alarm-2026-10-14',
                    'holiday-data-2026-10-14',
                    'calendar-note-2026-10-14',
                    'checklist-2026-10-14',
                    'checklist-2026-10-18',
                    'search-2026-10-14',
                    'counted-progress-2026-10-14',
                  }.contains(
                    (catalog['@${entry.key}']
                        as Map<String, dynamic>)['x-planact-introduced'],
                  ),
            )
            .map((entry) => entry.value as String)
            .toSet()
            .toList()
          ..sort();
    expect(
      sha256.convert(utf8.encode(templates.join('\n'))).toString(),
      // User-approved 2026-10-14: Today label and removal of stale fixed holiday coverage.
      '5d7a7860202664412828e85236ad849fce903f4baa0965fb0cf578b3e2f7275e',
    );
    for (final entry in catalog.entries.where((e) => !e.key.startsWith('@'))) {
      final metadata = catalog['@${entry.key}'] as Map<String, dynamic>;
      expect(metadata['description'], isA<String>(), reason: entry.key);
      final referenced = RegExp(r'\{([a-zA-Z][a-zA-Z0-9]*)\}')
          .allMatches(entry.value as String)
          .map((m) => m.group(1))
          .toSet();
      final placeholders = metadata['placeholders'] as Map<String, dynamic>?;
      expect(referenced, (placeholders?.keys ?? []).toSet(), reason: entry.key);
    }
  });

  test(
    'default generator preserves literal dollars, quotes and placeholders',
    () {
      final source = generator.render({
        'plain': 'سلام؛ "متن" و \$literal',
        '@plain': {'x-planact-default': true},
        'message': 'مبلغ {amount}؛ نام {name}',
        '@message': {
          'x-planact-default': true,
          'placeholders': {
            'amount': {'type': 'String'},
            'name': {'type': 'String'},
          },
        },
      });
      expect(source, contains(r'\$literal'));
      expect(source, contains('String amount, String name'));
      expect(source, contains(r'${amount}'));
      expect(source, contains(r'${name}'));
      expect(
        () => generator.render({
          'message': '{count, plural, one {جلسه} other {جلسات}}',
          '@message': {
            'x-planact-default': true,
            'placeholders': {
              'count': {'type': 'int'},
            },
          },
        }),
        throwsFormatException,
      );
    },
  );
}
