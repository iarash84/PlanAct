import 'package:planact/core/money/money.dart';
import 'package:planact/features/inbox/application/inbox_use_cases.dart';
import 'package:planact/features/inbox/application/sms_parser_support.dart';
import 'package:planact/features/inbox/application/layered_bank_sms_profiles.dart';
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
    final context = const SmsNormalizer().normalize(
      text: text,
      currency: currency,
      sourceAddress: sourceAddress,
      canonicalizeHeader: _canonicalizeBankHeader,
    );

    final classified = _rejectNonTransactional(context.text);
    if (classified) return null;

    for (final profile in const SmsProfileRegistry().candidates(context)) {
      final parsed = switch (profile) {
        SmsProfileFamily.resalatCompact => _tryParseResalatCompact(
          context.text,
          sourceAddress: context.sourceAddress,
        ),
        SmsProfileFamily.iranZamin => _tryParseIranZamin(
          context.text,
          sourceAddress: context.sourceAddress,
        ),
        SmsProfileFamily.mehrIran => _tryParseMehrIran(
          context.text,
          sourceAddress: context.sourceAddress,
        ),
        SmsProfileFamily.layeredBank => _tryParseLayeredProfiles(
          context.text,
          currency: context.currency,
          sourceAddress: context.sourceAddress,
        ),
        SmsProfileFamily.genericTemplate => _tryParseTemplates(
          context.text,
          sourceAddress: context.sourceAddress,
        ),
        SmsProfileFamily.compactSina => _tryParseCompactSina(context.text),
      };
      if (parsed != null) return parsed;
    }
    return null;
  }

  bool _rejectNonTransactional(String text) => RegExp(
    r'رمز|ناموفق|لغو|خطا|otp|password|fail|declined',
    caseSensitive: false,
  ).hasMatch(text);

  ParsedSms? _tryParseTemplates(String text, {String? sourceAddress}) {
    final normalizedLines = text.split('\n');
    final sender = sourceAddress?.trim().toUpperCase();
    if (sender == 'BANK MELLI' &&
        normalizedLines.length == 5 &&
        normalizedLines.firstOrNull == 'بانک ملی ایران' &&
        normalizedLines[1].startsWith('انتقال')) {
      return null;
    }
    for (final template in _templates) {
      final match = template.$2.firstMatch(text);
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
    return null;
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
    final account = RegExp(r'^(?:\d{12,24}|\d{1,12}(?:-\d{1,12}){2,4})$')
        .firstMatch(lines[0]);
    final amount = RegExp(r'^(' + _number + r')([+-])$').firstMatch(lines[1]);
    final stamp = RegExp(
      r'^(?<date>\d{4}/\d{1,2}/\d{1,2})-(?<time>\d{1,2}:\d{2}(?::\d{2})?)$',
    ).firstMatch(lines[2]);
    final balance = RegExp(r'^مانده\s*:?\s*(' + _number + r')$')
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
    } else if (header == 'بانک ملی ایران') {
      lines[0] = 'بانک ملی ایران';
    }
    return lines.join('\n');
  }

  /// Versioned, bounded profiles for layouts that share a bank family but do
  /// not share the older whole-message templates above. This remains a
  /// deterministic parser: no free-form number guessing is allowed.
  ParsedSms? _tryParseLayeredProfiles(
    String text, {
    required String currency,
    String? sourceAddress,
  }) {
    final context = SmsParseContext(
      text: text,
      lines: List<String>.unmodifiable(text.split('\n')),
      compactText: text.replaceAll(RegExp(r'\s+'), ' ').trim(),
      currency: currency,
      sourceAddress: sourceAddress,
      normalizedSourceAddress: sourceAddress?.trim().toUpperCase(),
    );
    final services = LayeredProfileServices(
      buildProfiled:
          ({
            required amountText,
            required balanceText,
            required dateText,
            required timeText,
            required account,
            required bank,
            required direction,
            required occurredAt,
            required confidence,
          }) => _buildSignedProfiledSms(
            amountText: amountText,
            balanceText: balanceText,
            dateText: dateText,
            timeText: timeText,
            account: account,
            bank: bank,
            direction: direction,
            occurredAt: occurredAt,
            confidence: confidence,
          ),
      buildSina:
          ({
            required amountText,
            required amountUnit,
            required balanceText,
            required balanceUnit,
            required dateText,
            required timeText,
            required account,
            required direction,
            required confidence,
          }) => _buildSinaProfiledSms(
            amountText: amountText,
            amountUnit: amountUnit,
            balanceText: balanceText,
            balanceUnit: balanceUnit,
            dateText: dateText,
            timeText: timeText,
            account: account,
            direction: direction,
            confidence: confidence,
          ),
      integer: _integer,
      date: _date,
    );
    return const LayeredBankSmsProfiles().parse(context, services) ??
        _tryParseLegacyLayeredProfiles(
          text,
          currency: currency,
          sourceAddress: sourceAddress,
        );
  }

  /// Legacy implementation retained as a bounded fallback during migration.
  /// New layouts must be added to [LayeredBankSmsProfiles] instead.
  ParsedSms? _tryParseLegacyLayeredProfiles(
    String text, {
    required String currency,
    String? sourceAddress,
  }) {
    // These profiles describe Iranian bank layouts without an explicit unit.
    // Keep the older fallback semantics for non-IRR caller contexts.
    if (currency != 'IRR') return null;

    final sender = sourceAddress?.trim().toUpperCase();
    final lines = text.split('\n');

    // Bank Mellat: account, signed transaction, balance, partial date/time.
    if (sender == 'BANK MELLAT' || lines.firstOrNull == 'بانک ملت') {
      if (lines.length == 4 && lines[0].startsWith('حساب')) {
        final account = RegExp(r'^حساب\s*([0-9]{4,32})$').firstMatch(lines[0]);
        final transaction = RegExp(
          r'^(برداشت|واریز)\s*((?:[0-9]{1,3}(?:[,،٬][0-9]{3})+|[0-9]+))([+-])?$',
        ).firstMatch(lines[1]);
        final balance = RegExp(
          r'^مانده\s*((?:[0-9]{1,3}(?:[,،٬][0-9]{3})+|[0-9]+))$',
        ).firstMatch(lines[2]);
        final stamp = RegExp(
          r'^(?<date>[0-9]{2}/[0-9]{2}/[0-9]{2})-(?<time>[0-9]{2}:[0-9]{2})$',
        ).firstMatch(lines[3]);
        if (account != null &&
            transaction != null &&
            balance != null &&
            stamp != null) {
          final sign = transaction.group(3);
          final incoming = transaction.group(1) == 'واریز' || sign == '+';
          if (sign == '-' && incoming || sign == '+' && !incoming) return null;
          return _buildProfiledSms(
            amountText: transaction.group(2)!,
            balanceText: balance.group(1)!,
            dateText: stamp.namedGroup('date')!,
            timeText: stamp.namedGroup('time')!,
            account: account.group(1)!,
            bank: 'ملت',
            direction: incoming
                ? TransactionDirection.incoming
                : TransactionDirection.outgoing,
            confidence: 86,
          );
        }
      }
    }

    // Bank Refah: کارت carries the signed transaction amount.
    if (sender == 'بانک رفاه' ||
        sender == 'BANK REFAH' ||
        lines.firstOrNull == 'بانک رفاه') {
      if (lines.length == 5 && lines[1].startsWith('حساب')) {
        final account = RegExp(r'^حساب\s*([0-9]{4,32})$').firstMatch(lines[1]);
        final transaction = RegExp(
          r'^کارت\s*((?:[0-9]{1,3}(?:[,،٬][0-9]{3})+|[0-9]+))([+-])$',
        ).firstMatch(lines[2]);
        final balance = RegExp(
          r'^مانده\s*((?:[0-9]{1,3}(?:[,،٬][0-9]{3})+|[0-9]+))$',
        ).firstMatch(lines[3]);
        final stamp = RegExp(
          r'^(?<date>[0-9]{2}/[0-9]{2})-(?<time>[0-9]{2}:[0-9]{2})$',
        ).firstMatch(lines[4]);
        if (account != null && transaction != null && balance != null) {
          final incoming = transaction.group(2) == '+';
          final dateTime = stamp == null
              ? null
              : _partialStamp(
                  stamp.namedGroup('date')!,
                  stamp.namedGroup('time')!,
                );
          return _buildSignedProfiledSms(
            amountText: transaction.group(1)!,
            balanceText: balance.group(1)!,
            dateText: stamp?.namedGroup('date'),
            timeText: stamp?.namedGroup('time'),
            account: account.group(1)!,
            bank: 'رفاه',
            direction: incoming
                ? TransactionDirection.incoming
                : TransactionDirection.outgoing,
            occurredAt: dateTime,
            confidence: 84,
          );
        }
      }
    }

    // Sina's device export uses a starred header and occasionally Arabic
    // spelling for the direction. Keep this profile sender/header gated.
    if (sender == 'SINA BANK' || lines.firstOrNull == 'بانک سینا') {
      if (lines.length == 5) {
        final operation = RegExp(
          r'^(برداشت از|واریز به)\s+([0-9]{1,32}(?:-[0-9]{1,32}){2,4})$',
        ).firstMatch(lines[1]);
        final amount = RegExp(
          r'^مبلغ\s*:?\s*((?:[0-9]{1,3}(?:[,،٬][0-9]{3})+|[0-9]+))\s*(ریال|تومان)$',
        ).firstMatch(lines[2]);
        final balance = RegExp(
          r'^مانده\s*:?\s*((?:[0-9]{1,3}(?:[,،٬][0-9]{3})+|[0-9]+))\s*(ریال|تومان)$',
        ).firstMatch(lines[3]);
        final stamp = RegExp(
          r'^زمان\s*:\s*(?<date>[0-9]{4}/[0-9]{1,2}/[0-9]{1,2})\s*;\s*(?<time>[0-9]{2}:[0-9]{2}(?::[0-9]{2})?)$',
        ).firstMatch(lines[4]);
        if (operation != null &&
            amount != null &&
            balance != null &&
            stamp != null) {
          final unit = amount.group(2) == 'تومان'
              ? SmsMoneyUnit.toman
              : SmsMoneyUnit.rial;
          final parsedAmount = _integer(amount.group(1)!, unit);
          final parsedBalance = _integer(
            balance.group(1)!,
            balance.group(2) == 'تومان'
                ? SmsMoneyUnit.toman
                : SmsMoneyUnit.rial,
          );
          final date = _date(stamp.namedGroup('date')!);
          final timeParts = stamp
              .namedGroup('time')!
              .split(':')
              .map(int.parse)
              .toList();
          if (parsedAmount != null &&
              parsedAmount > 0 &&
              parsedBalance != null &&
              date != null &&
              timeParts[0] <= 23 &&
              timeParts[1] <= 59 &&
              (timeParts.length < 3 || timeParts[2] <= 59)) {
            return ParsedSms(
              amount: Money(
                minorUnits: unit.canonicalIrr(parsedAmount),
                currency: 'IRR',
              ),
              balance: Money(
                minorUnits:
                    (balance.group(2) == 'تومان'
                            ? SmsMoneyUnit.toman
                            : SmsMoneyUnit.rial)
                        .canonicalIrr(parsedBalance),
                currency: 'IRR',
              ),
              currencyEvidence: SmsCurrencyEvidence(
                sourceAmount: parsedAmount,
                detectedUnit: unit,
              ),
              occurredAt: date.$1 == null
                  ? null
                  : DateTime(
                      date.$1!.year,
                      date.$1!.month,
                      date.$1!.day,
                      timeParts[0],
                      timeParts[1],
                      timeParts.length == 3 ? timeParts[2] : 0,
                    ),
              sourceDate: stamp.namedGroup('date'),
              sourceTime: stamp.namedGroup('time'),
              direction: operation.group(1) == 'واریز به'
                  ? TransactionDirection.incoming
                  : TransactionDirection.outgoing,
              quality: ParseQuality.high,
              confidence: 90,
              accountHint: operation.group(2),
              bank: 'سینا',
            );
          }
        }
      }
    }

    // Parsian: account, signed amount, balance, partial date, and a redacted
    // time/evidence line. The absent time is preserved as incomplete evidence.
    if (sender == 'PARSIANBANK') {
      if (lines.length >= 4) {
        final account = RegExp(r'^([0-9]{8,32})$').firstMatch(lines[0]);
        final transaction = RegExp(
          r'^مبلغ\s*:?\s*((?:[0-9]{1,3}(?:[,،٬][0-9]{3})+|[0-9]+))([+-])$',
        ).firstMatch(lines[1]);
        final balance = RegExp(
          r'^مانده\s*:?\s*((?:[0-9]{1,3}(?:[,،٬][0-9]{3})+|[0-9]+))$',
        ).firstMatch(lines[2]);
        final stamp = RegExp(r'^([0-9]{2}/[0-9]{2})$').firstMatch(lines[3]);
        if (account != null &&
            transaction != null &&
            balance != null &&
            stamp != null) {
          return _buildSignedProfiledSms(
            amountText: transaction.group(1)!,
            balanceText: balance.group(1)!,
            dateText: stamp.group(1),
            timeText: null,
            account: account.group(1)!,
            bank: 'پارسیان',
            direction: transaction.group(2) == '+'
                ? TransactionDirection.incoming
                : TransactionDirection.outgoing,
            occurredAt: null,
            confidence: 82,
          );
        }
      }
    }

    // National Bank compact family: header, operation, account, balance,
    // MMDD-time. Transfer messages remain outside income/expense parsing.
    if (sender == 'BANK MELLI' || lines.firstOrNull == 'بانک ملی ایران') {
      if (lines.length == 5 && lines[0] == 'بانک ملی ایران') {
        final operation = RegExp(
          r'^(برداشت|واریز|انتقال|خریداینترنتی)\s*:?\s*((?:[0-9]{1,3}(?:[,،٬][0-9]{3})+|[0-9]+))([+-])$',
        ).firstMatch(lines[1]);
        final account = RegExp(r'^حساب\s*:?\s*([0-9]{4,32})$')
            .firstMatch(lines[2]);
        final balance = RegExp(
          r'^مانده\s*:?\s*((?:[0-9]{1,3}(?:[,،٬][0-9]{3})+|[0-9]+))$',
        ).firstMatch(lines[3]);
        final stamp = RegExp(r'^(?<date>[0-9]{4})-(?<time>[0-9]{2}:[0-9]{2})$')
            .firstMatch(lines[4]);
        if (operation != null && account != null && balance != null) {
          if (operation.group(1) == 'انتقال') return null;
          final incoming = operation.group(1) == 'واریز';
          final sign = operation.group(3);
          if (sign == '-' && incoming || sign == '+' && !incoming) return null;
          return _buildSignedProfiledSms(
            amountText: operation.group(2)!,
            balanceText: balance.group(1)!,
            dateText: stamp?.namedGroup('date'),
            timeText: stamp?.namedGroup('time'),
            account: account.group(1)!,
            bank: 'ملی ایران',
            direction: incoming
                ? TransactionDirection.incoming
                : TransactionDirection.outgoing,
            occurredAt: null,
            confidence: 88,
          );
        }
      }
    }
    return null;
  }

  ParsedSms? _buildSinaProfiledSms({
    required String amountText,
    required SmsMoneyUnit amountUnit,
    required String balanceText,
    required SmsMoneyUnit balanceUnit,
    required String dateText,
    required String timeText,
    required String account,
    required TransactionDirection direction,
    required int confidence,
  }) {
    final amount = _integer(amountText, amountUnit);
    final balance = _integer(balanceText, balanceUnit);
    if (amount == null || amount <= 0 || balance == null) return null;
    final date = _date(dateText);
    if (date == null) return null;
    final parts = timeText.split(':').map(int.parse).toList();
    if (parts[0] > 23 ||
        parts[1] > 59 ||
        (parts.length == 3 && parts[2] > 59)) {
      return null;
    }
    final occurredAt = date.$1 == null
        ? null
        : DateTime(
            date.$1!.year,
            date.$1!.month,
            date.$1!.day,
            parts[0],
            parts[1],
            parts.length == 3 ? parts[2] : 0,
          );
    return ParsedSms(
      amount: Money(
        minorUnits: amountUnit.canonicalIrr(amount),
        currency: 'IRR',
      ),
      balance: Money(
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
      direction: direction,
      quality: occurredAt == null ? ParseQuality.medium : ParseQuality.high,
      confidence: confidence,
      accountHint: account,
      bank: 'سینا',
    );
  }

  DateTime? _partialStamp(String date, String time) {
    final dateMatch = RegExp(r'^(?<month>[0-9]{2})/(?<day>[0-9]{2})$')
        .firstMatch(date);
    final timeMatch = RegExp(r'^(?<hour>[0-9]{2}):(?<minute>[0-9]{2})$')
        .firstMatch(time);
    if (dateMatch == null || timeMatch == null) return null;

    final month = int.parse(dateMatch.namedGroup('month')!);
    final day = int.parse(dateMatch.namedGroup('day')!);
    final hour = int.parse(timeMatch.namedGroup('hour')!);
    final minute = int.parse(timeMatch.namedGroup('minute')!);
    if (month < 1 || month > 12 || day < 1 || day > 31) return null;
    if (hour > 23 || minute > 59) return null;

    // The source has no year. Preserve the textual evidence instead of
    // inventing an instant; this helper remains a validation seam.
    return null;
  }

  ParsedSms? _buildProfiledSms({
    required String amountText,
    required String balanceText,
    required String dateText,
    required String timeText,
    required String account,
    required String bank,
    required TransactionDirection direction,
    required int confidence,
  }) => _buildSignedProfiledSms(
    amountText: amountText,
    balanceText: balanceText,
    dateText: dateText,
    timeText: timeText,
    account: account,
    bank: bank,
    direction: direction,
    occurredAt: null,
    confidence: confidence,
  );

  ParsedSms? _buildSignedProfiledSms({
    required String amountText,
    required String balanceText,
    required String? dateText,
    required String? timeText,
    required String account,
    required String bank,
    required TransactionDirection direction,
    required DateTime? occurredAt,
    required int confidence,
  }) {
    final amount = _integer(amountText, null);
    final balance = _integer(balanceText, null);
    if (amount == null || amount <= 0 || balance == null) return null;
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
      direction: direction,
      quality: occurredAt == null ? ParseQuality.medium : ParseQuality.high,
      confidence: confidence,
      accountHint: account,
      bank: bank,
    );
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
