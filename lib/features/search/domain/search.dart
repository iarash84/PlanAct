import 'package:planact/features/commitments/domain/commitment.dart';
import 'package:planact/features/finance/domain/finance.dart';
import 'package:planact/features/notes/domain/calendar_note.dart';

enum SearchKind { commitment, transaction, note, account }

sealed class SearchTarget {
  const SearchTarget();
  SearchKind get kind;
  String get id;
}

final class CommitmentSearchTarget extends SearchTarget {
  const CommitmentSearchTarget(this.value);
  final Commitment value;
  @override
  SearchKind get kind => SearchKind.commitment;
  @override
  String get id => value.id.value;
}

final class TransactionSearchTarget extends SearchTarget {
  const TransactionSearchTarget(this.value, this.account);
  final AccountEntry value;
  final FinancialAccount account;
  @override
  SearchKind get kind => SearchKind.transaction;
  @override
  String get id => value.id.value;
}

final class NoteSearchTarget extends SearchTarget {
  const NoteSearchTarget(this.value);
  final CalendarNote value;
  @override
  SearchKind get kind => SearchKind.note;
  @override
  String get id => value.id.value;
}

final class AccountSearchTarget extends SearchTarget {
  AccountSearchTarget(this.value, List<AccountEntry> entries)
    : entries = List.unmodifiable(entries);
  final FinancialAccount value;
  final List<AccountEntry> entries;
  @override
  SearchKind get kind => SearchKind.account;
  @override
  String get id => value.id.value;
}

/// A disposable projection. Source text and stored domain values stay intact.
final class SearchDocument {
  SearchDocument({
    required this.target,
    required this.title,
    required this.description,
    required Iterable<String> keywords,
    required this.sortDate,
  }) : normalizedTitle = normalizeSearchText(title).replaceAll(' ', ''),
       normalizedText = [title, description, ...keywords]
           .map((field) => normalizeSearchText(field).replaceAll(' ', ''))
           .join('\n');

  final SearchTarget target;
  final String title;
  final String description;
  final DateTime sortDate;
  final String normalizedTitle;
  final String normalizedText;
}

String normalizeSearchText(String value) {
  final buffer = StringBuffer();
  for (var rune in value.toLowerCase().runes) {
    if ((rune >= 0x064b && rune <= 0x065f) ||
        rune == 0x0670 ||
        rune == 0x0640 ||
        rune == 0x200c ||
        rune == 0x200d) {
      continue;
    }
    if (rune == 0x064a || rune == 0x0649) rune = 0x06cc;
    if (rune == 0x0643) rune = 0x06a9;
    if (rune >= 0x06f0 && rune <= 0x06f9) rune -= 0x06f0 - 0x30;
    if (rune >= 0x0660 && rune <= 0x0669) rune -= 0x0660 - 0x30;
    buffer.writeCharCode(rune);
  }
  return buffer.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
}

List<SearchDocument> searchDocuments(
  Iterable<SearchDocument> documents,
  String query, {
  SearchKind? kind,
}) {
  final normalized = normalizeSearchText(query);
  if (normalized.isEmpty) return const [];
  final tokens = normalized.split(' ');
  final results = documents
      .where(
        (doc) =>
            (kind == null || doc.target.kind == kind) &&
            tokens.every((token) => doc.normalizedText.contains(token)),
      )
      .toList();
  final phrase = normalized.replaceAll(' ', '');
  int rank(SearchDocument doc) => doc.normalizedTitle == phrase
      ? 0
      : doc.normalizedTitle.startsWith(phrase)
      ? 1
      : 2;
  results.sort((a, b) {
    final ranked = rank(a).compareTo(rank(b));
    if (ranked != 0) return ranked;
    final date = b.sortDate.compareTo(a.sortDate);
    if (date != 0) return date;
    final type = a.target.kind.index.compareTo(b.target.kind.index);
    return type != 0 ? type : a.target.id.compareTo(b.target.id);
  });
  return results;
}
