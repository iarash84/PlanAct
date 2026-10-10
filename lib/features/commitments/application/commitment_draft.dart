import 'package:planact/core/localization/persian_numbers.dart';
import 'package:planact/features/commitments/domain/commitment.dart';
import 'package:planact/features/finance/domain/financial_expectation.dart';
import 'package:planact/features/scheduling/domain/schedule_definition.dart';

/// Presentation-only state used by the progressive commitment wizard.
class CommitmentDraft {
  const CommitmentDraft({
    this.category = CommitmentCategory.other,
    this.title = '',
    this.description,
    this.color,
    this.provider,
    this.kind = CommitmentKind.oneOff,
    this.startAt,
    this.frequency = RecurrenceFrequency.weekly,
    this.recurrenceCalendar = RecurrenceCalendar.jalali,
    this.termination = RecurrenceTermination.open,
    this.weekdays = const {},
    this.dayOfMonth,
    this.occurrenceCount,
    this.endDate,
    this.entitlement = EntitlementDraft.none,
    this.entitlementUnits,
    this.financialMeaning = CommitmentFinancialMeaning.none,
    this.financialAmount,
    this.priority = CommitmentPriority.normal,
    this.tags = const {},
    this.reminderOffsets = const [],
    this.attachmentIds = const [],
  });

  final CommitmentCategory category;
  final String title;
  final String? description;
  final CommitmentColor? color;
  final String? provider;
  final CommitmentKind kind;
  final DateTime? startAt;
  final RecurrenceFrequency frequency;
  final RecurrenceCalendar recurrenceCalendar;
  final RecurrenceTermination termination;
  final Set<int> weekdays;
  final int? dayOfMonth;
  final int? occurrenceCount;
  final DateTime? endDate;
  final EntitlementDraft entitlement;
  final int? entitlementUnits;
  final CommitmentFinancialMeaning financialMeaning;
  final int? financialAmount;
  final CommitmentPriority priority;
  final Set<String> tags;
  final List<Duration> reminderOffsets;
  final List<String> attachmentIds;

  bool get isRecurring => kind == CommitmentKind.recurring;
  bool get hasEntitlement => entitlement != EntitlementDraft.none;
  List<DateTime> get scheduledDates => startAt == null ? const [] : [startAt!];

  CommitmentDraft copyWith({
    CommitmentCategory? category,
    String? title,
    String? description,
    CommitmentColor? color,
    bool clearColor = false,
    String? provider,
    CommitmentKind? kind,
    DateTime? startAt,
    RecurrenceFrequency? frequency,
    RecurrenceCalendar? recurrenceCalendar,
    RecurrenceTermination? termination,
    bool clearOccurrenceCount = false,
    Set<int>? weekdays,
    int? dayOfMonth,
    int? occurrenceCount,
    DateTime? endDate,
    EntitlementDraft? entitlement,
    int? entitlementUnits,
    CommitmentFinancialMeaning? financialMeaning,
    int? financialAmount,
    CommitmentPriority? priority,
    Set<String>? tags,
    List<Duration>? reminderOffsets,
    List<String>? attachmentIds,
  }) => CommitmentDraft(
    category: category ?? this.category,
    title: title ?? this.title,
    description: description ?? this.description,
    color: clearColor ? null : color ?? this.color,
    provider: provider ?? this.provider,
    kind: kind ?? this.kind,
    startAt: startAt ?? this.startAt,
    frequency: frequency ?? this.frequency,
    recurrenceCalendar: recurrenceCalendar ?? this.recurrenceCalendar,
    termination: termination ?? this.termination,
    weekdays: weekdays ?? this.weekdays,
    dayOfMonth: dayOfMonth ?? this.dayOfMonth,
    occurrenceCount: clearOccurrenceCount
        ? null
        : occurrenceCount ?? this.occurrenceCount,
    endDate: endDate ?? this.endDate,
    entitlement: entitlement ?? this.entitlement,
    entitlementUnits: entitlementUnits ?? this.entitlementUnits,
    financialMeaning: financialMeaning ?? this.financialMeaning,
    financialAmount: financialAmount ?? this.financialAmount,
    priority: priority ?? this.priority,
    tags: tags ?? this.tags,
    reminderOffsets: reminderOffsets ?? this.reminderOffsets,
    attachmentIds: attachmentIds ?? this.attachmentIds,
  );

  String? validateForStep(int step) {
    if (step == 1 && title.trim().isEmpty) return 'عنوان تعهد را وارد کنید.';
    if (step == 2 && startAt == null) {
      return 'تاریخ و زمان شروع را انتخاب کنید.';
    }
    if (step == 2 &&
        isRecurring &&
        frequency == RecurrenceFrequency.weekly &&
        weekdays.isEmpty) {
      return 'حداقل یک روز هفته را انتخاب کنید.';
    }
    if (step == 3 &&
        entitlement == EntitlementDraft.fixedUnits &&
        (entitlementUnits == null || entitlementUnits! <= 0)) {
      return 'تعداد جلسهٔ معتبر را وارد کنید.';
    }
    if (step == 3 &&
        financialMeaning != CommitmentFinancialMeaning.none &&
        (financialAmount == null || financialAmount! <= 0)) {
      return 'مبلغ مورد انتظار را وارد کنید.';
    }
    if (isRecurring &&
        termination == RecurrenceTermination.count &&
        (occurrenceCount == null || occurrenceCount! <= 0)) {
      return 'تعداد تکرار را وارد کنید.';
    }
    if (isRecurring &&
        termination == RecurrenceTermination.endDate &&
        endDate == null) {
      return 'تاریخ پایان را انتخاب کنید.';
    }
    if (isRecurring &&
        termination == RecurrenceTermination.count &&
        occurrenceCount != null &&
        occurrenceCount! <= 0) {
      return 'تعداد تکرار باید مثبت باشد.';
    }
    if (termination == RecurrenceTermination.endDate &&
        endDate != null &&
        startAt != null &&
        LocalDate.fromDateTime(endDate!)
                .compareTo(LocalDate.fromDateTime(startAt!)) <
            0) {
      return 'پایان برنامه نمی‌تواند قبل از شروع باشد.';
    }
    return null;
  }

  String reviewSummary() {
    final schedule = !isRecurring
        ? 'یک‌بار در ${startAt == null ? 'زمان انتخاب‌شده' : 'تاریخ انتخاب‌شده'}'
        : 'تکرار ${_frequencyLabel(frequency)} · ${recurrenceCalendar == RecurrenceCalendar.jalali ? 'تقویم شمسی' : 'تقویم میلادی'} · ${switch (termination) {
            RecurrenceTermination.open => 'بدون پایان',
            RecurrenceTermination.count => '${PersianNumbers.format(occurrenceCount ?? 0)} نوبت',
            RecurrenceTermination.endDate => 'تا تاریخ پایان انتخاب‌شده',
          }}';
    final package = switch (entitlement) {
      EntitlementDraft.none => 'بدون بستهٔ جلسه',
      EntitlementDraft.unlimited => 'بدون محدودیت تعداد جلسه',
      EntitlementDraft.fixedUnits =>
        '${PersianNumbers.format(entitlementUnits ?? 0)} جلسه',
      EntitlementDraft.validUntil => 'معتبر تا تاریخ انتخاب‌شده',
    };
    final finance = switch (financialMeaning) {
      CommitmentFinancialMeaning.none => 'بدون انتظار مالی',
      CommitmentFinancialMeaning.paymentRequired =>
        'نیازمند پرداخت (${PersianNumbers.format(financialAmount ?? 0)} تومان)',
      CommitmentFinancialMeaning.receivable =>
        'دارای دریافتی مورد انتظار (${PersianNumbers.format(financialAmount ?? 0)} تومان)',
    };
    return '$title · $schedule · $package · $finance';
  }

  String _frequencyLabel(RecurrenceFrequency value) => switch (value) {
    RecurrenceFrequency.daily => 'روزانه',
    RecurrenceFrequency.weekly => 'هفتگی',
    RecurrenceFrequency.monthly => 'ماهانه',
    RecurrenceFrequency.yearly => 'سالانه',
  };
}

enum RecurrenceTermination { open, endDate, count }

enum CommitmentCategory {
  classCourse,
  appointment,
  personalRecurring,
  subscription,
  other,
}

enum EntitlementDraft { none, unlimited, fixedUnits, validUntil }

enum CommitmentFinancialMeaning { none, paymentRequired, receivable }

extension CommitmentFinancialMeaningX on CommitmentFinancialMeaning {
  FinancialExpectationDirection? get expectationDirection => switch (this) {
    CommitmentFinancialMeaning.none => null,
    CommitmentFinancialMeaning.paymentRequired =>
      FinancialExpectationDirection.outgoing,
    CommitmentFinancialMeaning.receivable =>
      FinancialExpectationDirection.incoming,
  };
}
