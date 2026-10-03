import 'package:flutter_test/flutter_test.dart';
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/core/money/money.dart';
import 'package:planact/features/classification/application/classification_reports.dart';
import 'package:planact/features/classification/application/tag_repository.dart';
import 'package:planact/features/commitments/application/commitment_repository.dart';
import 'package:planact/features/commitments/domain/commitment.dart';
import 'package:planact/features/commitments/domain/commitment_reports.dart';
import 'package:planact/features/finance/application/finance_use_cases.dart';
import 'package:planact/features/finance/domain/finance.dart';
import 'package:planact/features/finance/domain/finance_reports.dart';

void main() {
  test('filters deterministic reports by normalized tags and totals', () async {
    final tags = InMemoryTagRepository();
    final work = await tags.getOrCreate('#کار');
    final account = FinancialAccount(
      id: StableId.generate(),
      name: 'کیف پول',
      currency: 'تومان',
      type: FinancialAccountType.cash,
    );
    final entry = AccountEntry(
      id: StableId.generate(),
      accountId: account.id,
      type: AccountEntryType.expense,
      amount: Money(minorUnits: 2500, currency: 'تومان'),
      occurredAt: DateTime.utc(2026, 1, 2),
    );
    await tags.attach(
      recordId: entry.id.value,
      tag: work,
      type: TaggableType.accountEntry,
    );
    final commitment = Commitment.create(
      title: 'گزارش',
      now: DateTime.utc(2026, 1, 3),
    );
    await tags.attach(
      recordId: commitment.id.value,
      tag: work,
      type: TaggableType.commitment,
    );
    final reports = ClassificationReports(
      tags: tags,
      finance: InMemoryFinanceRepository()..saveAccount(account),
      commitments: InMemoryCommitmentRepository()..save(commitment),
    );
    await reports.finance.saveEntry(entry);

    final finance = await reports.financialReport(
      FinanceFilter(tag: work),
      currency: 'تومان',
    );
    expect(finance.entries, hasLength(1));
    expect(finance.summary.outgoing, 2500);
    expect(finance.summary.net, -2500);
    final commitments = await reports.commitmentReport(
      CommitmentFilter(tag: work),
    );
    expect(commitments.items.single.id, commitment.id);
  });
}
