import 'package:planact/core/money/money.dart';
import 'package:planact/features/inbox/application/inbox_use_cases.dart';
import 'package:planact/features/inbox/application/sms_parser_support.dart';
import 'package:planact/features/inbox/domain/inbox.dart';
import 'package:planact/features/inbox/domain/sms_currency_evidence.dart';
import 'package:shamsi_date/shamsi_date.dart';

/// Bounded whole-message layouts reviewed against the device corpus. Sender
/// aliases only select an exact grammar; they never supply a missing money unit.
final class DeviceBankSmsProfiles {
  const DeviceBankSmsProfiles();

  static const _number = r'(?:[0-9]{1,3}(?:[,،٬][0-9]{3})+|[0-9]+)';
  static const _account = r'(?<account>[0-9Xx*/.-]{2,40})';
  static const _amount =
      '(?<prefix>[+-])?(?<amount>$_number)(?<suffix>[+-])?\\s*(?<unit>ریال|تومان)?';
  static const _balance =
      '(?:مانده|موجودی)\\s*:?\\s*(?<balance>$_number|\\*+)\\s*(?<balanceUnit>ریال|تومان)?';
  static const _date =
      r'(?<date>(?:[0-9]{2,4}/)?[0-9]{1,2}/[0-9]{1,2}|[0-9]{4})';
  static const _time = r'(?<time>[0-9]{1,2}:[0-9]{2}(?::[0-9]{2})?)';
  static const _stamp = '$_date\\s*[-_ ]\\s*$_time';

  static final _layouts = <(String, Set<String>, RegExp)>[
    (
      'خاورمیانه',
      const {},
      RegExp(
        '^بانک خاورمیانه(?:\\n| )(?<operation>برداشت وجه از خودپرداز|انتقال از اینترنت بانک (?:از|به)(?:\\n| )کارت [0-9]{4}|خرید با کارت [0-9]{4})\\n$_amount\\n(?:$_account\\n)?$_balance(?:\\n$_date\\n$_time)?\$',
      ),
    ),
    (
      'خاورمیانه',
      const {},
      RegExp(
        '^بانک خاورمیانه\\n$_account\\n$_amount\\n(?:$_date\\n)?$_time\\n$_balance\\n(?<operation>واریز پایا|[0-9*/]+ سود صندوق|[0-9*/]+ پرداخت علی\\nالحساب ابطال|کارمزد اطلاع رسانی پیامکی\\nشش ماهه دوم سال [0-9]{2})\$',
      ),
    ),
    (
      'مسکن',
      const {'100025'},
      RegExp(
        '^(?<operation>خرید|انتقال اینترنت|برداشت بابت خدمات پیامکی سال [0-9]{4}):\\s*$_amount\\nحساب:\\s*$_account\\n$_balance\\n$_stamp\$',
      ),
    ),
    (
      'صادرات',
      const {'98700719', 'BANKSADERAT'},
      RegExp(
        '^(?<operation>پایا|پایانه فروش|انتقال):\\s*$_amount\\nحساب:\\s*$_account\\n$_balance\\n$_stamp\$',
      ),
    ),
    (
      'صادرات',
      const {'98700719', 'BANKSADERAT'},
      RegExp(
        '^کارت:\\s*$_account\\n(?<operation>بازپرداخت/واریز|خرید شتابی):\\s*$_amount\\n$_balance\\n$_stamp\$',
      ),
    ),
    (
      'رفاه',
      const {},
      RegExp('^بانک رفاه\\n(?<operation>واریز) مبلغ\\s*$_amount\\n$_balance\$'),
    ),
    (
      'رفاه',
      const {},
      RegExp(
        '^بانک رفاه\\nحساب\\s*$_account\\n(?<operation>پایا)\\s*$_amount\\n$_balance\\n$_stamp\$',
      ),
    ),
    (
      'سامان',
      const {},
      RegExp(
        '^بانک سامان\\n(?<operation>واریز|برداشت) مبلغ\\s*$_amount(?: (?<transfer>انتقال وجه))?\\n(?:به|از)\\s*$_account\\n$_balance\\n$_date\\n$_time\$',
      ),
    ),
    (
      'سپه',
      const {},
      RegExp(
        '^بانک سپه\\n(?<operation>واریز سود به):\\s*$_account\\nمبلغ:\\s*$_amount\\nزمان:\\s*$_stamp\\n$_balance\$',
      ),
    ),
    (
      'سپه',
      const {},
      RegExp(
        '^بانک سپه\\n(?<operation>واریز):\\s*$_amount\\nحساب:\\s*$_account\\n$_balance\\n$_stamp\\n(?<transfer>دستورپرداخت وارده پل کدپیگیری [0-9]+|انتقال وجه پایا)\$',
      ),
    ),
    (
      'شهر',
      const {},
      RegExp(
        '^بانک شهر\\nخرید با کارت\\n(?<operation>برداشت از):\\s*$_account\\nمبلغ:\\s*$_amount\\n$_balance\\n$_stamp\$',
      ),
    ),
    (
      'تجارت',
      const {},
      RegExp(
        '^\\*بانک تجارت\\*\\nحساب:\\s*$_account\\n(?<operation>برداشت|واریز):\\s*$_amount\\n(?:از طریق: [^\\n]+\\n)?$_balance\\n$_date\\n$_time\$',
      ),
    ),
    (
      'ملت',
      const {'BANK MELLAT'},
      RegExp(
        '^(?<operation>واریز سود کوتاه مدت)\\nحساب\\s*$_account\\nمبلغ\\s*$_amount\\n$_date\$',
      ),
    ),
    (
      'ملی ایران',
      const {'+98700717', 'MELLI', 'MELLIBANK'},
      RegExp(
        '^مبلغ $_amount (?<operation>واریز به حساب شما انجام شد|از حساب شما برداشت شد|خرید با کارت شما انجام شد|انتقال یافت)\\.\\n$_balance\$',
      ),
    ),
    (
      'پارسیان',
      const {'PARSIANBANK', 'PARSIAN', 'PERSIANBANK', 'PARSIAN BANK'},
      RegExp(
        '^مبلغ $_amount (?<operation>واریز به حساب شما انجام شد|از حساب شما برداشت شد|خرید با کارت [0-9-]{19} انجام شد|انتقال یافت)\\.\\n$_balance\$',
      ),
    ),
  ];

  ParsedSms? parse(SmsParseContext context) {
    if (context.currency != 'IRR') return null;
    // Full-width punctuation is a presentation variant, not stored evidence.
    final text = context.text.replaceAll('：', ':');
    for (final (bank, senders, pattern) in _layouts) {
      if (senders.isNotEmpty &&
          !senders.contains(context.normalizedSourceAddress)) {
        continue;
      }
      final match = pattern.firstMatch(text);
      if (match == null) continue;
      String? field(String name) =>
          match.groupNames.contains(name) ? match.namedGroup(name) : null;
      final operation = field('operation')!;
      final prefix = field('prefix');
      final suffix = field('suffix');
      if (prefix != null && suffix != null) return null;
      final sign = prefix ?? suffix;
      final incoming =
          operation.startsWith('واریز') || operation == 'بازپرداخت/واریز';
      final outgoing =
          operation.startsWith('برداشت') ||
          operation.startsWith('خرید') ||
          operation == 'پایانه فروش' ||
          operation.startsWith('از حساب');
      if ((incoming && sign == '-') ||
          (outgoing && sign == '+') ||
          (!incoming &&
              !outgoing &&
              sign == null &&
              operation != 'انتقال یافت')) {
        return null;
      }
      SmsMoneyUnit? unit(String? value) => value == null
          ? null
          : value == 'تومان'
          ? SmsMoneyUnit.toman
          : SmsMoneyUnit.rial;
      final amountUnit = unit(field('unit'));
      final amount = _integer(field('amount')!, amountUnit);
      final balanceUnit = unit(field('balanceUnit')) ?? amountUnit;
      final balanceText = field('balance');
      final balance = balanceText == null || balanceText.contains('*')
          ? null
          : _integer(balanceText, balanceUnit);
      if (amount == null ||
          amount <= 0 ||
          (balanceText != null &&
              !balanceText.contains('*') &&
              balance == null)) {
        return null;
      }
      final dateText = field('date');
      final timeText = field('time');
      DateTime? date;
      if (dateText != null) {
        final parts = dateText.contains('/')
            ? dateText.split('/').map(int.parse).toList()
            : [
                int.parse(dateText.substring(0, 2)),
                int.parse(dateText.substring(2)),
              ];
        final month = parts[parts.length - 2];
        final day = parts.last;
        if (month < 1 ||
            month > 12 ||
            day < 1 ||
            day > (month <= 6 ? 31 : 30)) {
          return null;
        }
        if (parts.length == 3 && dateText.split('/').first.length == 4) {
          if (parts.first < 1300 || parts.first > 1499) return null;
          try {
            final gregorian = Jalali(parts.first, month, day).toGregorian();
            date = DateTime(gregorian.year, gregorian.month, gregorian.day);
          } on DateException {
            return null;
          }
        }
      }
      final time = timeText?.split(':').map(int.parse).toList();
      if (time != null &&
          (time[0] > 23 ||
              time[1] > 59 ||
              (time.length == 3 && time[2] > 59))) {
        return null;
      }
      final occurredAt = date == null || time == null
          ? null
          : DateTime(
              date.year,
              date.month,
              date.day,
              time[0],
              time[1],
              time.length == 3 ? time[2] : 0,
            );
      return ParsedSms(
        amount: Money(
          minorUnits: amountUnit?.canonicalIrr(amount) ?? amount,
          currency: 'IRR',
        ),
        balance: balance == null || balanceUnit == null
            ? null
            : Money(
                minorUnits: balanceUnit.canonicalIrr(balance),
                currency: 'IRR',
              ),
        currencyEvidence: SmsCurrencyEvidence(
          sourceAmount: amount,
          detectedUnit: amountUnit,
        ),
        occurredAt: occurredAt,
        sourceDate: dateText,
        sourceTime: timeText,
        direction: incoming || sign == '+'
            ? TransactionDirection.incoming
            : outgoing || sign == '-'
            ? TransactionDirection.outgoing
            : TransactionDirection.unknown,
        isTransfer:
            operation.contains('انتقال') ||
            operation.contains('پایا') ||
            field('transfer') != null,
        quality: ParseQuality.medium,
        confidence: 80,
        bank: bank,
        accountHint: field('account'),
      );
    }
    return null;
  }

  int? _integer(String text, SmsMoneyUnit? unit) {
    final value = BigInt.tryParse(text.replaceAll(RegExp(r'[,،٬]'), ''));
    final maximum = BigInt.from(9223372036854775807);
    if (value == null ||
        value > maximum ||
        ((unit == null || unit == SmsMoneyUnit.toman) &&
            value * BigInt.from(10) > maximum)) {
      return null;
    }
    return value.toInt();
  }
}
