import 'package:planact/features/classification/application/tag_repository.dart';
import 'package:planact/features/commitments/application/commitment_repository.dart';
import 'package:planact/features/commitments/application/commitment_plan_use_case.dart';
import 'package:planact/features/finance/application/finance_use_cases.dart';
import 'package:planact/features/finance/application/financial_expectation_use_cases.dart';
import 'package:planact/features/reports/application/reports_reader.dart';
import 'package:planact/features/reports/domain/personal_reports.dart';
import 'package:planact/core/ids/stable_id.dart';

/// Test/preview seam for the existing injected HomeShell repositories.
/// Production uses DriftReportsReader to include every historical cycle.
class RepositoryReportsReader implements ReportsReader {
  const RepositoryReportsReader({
    required this.commitments,
    required this.plans,
    required this.finance,
    required this.expectations,
    required this.tags,
  });
  final CommitmentRepository commitments;
  final CommitmentPlanRepository plans;
  final FinanceRepository finance;
  final FinancialExpectationRepository expectations;
  final TagRepository tags;
  @override
  Future<ReportSnapshot> read(
    ReportFilter filter, {
    required DateTime now,
    bool includePreviews = false,
  }) async {
    final owners = await commitments.list();
    final savedPlans = <CommitmentPlan>[];
    final memberships = <StableId, Set<StableId>>{};
    for (final owner in owners) {
      final plan = await plans.findByCommitmentId(owner.id);
      if (plan != null) savedPlans.add(plan);
      memberships[owner.id] = await tags.tagsFor(
        owner.id.value,
        TaggableType.commitment,
      );
    }
    final entries = await finance.listEntries();
    final entryTags = <StableId, Set<StableId>>{};
    for (final entry in entries) {
      entryTags[entry.id] = await tags.tagsFor(
        entry.id.value,
        TaggableType.accountEntry,
      );
    }
    return ReportSnapshot(
      commitments: owners,
      cycles: savedPlans.map((p) => p.cycle).toList(),
      occurrences: savedPlans.expand((p) => p.occurrences).toList(),
      accounts: await finance.listAccounts(),
      entries: entries,
      expectations: await expectations.listExpectations(),
      matches: await expectations.listMatches(),
      tags: await tags.list(),
      commitmentTags: memberships,
      entryTags: entryTags,
    );
  }
}
