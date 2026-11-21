import 'package:flutter/material.dart';
import 'package:planact/app/theme/planact_spacing.dart';
import 'package:planact/core/localization/planact_localizations.dart';

class HelpFaqPage extends StatelessWidget {
  const HelpFaqPage({super.key});

  List<_FaqCategory> _categories(BuildContext context) {
    final l10n = planActL10n(context);
    return [
      _FaqCategory(
        title: l10n.helpFaqGettingStartedTitle,
        items: [
          _FaqItem(
            question: l10n.helpFaqPurposeQuestion,
            answer: l10n.helpFaqPurposeAnswer,
          ),
          _FaqItem(
            question: l10n.helpFaqStartQuestion,
            answer: l10n.helpFaqStartAnswer,
          ),
          _FaqItem(
            question: l10n.helpFaqConceptsQuestion,
            answer: l10n.helpFaqConceptsAnswer,
          ),
        ],
      ),
      _FaqCategory(
        title: l10n.helpFaqCommitmentsTitle,
        items: [
          _FaqItem(
            question: l10n.helpFaqCreateQuestion,
            answer: l10n.helpFaqCreateAnswer,
          ),
          _FaqItem(
            question: l10n.helpFaqRecurrenceQuestion,
            answer: l10n.helpFaqRecurrenceAnswer,
          ),
          _FaqItem(
            question: l10n.helpFaqHistoryQuestion,
            answer: l10n.helpFaqHistoryAnswer,
          ),
          _FaqItem(
            question: l10n.helpFaqCreditQuestion,
            answer: l10n.helpFaqCreditAnswer,
          ),
          _FaqItem(
            question: l10n.helpFaqOutcomeQuestion,
            answer: l10n.helpFaqOutcomeAnswer,
          ),
        ],
      ),
      _accountsCategory(context),
      _FaqCategory(
        title: l10n.navigationFinance,
        items: [
          _FaqItem(
            question: l10n.helpFaqCorrectionQuestion,
            answer: l10n.helpFaqCorrectionAnswer,
          ),
          _FaqItem(
            question: l10n.helpFaqCorrectionHistoryQuestion,
            answer: l10n.helpFaqCorrectionHistoryAnswer,
          ),
          _FaqItem(
            question: l10n.helpFaqRelationshipQuestion,
            answer: l10n.helpFaqRelationshipAnswer,
          ),
          _FaqItem(
            question: l10n.helpFaqCreateAccountQuestion,
            answer: l10n.helpFaqCreateAccountAnswer,
          ),
          _FaqItem(
            question: l10n.helpFaqTransferQuestion,
            answer: l10n.helpFaqTransferAnswer,
          ),
          _FaqItem(
            question: l10n.helpFaqPaymentQuestion,
            answer: l10n.helpFaqPaymentAnswer,
          ),
          _FaqItem(
            question: l10n.helpFaqMoneyQuestion,
            answer: l10n.helpFaqMoneyAnswer,
          ),
        ],
      ),
      _FaqCategory(
        title: l10n.helpFaqInboxTitle,
        items: [
          _FaqItem(
            question: l10n.helpFaqSmsNotificationQuestion,
            answer: l10n.helpFaqSmsNotificationAnswer,
          ),
          _FaqItem(
            question: l10n.helpFaqSmsConsentQuestion,
            answer: l10n.helpFaqSmsConsentAnswer,
          ),
          _FaqItem(
            question: l10n.helpFaqSmsConfirmQuestion,
            answer: l10n.helpFaqSmsConfirmAnswer,
          ),
          _FaqItem(
            question: l10n.helpFaqSmsUnitQuestion,
            answer: l10n.helpFaqSmsUnitAnswer,
          ),
          _FaqItem(
            question: l10n.helpFaqSmsRejectQuestion,
            answer: l10n.helpFaqSmsRejectAnswer,
          ),
        ],
      ),
      _FaqCategory(
        title: l10n.reminderPlatformScheduleAndroid,
        items: [
          _FaqItem(
            question: l10n.helpFaqReminderSetupQuestion,
            answer: l10n.helpFaqReminderSetupAnswer,
          ),
          _FaqItem(
            question: l10n.helpFaqReminderCleanupQuestion,
            answer: l10n.helpFaqReminderCleanupAnswer,
          ),
          _FaqItem(
            question: l10n.helpFaqDeliveryQuestion,
            answer: l10n.helpFaqDeliveryAnswer,
          ),
        ],
      ),
      _FaqCategory(
        title: l10n.helpFaqCalendarTitle,
        items: [
          _FaqItem(
            question: l10n.helpFaqCalendarVisibilityQuestion,
            answer: l10n.helpFaqCalendarVisibilityAnswer,
          ),
          _FaqItem(
            question: l10n.helpFaqNotesChecklistQuestion,
            answer: l10n.helpFaqNotesChecklistAnswer,
          ),
        ],
      ),
      _FaqCategory(
        title: l10n.helpFaqBackupTitle,
        items: [
          _FaqItem(
            question: l10n.helpFaqStorageQuestion,
            answer: l10n.helpFaqStorageAnswer,
          ),
          _FaqItem(
            question: l10n.helpFaqOfflineQuestion,
            answer: l10n.helpFaqOfflineAnswer,
          ),
          _FaqItem(
            question: l10n.helpFaqBackupQuestion,
            answer: l10n.helpFaqBackupAnswer,
          ),
          _FaqItem(
            question: l10n.helpFaqRecoveryKeyQuestion,
            answer: l10n.helpFaqRecoveryKeyAnswer,
          ),
        ],
      ),
    ];
  }

  _FaqCategory _accountsCategory(BuildContext context) {
    final l10n = planActL10n(context);
    return _FaqCategory(
      title: l10n.helpAccountsTitle,
      items: [
        _FaqItem(
          question: l10n.helpAccountsManageQuestion,
          answer: l10n.helpAccountsManageAnswer,
        ),
        _FaqItem(
          question: l10n.helpAccountsPrivacyQuestion,
          answer: l10n.helpAccountsPrivacyAnswer,
        ),
        _FaqItem(
          question: l10n.helpAccountsBalanceQuestion,
          answer: l10n.helpAccountsBalanceAnswer,
        ),
        _FaqItem(
          question: l10n.helpAccountsReviewQuestion,
          answer: l10n.helpAccountsReviewAnswer,
        ),
        _FaqItem(
          question: l10n.helpAccountsReconcileQuestion,
          answer: l10n.helpAccountsReconcileAnswer,
        ),
        _FaqItem(
          question: l10n.helpAccountsRecoveryQuestion,
          answer: l10n.helpAccountsRecoveryAnswer,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(planActL10n(context).helpFaqPageTitle)),
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(PlanActSpacing.page),
        children: [
          for (final category in _categories(context))
            Padding(
              padding: const EdgeInsets.only(bottom: PlanActSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category.title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: PlanActSpacing.md),
                  for (final item in category.items)
                    Card(
                      margin: const EdgeInsets.only(bottom: PlanActSpacing.sm),
                      child: ExpansionTile(
                        key: ValueKey(item.question),
                        title: Text(item.question),
                        initiallyExpanded: false,
                        childrenPadding: const EdgeInsets.fromLTRB(
                          PlanActSpacing.lg,
                          0,
                          PlanActSpacing.lg,
                          PlanActSpacing.lg,
                        ),
                        children: [
                          Text(item.answer, textAlign: TextAlign.start),
                        ],
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    ),
  );
}

class _FaqCategory {
  const _FaqCategory({required this.title, required this.items});

  final String title;
  final List<_FaqItem> items;
}

class _FaqItem {
  const _FaqItem({required this.question, required this.answer});

  final String question;
  final String answer;
}
