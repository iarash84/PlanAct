import 'dart:convert';

/// Display-only preferences. Missing or unsupported data preserves legacy views.
final class CalendarVisibility {
  const CalendarVisibility({
    this.commitments = true,
    this.notes = true,
    this.income = false,
    this.expense = false,
    this.transfers = false,
  });

  final bool commitments;
  final bool notes;
  final bool income;
  final bool expense;
  final bool transfers;
  bool get hasFinancialItems => income || expense || transfers;
  bool get isDefault => commitments && notes && !hasFinancialItems;

  CalendarVisibility copyWith({
    bool? commitments,
    bool? notes,
    bool? income,
    bool? expense,
    bool? transfers,
  }) => CalendarVisibility(
    commitments: commitments ?? this.commitments,
    notes: notes ?? this.notes,
    income: income ?? this.income,
    expense: expense ?? this.expense,
    transfers: transfers ?? this.transfers,
  );

  String get storageValue => jsonEncode({
    'version': 1,
    'commitments': commitments,
    'notes': notes,
    'income': income,
    'expense': expense,
    'transfers': transfers,
  });

  static CalendarVisibility parse(String? value) {
    if (value == null) return const CalendarVisibility();
    try {
      final data = jsonDecode(value);
      if (data is! Map ||
          data['version'] != 1 ||
          [
            'commitments',
            'notes',
            'income',
            'expense',
            'transfers',
          ].any((key) => data[key] is! bool)) {
        return const CalendarVisibility();
      }
      return CalendarVisibility(
        commitments: data['commitments'] as bool,
        notes: data['notes'] as bool,
        income: data['income'] as bool,
        expense: data['expense'] as bool,
        transfers: data['transfers'] as bool,
      );
    } on FormatException {
      return const CalendarVisibility();
    }
  }
}
