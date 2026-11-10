import 'package:planact/core/money/money.dart';
import 'package:planact/features/inbox/application/inbox_use_cases.dart';
import 'package:planact/features/inbox/application/sms_parser_support.dart';
import 'package:planact/features/inbox/domain/inbox.dart';
import 'package:planact/features/inbox/domain/sms_currency_evidence.dart';

/// Shared construction hooks keep profile matching independent from the
/// `ParsedSms` validation and money-normalization policy.
final class LayeredProfileServices {
  const LayeredProfileServices({
    required this.buildProfiled,
    required this.buildSina,
    required this.integer,
    required this.date,
  });

  final ParsedSms? Function({
    required String amountText,
    required String balanceText,
    required String? dateText,
    required String? timeText,
    required String account,
    required String bank,
    required TransactionDirection direction,
    required DateTime? occurredAt,
    required int confidence,
  })
  buildProfiled;
  final ParsedSms? Function({
    required String amountText,
    required SmsMoneyUnit amountUnit,
    required String balanceText,
    required SmsMoneyUnit balanceUnit,
    required String dateText,
    required String timeText,
    required String account,
    required TransactionDirection direction,
    required int confidence,
  })
  buildSina;
  final int? Function(String value, SmsMoneyUnit? unit) integer;
  final (DateTime?,)? Function(String value) date;
}

/// Deterministic profiles for bank layouts that cannot be represented by the
/// generic whole-message templates. Each profile owns only recognition rules;
/// construction and persistence-facing semantics remain in the main parser.
final class LayeredBankSmsProfiles {
  const LayeredBankSmsProfiles();

  static const _number = r'(?:[0-9]{1,3}(?:[,،٬][0-9]{3})+|[0-9]+)';

  ParsedSms? parse(SmsParseContext context, LayeredProfileServices services) {
    if (context.currency != 'IRR') return null;
    final sender = context.normalizedSourceAddress;
    final lines = context.lines;

    final novin = _parseEghtesadNovin(lines, services);
    if (novin != null) return novin;

    final blu = _parseBlu(lines, services);
    if (blu != null) return blu;

    final mellat = _parseMellat(sender, lines, services);
    if (mellat != null) return mellat;

    final refah = _parseRefah(sender, lines, services);
    if (refah != null) return refah;

    final sina = _parseSina(sender, lines, services);
    if (sina != null) return sina;

    final parsian = _parseParsian(sender, lines, services);
    if (parsian != null) return parsian;

    return _parseMelli(sender, lines, services);
  }

  /// Eghtesad Novin v1: explicit signed rial amounts and branded contact footer.
  /// The source omits its year, so month/day and time remain partial evidence.
  ParsedSms? _parseEghtesadNovin(
    List<String> lines,
    LayeredProfileServices services,
  ) {
    if (lines.length != 5 ||
        !RegExp(r'^مرکز\s*آوای\s+نوین\s*:\s*0[0-9]{10}$').hasMatch(lines[4])) {
      return null;
    }
    final operation = RegExp(
      r'^(واریز|برداشت)\s*:\s*([0-9]{1,12}(?:-[0-9]{1,12}){3})$',
    ).firstMatch(lines[0]);
    final amount = RegExp('^([+-])($_number)\\s*ریال\$').firstMatch(lines[1]);
    final balance = RegExp('^مانده\\s*:\\s*($_number)\\s*ریال\$')
        .firstMatch(lines[2]);
    final stamp = RegExp(r'^(\d{1,2}/\d{1,2})-(\d{2}):(\d{2})$')
        .firstMatch(lines[3]);
    if (operation == null ||
        amount == null ||
        balance == null ||
        stamp == null) {
      return null;
    }
    final incoming = operation.group(1) == 'واریز';
    if ((amount.group(1) == '+') != incoming) return null;
    final value = services.integer(amount.group(2)!, SmsMoneyUnit.rial);
    final remaining = services.integer(balance.group(1)!, SmsMoneyUnit.rial);
    final dateText = stamp.group(1)!;
    if (value == null ||
        value <= 0 ||
        remaining == null ||
        services.date(dateText) == null ||
        int.parse(stamp.group(2)!) > 23 ||
        int.parse(stamp.group(3)!) > 59) {
      return null;
    }
    return ParsedSms(
      amount: Money(minorUnits: value, currency: 'IRR'),
      balance: Money(minorUnits: remaining, currency: 'IRR'),
      currencyEvidence: SmsCurrencyEvidence(
        sourceAmount: value,
        detectedUnit: SmsMoneyUnit.rial,
      ),
      occurredAt: null,
      sourceDate: dateText,
      sourceTime: '${stamp.group(2)}:${stamp.group(3)}',
      accountHint: operation.group(2),
      bank: 'اقتصاد نوین',
      direction: incoming
          ? TransactionDirection.incoming
          : TransactionDirection.outgoing,
      quality: ParseQuality.medium,
      confidence: 90,
    );
  }

  /// Blu v1: the full branded layout is evidence, not an unverified sender
  /// alias. Heading and conversational direction must agree; no account is
  /// present in this layout and none may be inferred from the recipient name.
  ParsedSms? _parseBlu(List<String> lines, LayeredProfileServices services) {
    if (lines.length != 6 || lines[0] != 'بلو') return null;
    final incoming = lines[1] == 'واریز پول';
    if (!incoming && lines[1] != 'برداشت پول') return null;
    final transaction = RegExp(
      '^(?:[\\u0600-\\u06ff\\u200c ]{1,80}|<NAME>) عزیز،\\s*($_number)\\s*ریال '
      r'(از حساب شما پرید\.|به حساب شما نشست\.)$',
    ).firstMatch(lines[2]);
    final balance = RegExp('^موجودی:\\s*($_number)\\s+ریال\$')
        .firstMatch(lines[3]);
    final time = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(lines[4]);
    if (transaction == null ||
        balance == null ||
        time == null ||
        !RegExp(r'^14\d{2}\.\d{2}\.\d{2}$').hasMatch(lines[5])) {
      return null;
    }
    if ((transaction.group(2) == 'به حساب شما نشست.') != incoming) return null;
    final amount = services.integer(transaction.group(1)!, SmsMoneyUnit.rial);
    final remaining = services.integer(balance.group(1)!, SmsMoneyUnit.rial);
    final date = services.date(lines[5].replaceAll('.', '/'))?.$1;
    final hour = int.parse(time.group(1)!);
    final minute = int.parse(time.group(2)!);
    if (amount == null ||
        amount <= 0 ||
        remaining == null ||
        date == null ||
        hour > 23 ||
        minute > 59) {
      return null;
    }
    return ParsedSms(
      amount: Money(minorUnits: amount, currency: 'IRR'),
      balance: Money(minorUnits: remaining, currency: 'IRR'),
      currencyEvidence: SmsCurrencyEvidence(
        sourceAmount: amount,
        detectedUnit: SmsMoneyUnit.rial,
      ),
      occurredAt: DateTime(date.year, date.month, date.day, hour, minute),
      sourceDate: lines[5],
      sourceTime: lines[4],
      direction: incoming
          ? TransactionDirection.incoming
          : TransactionDirection.outgoing,
      quality: ParseQuality.high,
      confidence: 90,
      bank: 'بلو',
    );
  }

  ParsedSms? _parseMellat(
    String? sender,
    List<String> lines,
    LayeredProfileServices services,
  ) {
    if (sender != 'BANK MELLAT' && lines.firstOrNull != 'بانک ملت') {
      return null;
    }
    if (lines.length != 4 || !lines[0].startsWith('حساب')) return null;
    final account = RegExp(r'^حساب\s*([0-9]{4,32})$').firstMatch(lines[0]);
    final transaction = RegExp(
      '^(برداشت|واریز)\\s*($_number)([+-])?'
      r'$',
    ).firstMatch(lines[1]);
    final balance = RegExp(
      '^مانده\\s*($_number)'
      r'$',
    ).firstMatch(lines[2]);
    final stamp = RegExp(
      r'^(?<date>[0-9]{2}/[0-9]{2}/[0-9]{2})-(?<time>[0-9]{2}:[0-9]{2})$',
    ).firstMatch(lines[3]);
    if (account == null ||
        transaction == null ||
        balance == null ||
        stamp == null) {
      return null;
    }
    final sign = transaction.group(3);
    final incoming = transaction.group(1) == 'واریز' || sign == '+';
    if (sign == '-' && incoming || sign == '+' && !incoming) return null;
    return services.buildProfiled(
      amountText: transaction.group(2)!,
      balanceText: balance.group(1)!,
      dateText: stamp.namedGroup('date'),
      timeText: stamp.namedGroup('time'),
      account: account.group(1)!,
      bank: 'ملت',
      direction: incoming
          ? TransactionDirection.incoming
          : TransactionDirection.outgoing,
      occurredAt: null,
      confidence: 86,
    );
  }

  ParsedSms? _parseRefah(
    String? sender,
    List<String> lines,
    LayeredProfileServices services,
  ) {
    if (sender != 'بانک رفاه' &&
        sender != 'BANK REFAH' &&
        lines.firstOrNull != 'بانک رفاه') {
      return null;
    }
    if (lines.length != 5 || !lines[1].startsWith('حساب')) return null;
    final account = RegExp(r'^حساب\s*([0-9]{4,32})$').firstMatch(lines[1]);
    final transaction = RegExp('^کارت\\s*($_number)([+-])\$')
        .firstMatch(lines[2]);
    final balance = RegExp('^مانده\\s*($_number)\$').firstMatch(lines[3]);
    final stamp = RegExp(
      r'^(?<date>[0-9]{2}/[0-9]{2})-(?<time>[0-9]{2}:[0-9]{2})$',
    ).firstMatch(lines[4]);
    if (account == null || transaction == null || balance == null) return null;
    return services.buildProfiled(
      amountText: transaction.group(1)!,
      balanceText: balance.group(1)!,
      dateText: stamp?.namedGroup('date'),
      timeText: stamp?.namedGroup('time'),
      account: account.group(1)!,
      bank: 'رفاه',
      direction: transaction.group(2) == '+'
          ? TransactionDirection.incoming
          : TransactionDirection.outgoing,
      occurredAt: null,
      confidence: 84,
    );
  }

  ParsedSms? _parseSina(
    String? sender,
    List<String> lines,
    LayeredProfileServices services,
  ) {
    if (sender != 'SINA BANK' && lines.firstOrNull != 'بانک سینا') return null;
    if (lines.length != 5) return null;
    final operation = RegExp(
      r'^(برداشت از|واریز به)\s+([0-9]{1,32}(?:-[0-9]{1,32}){2,4})$',
    ).firstMatch(lines[1]);
    final amount = RegExp('^مبلغ\\s*:?\\s*($_number)\\s*(ریال|تومان)\$')
        .firstMatch(lines[2]);
    final balance = RegExp('^مانده\\s*:?\\s*($_number)\\s*(ریال|تومان)\$')
        .firstMatch(lines[3]);
    final stamp = RegExp(
      r'^زمان\s*:\s*(?<date>[0-9]{4}/[0-9]{1,2}/[0-9]{1,2})\s*;\s*(?<time>[0-9]{2}:[0-9]{2}(?::[0-9]{2})?)$',
    ).firstMatch(lines[4]);
    if (operation == null ||
        amount == null ||
        balance == null ||
        stamp == null) {
      return null;
    }
    final amountUnit = _unit(amount.group(2)!);
    final balanceUnit = _unit(balance.group(2)!);
    final parsedAmount = services.integer(amount.group(1)!, amountUnit);
    final parsedBalance = services.integer(balance.group(1)!, balanceUnit);
    final date = services.date(stamp.namedGroup('date')!);
    final timeText = stamp.namedGroup('time')!;
    final parts = timeText.split(':').map(int.parse).toList();
    if (parsedAmount == null ||
        parsedAmount <= 0 ||
        parsedBalance == null ||
        date == null ||
        parts[0] > 23 ||
        parts[1] > 59 ||
        (parts.length == 3 && parts[2] > 59)) {
      return null;
    }
    return services.buildSina(
      amountText: amount.group(1)!,
      amountUnit: amountUnit,
      balanceText: balance.group(1)!,
      balanceUnit: balanceUnit,
      dateText: stamp.namedGroup('date')!,
      timeText: timeText,
      account: operation.group(2)!,
      direction: operation.group(1) == 'واریز به'
          ? TransactionDirection.incoming
          : TransactionDirection.outgoing,
      confidence: 90,
    );
  }

  ParsedSms? _parseParsian(
    String? sender,
    List<String> lines,
    LayeredProfileServices services,
  ) {
    if (sender != 'PARSIANBANK' || lines.length < 4) return null;
    final account = RegExp(r'^([0-9]{8,32})$').firstMatch(lines[0]);
    final transaction = RegExp('^مبلغ\\s*:?\\s*($_number)([+-])\$')
        .firstMatch(lines[1]);
    final balance = RegExp('^مانده\\s*:?\\s*($_number)\$').firstMatch(lines[2]);
    final stamp = RegExp(r'^([0-9]{2}/[0-9]{2})$').firstMatch(lines[3]);
    if (account == null ||
        transaction == null ||
        balance == null ||
        stamp == null) {
      return null;
    }
    return services.buildProfiled(
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

  ParsedSms? _parseMelli(
    String? sender,
    List<String> lines,
    LayeredProfileServices services,
  ) {
    if (sender != 'BANK MELLI' && lines.firstOrNull != 'بانک ملی ایران') {
      return null;
    }
    if (lines.length != 5 || lines[0] != 'بانک ملی ایران') return null;
    final operation = RegExp(
      '^(برداشت|واریز|انتقال|خریداینترنتی)\\s*:?\\s*($_number)([+-])?'
      r'$',
    ).firstMatch(lines[1]);
    final account = RegExp(r'^حساب\s*:?\s*([0-9]{4,32})$').firstMatch(lines[2]);
    final balance = RegExp('^مانده\\s*:?\\s*($_number)\$').firstMatch(lines[3]);
    final stamp = RegExp(r'^(?<date>[0-9]{4})-(?<time>[0-9]{2}:[0-9]{2})$')
        .firstMatch(lines[4]);
    if (operation == null || account == null || balance == null) return null;
    if (operation.group(1) == 'انتقال') return null;
    final incoming = operation.group(1) == 'واریز';
    final sign = operation.group(3);
    if (sign == '-' && incoming || sign == '+' && !incoming) return null;
    return services.buildProfiled(
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

  SmsMoneyUnit _unit(String value) =>
      value == 'تومان' ? SmsMoneyUnit.toman : SmsMoneyUnit.rial;
}
