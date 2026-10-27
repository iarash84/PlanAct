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

  static const _accountAfterDirection =
      r'(?:حساب\s*)?'
      '$_account';
  static final _templates = <(String?, RegExp)>[
    (
      'سینا',
      RegExp(
        '^بانک سینا\n(?<direction>برداشت از|واریز به)\\s+$_accountAfterDirection\nمبلغ\\s*:?\\s*$_amount\n$_balance\nزمان\\s*:\\s*$_stamp\$',
      ),
    ),
    (
      'رسالت',
      RegExp(
        '^بانک رسالت\n(?<direction>برداشت از|واریز به)\\s+$_accountAfterDirection\nمبلغ\\s*:?\\s*$_amount\n$_balance\nزمان\\s*:\\s*$_stamp\$',
      ),
    ),
    (
      'ایران‌زمین',
      RegExp(
        '^بانک ایران(?:‌| )زمین\n(?<direction>برداشت از|واریز به)\\s+$_accountAfterDirection\nمبلغ\\s*:?\\s*$_amount\n$_balance\nزمان\\s*:\\s*$_stamp\$',
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
  ParsedSms? tryParse({
    required String text,
    required String currency,
    String? sourceAddress,
  }) {
    if (text.length > 4096) return null;
    var normalized = text
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
    normalized = _canonicalizeBankHeader(normalized);
    final compactResalat = _tryParseResalatCompact(
      normalized,
      sourceAddress: sourceAddress,
    );
    if (compactResalat != null) return compactResalat;
    final iranZamin = _tryParseIranZamin(
      normalized,
      sourceAddress: sourceAddress,
    );
    if (iranZamin != null) return iranZamin;
    final mehrIran = _tryParseMehrIran(
      normalized,
      sourceAddress: sourceAddress,
    );
    if (mehrIran != null) return mehrIran;
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

  ParsedSms? _tryParseResalatCompact(String text, {String? sourceAddress}) {
    if (sourceAddress == null ||
        !RegExp(
          r'^resalatbank$',
          caseSensitive: false,
        ).hasMatch(sourceAddress.trim())) {
      return null;
    }
    final lines = text.split('\n');
    if (lines.length != 4) return null;
    final account = RegExp(r'^\d{1,32}(?:\.\d{1,32})+$').firstMatch(lines[0]);
    final amount = RegExp('^([+-])($_number)\\s*\$').firstMatch(lines[1]);
    final stamp = RegExp(r'^(\d{2}/\d{2})[_ -](\d{2}:\d{2}(?::\d{2})?)$')
        .firstMatch(lines[2]);
    final balance = RegExp('^(?:مانده|موجودی)\\s*:?\\s*($_number)\$')
        .firstMatch(lines[3]);
    if (account == null || amount == null || stamp == null || balance == null) {
      return null;
    }
    final sourceAmount = _integer(amount.group(2)!, null);
    if (sourceAmount == null || sourceAmount <= 0) return null;
    final timeParts = stamp.group(2)!.split(':').map(int.parse).toList();
    if (timeParts[0] > 23 ||
        timeParts[1] > 59 ||
        (timeParts.length == 3 && timeParts[2] > 59)) {
      return null;
    }
    final evidence = SmsCurrencyEvidence(
      sourceAmount: sourceAmount,
      detectedUnit: null,
    );
    final balanceAmount = _integer(balance.group(1)!, null);
    if (balanceAmount == null) return null;
    return ParsedSms(
      amount: Money(minorUnits: sourceAmount, currency: 'IRR'),
      balance: Money(minorUnits: balanceAmount, currency: 'IRR'),
      currencyEvidence: evidence,
      occurredAt: null,
      sourceDate: stamp.group(1),
      sourceTime: stamp.group(2),
      direction: amount.group(1) == '+'
          ? TransactionDirection.incoming
          : TransactionDirection.outgoing,
      quality: ParseQuality.medium,
      confidence: 85,
      accountHint: account.group(0),
      bank: 'رسالت',
    );
  }

  ParsedSms? _tryParseIranZamin(String text, {String? sourceAddress}) {
    if (sourceAddress?.trim().toUpperCase() != 'IZBANK') return null;
    final lines = text.split('\n');
    if (lines.length != 4) return null;
    final account = RegExp(r'^\d{1,12}(?:-\d{1,12}){2,4}$')
        .firstMatch(lines[0]);
    final amount = RegExp(r'^([+-])(' + _number + r')$').firstMatch(lines[1]);
    final balance = RegExp(r'^مانده\s*:?[ ]*(' + _number + r')$')
        .firstMatch(lines[2]);
    final stamp = RegExp(
      r'^(?<date>\d{4}/\d{1,2}/\d{1,2})-(?<time>\d{1,2}:\d{2}(?::\d{2})?)$',
    ).firstMatch(lines[3]);
    if (account == null || amount == null || balance == null || stamp == null) {
      return null;
    }
    return _buildSignedBankSms(
      amountText: amount.group(2)!,
      sign: amount.group(1)!,
      balanceText: balance.group(1)!,
      dateText: stamp.namedGroup('date')!,
      timeText: stamp.namedGroup('time')!,
      account: account.group(0)!,
      bank: 'ایران‌زمین',
    );
  }

  ParsedSms? _tryParseMehrIran(String text, {String? sourceAddress}) {
    if (sourceAddress?.trim().toUpperCase() != 'B.QMEHRIRAN') return null;
    final lines = text.split('\n');
    if (lines.length != 4) return null;
    final account = RegExp(r'^\d{12,24}$').firstMatch(lines[0]);
    final amount = RegExp(r'^(' + _number + r')([+-])$').firstMatch(lines[1]);
    final stamp = RegExp(
      r'^(?<date>\d{4}/\d{1,2}/\d{1,2})-(?<time>\d{1,2}:\d{2}(?::\d{2})?)$',
    ).firstMatch(lines[2]);
    final balance = RegExp(r'^مانده\s*:\s*(' + _number + r')$')
        .firstMatch(lines[3]);
    if (account == null || amount == null || stamp == null || balance == null) {
      return null;
    }
    return _buildSignedBankSms(
      amountText: amount.group(1)!,
      sign: amount.group(2)!,
      balanceText: balance.group(1)!,
      dateText: stamp.namedGroup('date')!,
      timeText: stamp.namedGroup('time')!,
      account: account.group(0)!,
      bank: 'مهر ایران',
    );
  }

  ParsedSms? _buildSignedBankSms({
    required String amountText,
    required String sign,
    required String balanceText,
    required String dateText,
    required String timeText,
    required String account,
    required String bank,
  }) {
    final amount = _integer(amountText, null);
    final balance = _integer(balanceText, null);
    if (amount == null || amount <= 0 || balance == null) return null;
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
    return ParsedSms(
      amount: Money(minorUnits: amount, currency: 'IRR'),
      balance: Money(minorUnits: balance, currency: 'IRR'),
      currencyEvidence: SmsCurrencyEvidence(
        sourceAmount: amount,
        detectedUnit: null,
      ),
      occurredAt: occurredAt,
      sourceDate: dateText,
      sourceTime: timeText,
      direction: sign == '+'
          ? TransactionDirection.incoming
          : TransactionDirection.outgoing,
      quality: occurredAt == null ? ParseQuality.medium : ParseQuality.high,
      confidence: 90,
      accountHint: account,
      bank: bank,
    );
  }

  String _canonicalizeBankHeader(String text) {
    final lines = text.split('\n');
    if (lines.isEmpty) return text;
    final header = lines.first
        .replaceAll('*', '')
        .replaceAll(RegExp(r'[ \u200c]+'), ' ')
        .trim();
    if (RegExp(r'^بانک قرض الحسنه رسالت$').hasMatch(header) ||
        header == 'بانک رسالت') {
      lines[0] = 'بانک رسالت';
    } else if (RegExp(r'^بانک ایران[ \u200c]*زمین$').hasMatch(header)) {
      lines[0] = 'بانک ایران‌زمین';
    }
    return lines.join('\n');
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
