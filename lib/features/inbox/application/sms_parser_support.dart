import 'package:planact/features/inbox/application/inbox_use_cases.dart';

/// Immutable input shared by all bank-layout candidates.
///
/// Normalization is deliberately kept outside individual profiles so every
/// profile evaluates the same text, sender and line boundaries.
final class SmsParseContext {
  const SmsParseContext({
    required this.text,
    required this.lines,
    required this.compactText,
    required this.currency,
    required this.sourceAddress,
    required this.normalizedSourceAddress,
  });

  final String text;
  final List<String> lines;
  final String compactText;
  final String currency;
  final String? sourceAddress;
  final String? normalizedSourceAddress;

  String? get header => lines.isEmpty ? null : lines.first;
}

final class SmsNormalizer {
  const SmsNormalizer();

  SmsParseContext normalize({
    required String text,
    required String currency,
    String? sourceAddress,
    required String Function(String) canonicalizeHeader,
  }) {
    final normalized = text
        .replaceAll(RegExp(r'[\u200e\u200f\u202a-\u202e\u2066-\u2069]'), '')
        .replaceAll('ي', 'ی')
        .replaceAll('ك', 'ک')
        .replaceAllMapped(RegExp(r'[۰-۹٠-٩]'), (match) {
          final code = match[0]!.codeUnitAt(0);
          return String.fromCharCode(
            code - (code >= 0x6f0 ? 0x6f0 : 0x660) + 48,
          );
        })
        .split(RegExp(r'\r?\n'))
        .map((line) => line.trim())
        .join('\n')
        .trim();
    final canonical = canonicalizeHeader(normalized);
    final lines = List<String>.unmodifiable(canonical.split('\n'));
    final normalizedSender = sourceAddress?.trim().toUpperCase();
    return SmsParseContext(
      text: canonical,
      lines: lines,
      compactText: canonical.replaceAll(RegExp(r'\s+'), ' ').trim(),
      currency: currency,
      sourceAddress: sourceAddress,
      normalizedSourceAddress: normalizedSender,
    );
  }
}

/// Ordered families used by the parser pipeline.
///
/// The order is explicit because two bank layouts can intentionally share a
/// shape. Adding a new family should be a registry change, not an edit to the
/// public parser contract.
enum SmsProfileFamily {
  resalatCompact,
  iranZamin,
  mehrIran,
  layeredBank,
  genericTemplate,
  compactSina,
}

final class SmsProfileRegistry {
  const SmsProfileRegistry();

  Iterable<SmsProfileFamily> candidates(SmsParseContext context) sync* {
    yield SmsProfileFamily.resalatCompact;
    yield SmsProfileFamily.iranZamin;
    yield SmsProfileFamily.mehrIran;
    yield SmsProfileFamily.layeredBank;
    yield SmsProfileFamily.genericTemplate;
    if (!context.text.contains('\n')) {
      yield SmsProfileFamily.compactSina;
    }
  }
}

/// A small internal result seam for future diagnostics.
///
/// The current public API remains `ParsedSms?`; this type is intentionally
/// private to the parsing application layer and does not alter persistence.
final class SmsProfileAttempt {
  const SmsProfileAttempt.accepted(this.value)
    : reason = null,
      isAmbiguous = false;
  const SmsProfileAttempt.rejected(this.reason)
    : value = null,
      isAmbiguous = false;
  const SmsProfileAttempt.ambiguous(this.reason)
    : value = null,
      isAmbiguous = true;

  final ParsedSms? value;
  final String? reason;
  final bool isAmbiguous;

  bool get accepted => value != null;
}
