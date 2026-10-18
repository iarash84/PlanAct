import 'package:planact/features/classification/application/tag_repository.dart';
import 'package:planact/features/commitments/application/commitment_repository.dart';
import 'package:planact/features/finance/application/finance_use_cases.dart';
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/features/finance/domain/finance.dart';
import 'package:planact/features/notes/application/calendar_note_repository.dart';
import 'package:planact/features/search/domain/search.dart';

abstract interface class SearchReader {
  Future<List<SearchDocument>> read();
}

/// Repository fallback for isolated previews/tests. Production wraps this read
/// in one gated database transaction and supplies batched tag memberships.
final class RepositorySearchReader implements SearchReader {
  const RepositorySearchReader({
    required this.commitments,
    required this.finance,
    required this.notes,
    required this.tags,
    this.entryLabels,
  });
  final CommitmentRepository commitments;
  final FinanceRepository finance;
  final CalendarNoteRepository notes;
  final TagRepository tags;
  final Map<String, List<String>>? entryLabels;

  @override
  Future<List<SearchDocument>> read() async {
    final owners = await commitments.list();
    final accounts = await finance.listAccounts();
    final entries = await finance.listEntries();
    final calendarNotes = await notes.list();
    final labels = entryLabels ?? <String, List<String>>{};
    if (entryLabels == null) {
      for (final tag in await tags.list()) {
        for (final id in await tags.recordsWithTag(
          tag.id,
          TaggableType.accountEntry,
        )) {
          (labels[id] ??= []).add(tag.label);
        }
      }
    }
    final byId = {for (final account in accounts) account.id: account};
    final entriesByAccount = <StableId, List<AccountEntry>>{};
    for (final entry in entries) {
      (entriesByAccount[entry.accountId] ??= []).add(entry);
    }
    return [
      for (final owner in owners)
        SearchDocument(
          target: CommitmentSearchTarget(owner),
          title: owner.title,
          description: owner.description ?? '',
          keywords: owner.tags,
          sortDate: owner.createdAt,
        ),
      for (final note in calendarNotes)
        SearchDocument(
          target: NoteSearchTarget(note),
          title: note.title,
          description: note.description,
          keywords: const [],
          sortDate: note.date.toUtcDateForCalculation(),
        ),
      for (final account in accounts)
        SearchDocument(
          target: AccountSearchTarget(
            account,
            entriesByAccount[account.id] ?? const [],
          ),
          title: account.name,
          description: account.bank?.label ?? '',
          keywords: [account.currency],
          sortDate: DateTime(1),
        ),
      for (final entry in entries)
        if (byId[entry.accountId] case final account?)
          SearchDocument(
            target: TransactionSearchTarget(entry, account),
            title: entry.note?.trim().isNotEmpty == true
                ? entry.note!
                : account.name,
            description: entry.category ?? '',
            keywords: [
              account.name,
              account.bank?.label ?? '',
              entry.referenceId ?? '',
              ...?labels[entry.id.value],
            ],
            sortDate: entry.occurredAt,
          ),
    ];
  }
}
