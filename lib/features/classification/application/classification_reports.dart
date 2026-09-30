import 'package:planact/features/classification/application/tag_repository.dart';
import 'package:planact/features/classification/domain/tag.dart';
import 'package:planact/features/commitments/application/commitment_repository.dart';
import 'package:planact/features/commitments/domain/commitment_reports.dart';
import 'package:planact/features/finance/application/finance_use_cases.dart';
import 'package:planact/features/finance/domain/finance.dart';
import 'package:planact/features/finance/domain/finance_reports.dart';

class FinancialActivityReport {
  const FinancialActivityReport({
    required this.entries,
    required this.summary,
    required this.byCategory,
  });
  final List<AccountEntry> entries;
  final CashFlowSummary summary;
  final List<GroupedTotal> byCategory;
}

class ClassificationReports {
  const ClassificationReports({
    required this.tags,
    required this.finance,
    required this.commitments,
  });
  final TagRepository tags;
  final FinanceRepository finance;
  final CommitmentRepository commitments;

  Future<Map<String, Set<Tag>>> _memberships(
    Iterable<String> ids,
    TaggableType type,
  ) async {
    final all = {for (final tag in await tags.list()) tag.id: tag};
    final result = <String, Set<Tag>>{};
    for (final id in ids) {
      result[id] = (await tags.tagsFor(
        id,
        type,
      )).map((tagId) => all[tagId]).whereType<Tag>().toSet();
    }
    return result;
  }

  Future<CommitmentReport> commitmentReport(CommitmentFilter filter) async {
    final records = await commitments.list();
    return buildCommitmentReport(
      records,
      filter,
      tagsByCommitment: filter.tag == null
          ? const {}
          : await _memberships(
              records.map((item) => item.id.value),
              TaggableType.commitment,
            ),
    );
  }

  Future<FinancialActivityReport> financialReport(
    FinanceFilter filter, {
    required String currency,
  }) async {
    final records = await finance.listEntries();
    final entries = filterEntries(
      records,
      filter,
      tagsByEntry: filter.tag == null
          ? const {}
          : await _memberships(
              records.map((item) => item.id.value),
              TaggableType.accountEntry,
            ),
    );
    return FinancialActivityReport(
      entries: entries,
      summary: cashFlowSummary(entries, currency),
      byCategory: groupFinancialEntries(entries, currency: currency),
    );
  }
}
