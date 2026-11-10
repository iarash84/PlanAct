import 'package:planact/features/inbox/application/inbox_use_cases.dart';
import 'package:planact/features/inbox/application/sms_parser_support.dart';
import 'package:planact/features/inbox/domain/inbox.dart';

/// Unknown layouts are admitted only by a complete, bounded evidence grammar.
/// Never searches arbitrary prose for numbers or derives identity from a sender.
final class EvidenceBankSmsFallback {
  const EvidenceBankSmsFallback();

  ParsedSms? parse(SmsParseContext context) {
    if (context.currency != 'IRR') return null;
    final fields = <String, String>{};
    RegExpMatch? operation;
    for (final line in context.lines) {
      final candidate = RegExp(
        r'^(برداشت از|واریز به|انتقال از|انتقال به) حساب\s*:\s*([0-9*]{4,32})$',
      ).firstMatch(line);
      if (candidate != null) {
        if (operation != null) return null;
        operation = candidate;
        continue;
      }
      final field = RegExp(r'^(مبلغ|مانده|موجودی|تاریخ|ساعت)\s*:\s*(.+)$')
          .firstMatch(line);
      if (field == null) return null;
      final key = field.group(1) == 'موجودی' ? 'مانده' : field.group(1)!;
      if (fields.containsKey(key)) return null;
      fields[key] = field.group(2)!;
    }
    if (operation == null ||
        !fields.containsKey('مبلغ') ||
        !fields.containsKey('مانده')) {
      return null;
    }
    final label = operation.group(1)!;
    final transfer = label.startsWith('انتقال');
    final parsed = const GenericBankSmsParser().tryParse(
      text: [
        'نوع: ${transfer
            ? 'انتقال'
            : label.startsWith('واریز')
            ? 'واریز'
            : 'برداشت'}',
        'حساب: ${operation.group(2)}',
        for (final field in fields.entries) '${field.key}: ${field.value}',
      ].join('\n'),
      currency: context.currency,
    );
    if (parsed == null) return null;
    return ParsedSms(
      amount: parsed.amount,
      balance: parsed.balance,
      currencyEvidence: parsed.currencyEvidence,
      occurredAt: parsed.occurredAt,
      sourceDate: parsed.sourceDate,
      sourceTime: parsed.sourceTime,
      accountHint: parsed.accountHint,
      direction: label.endsWith('به')
          ? TransactionDirection.incoming
          : TransactionDirection.outgoing,
      isTransfer: transfer,
      quality: ParseQuality.medium,
      confidence: 60,
    );
  }
}
