import 'package:planact/features/reminders/domain/reminder.dart';
import 'package:planact/core/localization/persian_copy.g.dart';
import 'package:planact/core/localization/persian_numbers.dart';
import 'package:planact/features/commitments/domain/commitment.dart';
import 'package:planact/features/finance/domain/financial_expectation.dart';
import 'package:planact/features/scheduling/domain/schedule_definition.dart';

/// Presentation-only state used by the single-page commitment form.
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
    this.checklistTitles = const [],
    this.reminderOffsets = const [],
    this.reminderDelivery = ReminderDelivery.notification,
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
  final List<String> checklistTitles;
  final List<Duration> reminderOffsets;
  final ReminderDelivery reminderDelivery;
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
    bool clearEntitlementUnits = false,
    CommitmentFinancialMeaning? financialMeaning,
    int? financialAmount,
    bool clearFinancialAmount = false,
    CommitmentPriority? priority,
    Set<String>? tags,
    List<String>? checklistTitles,
    List<Duration>? reminderOffsets,
    ReminderDelivery? reminderDelivery,
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
    entitlementUnits: clearEntitlementUnits
        ? null
        : entitlementUnits ?? this.entitlementUnits,
    financialMeaning: financialMeaning ?? this.financialMeaning,
    financialAmount: clearFinancialAmount
        ? null
        : financialAmount ?? this.financialAmount,
    priority: priority ?? this.priority,
    tags: tags ?? this.tags,
    checklistTitles: checklistTitles ?? this.checklistTitles,
    reminderOffsets: reminderOffsets ?? this.reminderOffsets,
    reminderDelivery: reminderDelivery ?? this.reminderDelivery,
    attachmentIds: attachmentIds ?? this.attachmentIds,
  );

  String? validateForStep(int step) {
    if (step == 1 && title.trim().isEmpty) {
      return PersianCopy.commitmentTitleRequired;
    }
    if (step == 2 && startAt == null) {
      return PersianCopy.quickCaptureSheetErrorMessage;
    }
    if (step == 2 &&
        isRecurring &&
        frequency == RecurrenceFrequency.weekly &&
        weekdays.isEmpty) {
      return PersianCopy.commitmentDraftValidateForStepMessage;
    }
    if (step == 3 &&
        entitlement == EntitlementDraft.fixedUnits &&
        (entitlementUnits == null || entitlementUnits! <= 0)) {
      return PersianCopy.commitmentDraftValidateForStepMessage2;
    }
    if (step == 3 &&
        financialMeaning != CommitmentFinancialMeaning.none &&
        (financialAmount == null || financialAmount! <= 0)) {
      return PersianCopy.commitmentDraftValidateForStepMessage3;
    }
    if (isRecurring &&
        termination == RecurrenceTermination.count &&
        (occurrenceCount == null || occurrenceCount! <= 0)) {
      return PersianCopy.commitmentDraftValidateForStepMessage4;
    }
    if (isRecurring &&
        termination == RecurrenceTermination.endDate &&
        endDate == null) {
      return PersianCopy.commitmentDraftValidateForStepMessage5;
    }
    if (isRecurring &&
        termination == RecurrenceTermination.count &&
        occurrenceCount != null &&
        occurrenceCount! <= 0) {
      return PersianCopy.commitmentDraftValidateForStepMessage6;
    }
    if (termination == RecurrenceTermination.endDate &&
        endDate != null &&
        startAt != null &&
        LocalDate.fromDateTime(endDate!)
                .compareTo(LocalDate.fromDateTime(startAt!)) <
            0) {
      return PersianCopy.commitmentDraftValidateForStepMessage7;
    }
    return null;
  }

  String reviewSummary({String? formattedFinancialAmount}) {
    final schedule = !isRecurring
        ? PersianCopy.commitmentDraftScheduleMessage3(
            (startAt == null
                    ? PersianCopy.commitmentDraftScheduleMessage2
                    : PersianCopy.commitmentDraftScheduleMessage)
                .toString(),
          )
        : PersianCopy.commitmentDraftScheduleMessage6(
            (_frequencyLabel(frequency)).toString(),
            (recurrenceCalendar == RecurrenceCalendar.jalali
                    ? PersianCopy.commitmentDraftScheduleMessage5
                    : PersianCopy.commitmentDraftScheduleMessage4)
                .toString(),
            (switch (termination) {
              RecurrenceTermination.open =>
                PersianCopy.quickCaptureSheetScheduleFieldsItems3,
              RecurrenceTermination.count =>
                PersianCopy.commitmentDraftRecurrenceTerminationCount(
                  (PersianNumbers.format(occurrenceCount ?? 0)).toString(),
                ),
              RecurrenceTermination.endDate =>
                PersianCopy.commitmentDraftRecurrenceTerminationEndDate,
            }).toString(),
          );
    final package = switch (entitlement) {
      EntitlementDraft.none => null,
      EntitlementDraft.unlimited =>
        PersianCopy.commitmentDraftEntitlementDraftUnlimited,
      EntitlementDraft.fixedUnits =>
        PersianCopy.commitmentDraftEntitlementDraftFixedUnits(
          (PersianNumbers.format(entitlementUnits ?? 0)).toString(),
        ),
      EntitlementDraft.validUntil =>
        PersianCopy.commitmentDraftEntitlementDraftValidUntil,
    };
    final finance = switch (financialMeaning) {
      CommitmentFinancialMeaning.none =>
        PersianCopy.quickCaptureSheetCommitmentFinancialMeaningNone,
      CommitmentFinancialMeaning.paymentRequired =>
        PersianCopy.commitmentDraftCommitmentFinancialMeaningPaymentRequired2(
          (formattedFinancialAmount ??
                  PersianCopy.commitmentDraftCommitmentFinancialMeaningPaymentRequired(
                    (PersianNumbers.format(financialAmount ?? 0)).toString(),
                  ))
              .toString(),
        ),
      CommitmentFinancialMeaning.receivable =>
        PersianCopy.commitmentDraftCommitmentFinancialMeaningReceivable(
          (formattedFinancialAmount ??
                  PersianCopy.commitmentDraftCommitmentFinancialMeaningPaymentRequired(
                    (PersianNumbers.format(financialAmount ?? 0)).toString(),
                  ))
              .toString(),
        ),
    };
    return [title, schedule, ?package, finance].join(' · ');
  }

  String _frequencyLabel(RecurrenceFrequency value) => switch (value) {
    RecurrenceFrequency.daily => PersianCopy.recurrenceDaily,
    RecurrenceFrequency.weekly => PersianCopy.recurrenceWeekly,
    RecurrenceFrequency.monthly => PersianCopy.recurrenceMonthly,
    RecurrenceFrequency.yearly => PersianCopy.recurrenceYearly,
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
