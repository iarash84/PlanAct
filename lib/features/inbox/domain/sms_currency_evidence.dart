import 'package:planact/core/errors/app_error.dart';

/// SMS source units are evidence, not a display preference.
/// Kept local so ingestion never depends on Settings or a presentation default.
enum SmsMoneyUnit {
  rial,
  toman;

  String get label => this == rial ? 'ریال' : 'تومان';

  int canonicalIrr(int value) {
    final result = BigInt.from(value) * BigInt.from(this == toman ? 10 : 1);
    if (result > BigInt.parse('9223372036854775807') || result <= BigInt.zero) {
      throw const ValidationError('مبلغ خارج از محدودهٔ مجاز است.');
    }
    return result.toInt();
  }
}

/// Null evidence on a draft means legacy, not an ambiguous newly parsed SMS.
class SmsCurrencyEvidence {
  const SmsCurrencyEvidence({
    required this.sourceAmount,
    this.detectedUnit,
    this.selectedUnit,
  });

  final int sourceAmount;
  final SmsMoneyUnit? detectedUnit;
  final SmsMoneyUnit? selectedUnit;
  SmsMoneyUnit? get effectiveUnit => selectedUnit ?? detectedUnit;
  bool get requiresSelection => effectiveUnit == null;

  SmsCurrencyEvidence select(SmsMoneyUnit unit) => SmsCurrencyEvidence(
    sourceAmount: sourceAmount,
    detectedUnit: detectedUnit,
    selectedUnit: unit,
  );

  Map<String, dynamic> toJson() => {
    'version': 1,
    'sourceAmount': sourceAmount,
    'detectedUnit': detectedUnit?.name,
    'selectedUnit': selectedUnit?.name,
  };

  factory SmsCurrencyEvidence.fromJson(Map<String, dynamic> json) {
    if (json['version'] != 1) {
      throw const ValidationError('نسخهٔ شواهد واحد پیامک پشتیبانی نمی‌شود.');
    }
    return SmsCurrencyEvidence(
      sourceAmount: json['sourceAmount'] as int,
      detectedUnit: json['detectedUnit'] == null
          ? null
          : SmsMoneyUnit.values.byName(json['detectedUnit'] as String),
      selectedUnit: json['selectedUnit'] == null
          ? null
          : SmsMoneyUnit.values.byName(json['selectedUnit'] as String),
    );
  }

  /// Only immediately adjacent units belong to this amount. Units attached to
  /// later balances, account descriptions or unrelated text are not evidence.
  static SmsMoneyUnit? amountBoundUnit(String text, int amountEnd) {
    final suffix = text.substring(amountEnd);
    final match = RegExp(
      r'^\s*(ریال|تومان|rials?|tomans?|irr)(?![a-zA-Zآ-ی])(?:\s*[/،,]\s*(ریال|تومان|rials?|tomans?|irr)(?![a-zA-Zآ-ی]))?',
      caseSensitive: false,
    ).firstMatch(suffix);
    if (match == null) return null;
    SmsMoneyUnit unit(String token) =>
        RegExp(r'تومان|toman', caseSensitive: false).hasMatch(token)
        ? SmsMoneyUnit.toman
        : SmsMoneyUnit.rial;
    final first = unit(match.group(1)!);
    if (match.group(2) != null && unit(match.group(2)!) != first) return null;
    return first;
  }
}
