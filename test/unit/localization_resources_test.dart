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
    // Post-migration message groups are explicitly marked and are not part of
    // the frozen pre-migration source. All catalog metadata is still checked.
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
                    'compact-tags-2026-11-08',
                    'inbox-tags-2026-11-08',
                    'theme-presets-2026-11-09',
                    'reports-cards-2026-11-10',
                    'today-relationship-preview-2026-11-11',
                    'today-inbox-preview-2026-11-11',
                    'finance-pagination-2026-11-11',
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
      // Reviewed baseline for the current Persian catalog, including the
      // approved help/FAQ copy now used by the More page.
      'c56ea70e203d51818c1ab4d6a2a77244edbb1218622c0e264dadafcabdf09263',
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

  test('finance pagination copy is separate from migrated templates', () {
    final messages = {
      'financeTransactionPreviousPage': 'صفحهٔ قبل',
      'financeTransactionNextPage': 'صفحهٔ بعد',
      'financeTransactionPageRange':
          'تراکنش {start} تا {end} از {total}؛ صفحهٔ {page} از {pages}',
    };
    final markedKeys = catalog.keys.where(
      (key) =>
          key.startsWith('@') &&
          catalog[key] is Map &&
          (catalog[key] as Map)['x-planact-introduced'] ==
              'finance-pagination-2026-11-11',
    );
    expect(markedKeys, unorderedEquals(messages.keys.map((key) => '@$key')));
    for (final entry in messages.entries) {
      expect(catalog[entry.key], entry.value, reason: entry.key);
    }
  });

  test('Today preview copy is explicitly separate from migrated templates', () {
    final groups = {
      'today-relationship-preview-2026-11-11': {
        'todayRelationshipViewAll': 'مشاهدهٔ همه در تعیین ارتباط',
        'todayRelationshipDate': 'تاریخ تراکنش: {date}',
      },
      'today-inbox-preview-2026-11-11': {
        'todayInboxViewAll': 'مشاهدهٔ همه در صندوق بررسی',
      },
    };
    for (final group in groups.entries) {
      final markedKeys = catalog.keys.where(
        (key) =>
            key.startsWith('@') &&
            catalog[key] is Map &&
            (catalog[key] as Map)['x-planact-introduced'] == group.key,
      );
      expect(
        markedKeys,
        unorderedEquals(group.value.keys.map((key) => '@$key')),
      );
      for (final entry in group.value.entries) {
        expect(catalog[entry.key], entry.value, reason: entry.key);
      }
    }
  });

  test('compact tag copy is explicitly separate from migrated templates', () {
    final messages = {
      'tagSelectionChoose': 'انتخاب برچسب‌ها',
      'tagSelectionSearch': 'جست‌وجوی برچسب',
      'tagSelectionEmpty': 'برچسبی پیدا نشد.',
      'tagSelectionRemaining': 'و {count} برچسب دیگر',
      'tagSelectionCreate': 'افزودن برچسب «{label}»',
    };
    final markedKeys = catalog.keys.where(
      (key) =>
          key.startsWith('@') &&
          catalog[key] is Map &&
          (catalog[key] as Map)['x-planact-introduced'] ==
              'compact-tags-2026-11-08',
    );
    expect(markedKeys, unorderedEquals(messages.keys.map((key) => '@$key')));
    for (final entry in messages.entries) {
      expect(catalog[entry.key], entry.value, reason: entry.key);
    }
  });

  test('report card copy is explicitly separate from migrated templates', () {
    final messages = {
      'reportsTransactionMetadata': '{date} · {type}\n{account}',
      'reportsPreviousPage': 'صفحهٔ قبل',
      'reportsNextPage': 'صفحهٔ بعد',
      'reportsPagePosition': 'صفحهٔ {page} از {pages} · {count} تراکنش',
    };
    final markedKeys = catalog.keys.where(
      (key) =>
          key.startsWith('@') &&
          catalog[key] is Map &&
          (catalog[key] as Map)['x-planact-introduced'] ==
              'reports-cards-2026-11-10',
    );
    expect(markedKeys, unorderedEquals(messages.keys.map((key) => '@$key')));
    for (final entry in messages.entries) {
      expect(catalog[entry.key], entry.value, reason: entry.key);
    }
  });

  test('theme preset copy is explicitly separate from migrated templates', () {
    final messages = {
      'settingsPaletteTitle': 'تم رنگی',
      'settingsPaletteDescription': 'هر تم نسخهٔ روشن و تاریک هماهنگ دارد؛ حالت نمایش را جداگانه انتخاب کنید.',
      'settingsPaletteOriginal': 'اصلی پلن‌اکت',
      'settingsPaletteBlue': 'آبی آرام',
      'settingsPalettePurple': 'بنفش ملایم',
      'settingsPaletteEarth': 'خاکی گرم',
      'settingsPaletteSaveError':
          'ذخیرهٔ تم انجام نشد؛ تم قبلی حفظ شده است. دوباره انتخاب کنید.',
      'settingsPaletteLoadError':
          'خواندن تم ذخیره‌شده انجام نشد. دوباره تلاش کنید.',
    };
    final markedKeys = catalog.keys.where(
      (key) =>
          key.startsWith('@') &&
          catalog[key] is Map &&
          (catalog[key] as Map)['x-planact-introduced'] ==
              'theme-presets-2026-11-09',
    );
    expect(markedKeys, unorderedEquals(messages.keys.map((key) => '@$key')));
    for (final entry in messages.entries) {
      expect(catalog[entry.key], entry.value, reason: entry.key);
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
