import 'package:planact/core/money/money.dart';
import 'package:planact/features/inbox/application/inbox_use_cases.dart';
import 'package:planact/features/inbox/domain/inbox.dart';
import 'package:planact/features/inbox/domain/sms_currency_evidence.dart';
import 'package:shamsi_date/shamsi_date.dart';

/// Whole-message recognition for the bounded, redacted 18-message corpus.
/// Unknown senders/accounts are not bank identity or currency evidence.
class RealBankSmsParser implements SmsFormatParser {
  const RealBankSmsParser();

  static const _number = r'(?:[0-9]{1,3}(?:[,،٬][0-9]{3})+|[0-9]+)';
  static const _accountValue = r'[0-9]{1,32}(?:[.-][0-9]{1,32})*';
  static const _account = '(?<account>$_accountValue)';
  static const _amount =
      '(?<prefix>[+-])?(?<amount>$_number)(?<suffix>[+-])?\\s*(?<unit>ریال|تومان)?';
  static const _balance =
      '(?:مانده|موجودی)\\s*:?\\s*(?<balance>$_number)\\s*(?<balanceUnit>ریال|تومان)?';
  static const _stamp =
      r'(?<date>(?:[0-9]{4}|[0-9]{2})/[0-9]{1,2}/[0-9]{1,2}|[0-9]{2}/[0-9]{2}|[0-9]{4})\s*[-_; ]\s*(?<time>[0-9]{2}:[0-9]{2}(?::[0-9]{2})?)';
  static final _compactSinaAmount = RegExp(
    'مبلغ\\s*[:：]?\\s*($_number)\\s*(ریال|تومان)',
  );
  static final _compactSinaDeposit = RegExp(r'واریز\s+به\s+حساب');
  static final _compactSinaBank = RegExp(r'بانک\s*سینا');

  static final _templates = <(String?, RegExp)>[
    (
      'سینا',
      RegExp(
        '^بانک سینا\n(?<direction>برداشت از|واریز به)\\s+$_account\nمبلغ\\s*:?\\s*$_amount\n$_balance\nزمان\\s*:\\s*$_stamp\$',
      ),
    ),
    (
      'رسالت',
      RegExp(
        '^بانک رسالت\n(?<direction>برداشت از|واریز به)\\s+$_account\nمبلغ\\s*:?\\s*$_amount\n$_balance\nزمان\\s*:\\s*$_stamp\$',
      ),
    ),
    (
      'ایران‌زمین',
      RegExp(
        '^بانک ایران(?:‌| )زمین\n(?<direction>برداشت از|واریز به)\\s+$_account\nمبلغ\\s*:?\\s*$_amount\n$_balance\nزمان\\s*:\\s*$_stamp\$',
      ),
    ),
    (
      null,
      RegExp(
        '^حساب\\s*$_account\n(?<direction>برداشت|واریز)\\s*$_amount\n$_balance\n$_stamp\$',
      ),
    ),
    (null, RegExp('^$_account\n$_amount\n$_stamp\n$_balance\$')),
    (
      'رفاه',
      RegExp(
        '^بانک رفاه\nحساب\\s*$_account\nکارت\\s*$_amount\n$_balance\n$_stamp\$',
      ),
    ),
    (
      'ملی ایران',
      RegExp(
        '^بانک ملی ایران\n(?<direction>برداشت|انتقال|خریداینترنتی|واریز)\\s*:\\s*$_amount\nحساب\\s*:\\s*$_account\n$_balance\n$_stamp\$',
      ),
    ),
    (
      'شهر',
      RegExp(
        '^\\*بانک شهر\\*\n(?<description>واریز یارانه|خرید با کارت|پرداخت قبض)\n(?<direction>واریز به|برداشت از)\\s*:\\s*$_account\nمبلغ\\s*:\\s*$_amount\n$_balance\n$_stamp\$',
      ),
    ),
    (
      'گردشگری',
      RegExp(
        '^\\*بانک گردشگری\\*\n[\u0600-\u06ff\u200c ]{1,80}\n(?<direction>واریز به)\\s*:\\s*$_account\nمبلغ\\s*:\\s*$_amount\n$_stamp\n$_balance\$',
      ),
    ),
  ];

  @override
  ParsedSms? tryParse({required String text, required String currency}) {
    if (text.length > 4096) return null;
    final normalized = text
        .replaceAll(RegExp(r'[\u200e\u200f\u202a-\u202e\u2066-\u2069]'), '')
        .replaceAll('ي', 'ی')
        .replaceAll('ك', 'ک')
        .replaceAllMapped(RegExp(r'[۰-۹٠-٩]'), (m) {
          final code = m[0]!.codeUnitAt(0);
          return String.fromCharCode(
            code - (code >= 0x6f0 ? 0x6f0 : 0x660) + 48,
          );
        })
        .split(RegExp(r'\r?\n'))
        .map((line) => line.trim())
        .join('\n')
        .trim();
    if (RegExp(
      r'رمز|ناموفق|لغو|خطا|otp|password|fail|declined',
      caseSensitive: false,
    ).hasMatch(normalized)) {
      return null;
    }
    for (final template in _templates) {
      final match = template.$2.firstMatch(normalized);
      if (match == null) continue;
      String? field(String name) =>
          match.groupNames.contains(name) ? match.namedGroup(name) : null;
      final prefix = field('prefix');
      final suffix = field('suffix');
      // Two signs are ambiguous even when equal.
      if (prefix != null && suffix != null) return null;
      final sign = prefix ?? suffix;
      final label = field('direction');
      final incoming = label?.startsWith('واریز') == true;
      final outgoing =
          label?.startsWith('برداشت') == true || label == 'خریداینترنتی';
      if ((incoming && sign == '-') || (outgoing && sign == '+')) return null;
      if (!incoming && !outgoing && sign == null) return null;
      final description = field('description');
      if (description != null && (description == 'واریز یارانه') != incoming) {
        return null;
      }
      // Unbranded signed layouts require a dotted account, not arbitrary prose.
      if (template.$1 == null &&
          label == null &&
          !field('account')!.contains('.')) {
        return null;
      }
      SmsMoneyUnit? unit(String? value) => value == null
          ? null
          : value == 'تومان'
          ? SmsMoneyUnit.toman
          : SmsMoneyUnit.rial;
      final amountUnit = unit(field('unit'));
      final balanceUnit = unit(field('balanceUnit')) ?? amountUnit;
      final amount = _integer(field('amount')!, amountUnit);
      final balance = _integer(field('balance')!, balanceUnit);
      if (amount == null || amount <= 0 || balance == null) return null;
      final dateText = field('date')!;
      final timeText = field('time')!;
      final time = timeText.split(':').map(int.parse).toList();
      if (time[0] > 23 || time[1] > 59 || (time.length == 3 && time[2] > 59)) {
        return null;
      }
      final date = _date(dateText);
      if (date == null) return null;
      final occurredAt = date.$1 == null
          ? null
          : DateTime(
              date.$1!.year,
              date.$1!.month,
              date.$1!.day,
              time[0],
              time[1],
              time.length == 3 ? time[2] : 0,
            );
      final evidence = SmsCurrencyEvidence(
        sourceAmount: amount,
        detectedUnit: amountUnit,
      );
      return ParsedSms(
        amount: Money(
          minorUnits: amountUnit?.canonicalIrr(amount) ?? amount,
          currency: 'IRR',
        ),
        balance: balanceUnit == null
            ? null
            : Money(
                minorUnits: balanceUnit.canonicalIrr(balance),
                currency: 'IRR',
              ),
        currencyEvidence: evidence,
        occurredAt: occurredAt,
        sourceDate: dateText,
        sourceTime: timeText,
        direction: incoming || sign == '+'
            ? TransactionDirection.incoming
            : TransactionDirection.outgoing,
        isTransfer: label == 'انتقال',
        quality: evidence.requiresSelection || occurredAt == null
            ? ParseQuality.medium
            : ParseQuality.high,
        confidence: 80,
        accountHint: field('account'),
        bank: template.$1,
      );
    }
    return normalized.contains('\n') ? null : _tryParseCompactSina(normalized);
  }

  ParsedSms? _tryParseCompactSina(String text) {
    final compact = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    final amountMatch = _compactSinaAmount.firstMatch(compact);
    final depositMatch = _compactSinaDeposit.firstMatch(compact);
    final bankMatch = _compactSinaBank.firstMatch(compact);
    if (RegExp(r'برداشت|خرید|پرداخت|انتقال|کارت\s*به\s*کارت')
            .hasMatch(compact) ||
        RegExp('مبلغ').allMatches(compact).length != 1 ||
        RegExp('واریز').allMatches(compact).length != 1 ||
        RegExp('حساب').allMatches(compact).length != 1 ||
        RegExp('بانک\\s*سینا').allMatches(compact).length != 1 ||
        RegExp('ریال|تومان').allMatches(compact).length != 1 ||
        RegExp('مانده|موجودی|زمان|تاریخ').hasMatch(compact) ||
        amountMatch == null ||
        depositMatch == null ||
        bankMatch == null ||
        amountMatch.end > depositMatch.start ||
        depositMatch.end > bankMatch.start ||
        depositMatch.start - amountMatch.end > 160 ||
        bankMatch.start - depositMatch.end > 200) {
      return null;
    }
    final unit = amountMatch.group(2) == 'تومان'
        ? SmsMoneyUnit.toman
        : SmsMoneyUnit.rial;
    final sourceAmount = _integer(amountMatch.group(1)!, unit);
    if (sourceAmount == null || sourceAmount <= 0) return null;
    final evidence = SmsCurrencyEvidence(
      sourceAmount: sourceAmount,
      detectedUnit: unit,
    );
    return ParsedSms(
      amount: Money(
        minorUnits: unit.canonicalIrr(sourceAmount),
        currency: 'IRR',
      ),
      occurredAt: null,
      sourceDate: null,
      sourceTime: null,
      direction: TransactionDirection.incoming,
      quality: ParseQuality.medium,
      confidence: 70,
      bank: 'سینا',
      currencyEvidence: evidence,
    );
  }

  int? _integer(String value, SmsMoneyUnit? unit) {
    final number = BigInt.tryParse(value.replaceAll(RegExp(r'[,،٬]'), ''));
    final maximum = BigInt.from(9223372036854775807);
    if (number == null ||
        number > maximum ||
        ((unit == null || unit == SmsMoneyUnit.toman) &&
            number * BigInt.from(10) > maximum)) {
      return null;
    }
    return number.toInt();
  }

  /// Valid partial calendar evidence is not permission to invent its year.
  (DateTime?,)? _date(String value) {
    final parts = value.contains('/')
        ? value.split('/').map(int.parse).toList()
        : [int.parse(value.substring(0, 2)), int.parse(value.substring(2))];
    final month = parts[parts.length - 2];
    final day = parts.last;
    if (month < 1 || month > 12 || day < 1 || day > (month <= 6 ? 31 : 30)) {
      return null;
    }
    if (parts.length != 3 || value.split('/').first.length != 4) return (null,);
    final year = parts.first;
    if (year < 1300 || year > 1499) return null;
    try {
      final date = Jalali(year, month, day).toGregorian();
      return (DateTime(date.year, date.month, date.day),);
    } on DateException {
      return null;
    }
  }
}
