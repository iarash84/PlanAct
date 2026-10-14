import 'package:planact/core/application/command_gate.dart';
import 'package:planact/core/database/app_database.dart';
import 'package:planact/features/classification/data/drift_tag_repository.dart';
import 'package:planact/features/commitments/data/drift_commitment_repository.dart';
import 'package:planact/features/finance/data/drift_finance_repository.dart';
import 'package:planact/features/notes/data/drift_calendar_note_repository.dart';
import 'package:planact/features/search/application/search_reader.dart';
import 'package:planact/features/search/domain/search.dart';

final class DriftSearchReader implements SearchReader, CommandGateProvider {
  const DriftSearchReader(this.database);
  final AppDatabase database;
  @override
  CommandGate? get commandGate => CommandGate.forOwner(database);

  @override
  Future<List<SearchDocument>> read() => CommandGate.runFor(
    this,
    () => database.transaction(() async {
      final tags = await database.select(database.tags).get();
      final names = {for (final tag in tags) tag.id: tag.label};
      final links = await database.select(database.accountEntryTags).get();
      final labels = <String, List<String>>{};
      for (final link in links) {
        if (names[link.tagId] case final name?) {
          (labels[link.accountEntryId] ??= []).add(name);
        }
      }
      return RepositorySearchReader(
        commitments: DriftCommitmentRepository(database),
        finance: DriftFinanceRepository(database),
        notes: DriftCalendarNoteRepository(database),
        tags: DriftTagRepository(database),
        entryLabels: labels,
      ).read();
    }),
  );
}
