import 'package:planact/core/application/command_gate.dart';
import 'package:planact/core/database/app_database.dart' show AppDatabase;
import 'package:planact/features/calendar/application/calendar_transaction_reader.dart';
import 'package:planact/features/calendar/domain/calendar_transaction.dart';
import 'package:planact/features/calendar/domain/calendar_visibility.dart';
import 'package:planact/features/classification/application/tag_repository.dart';
import 'package:planact/features/classification/data/drift_tag_repository.dart';
import 'package:planact/features/finance/data/drift_finance_repository.dart';
import 'package:planact/features/finance/domain/finance.dart';
import 'package:planact/features/scheduling/domain/schedule_definition.dart';

final class DriftCalendarTransactionReader
    implements CalendarTransactionReader, CommandGateProvider {
  const DriftCalendarTransactionReader(this.database);
  final AppDatabase database;
  @override
  CommandGate? get commandGate => CommandGate.forOwner(database);
  @override
  Future<List<CalendarTransaction>> loadRange(
    LocalDate start,
    LocalDate endExclusive,
    CalendarVisibility visibility,
  ) {
    if (!visibility.hasFinancialItems) return Future.value(const []);
    return CommandGate.runFor(
      this,
      () => database.transaction(() async {
        final finance = DriftFinanceRepository(database);
        final entries = await finance.listEntries();
        final projected = projectCalendarTransactions(
          entries,
          visibility,
          start,
          endExclusive,
        );
        if (projected.isEmpty) return projected;
        final accounts = {
          for (final account in await finance.listAccounts())
            account.id: account,
        };
        final tagRepository = DriftTagRepository(database);
        final tags = await tagRepository.list();
        final groups = <String, List<AccountEntry>>{};
        for (final entry in entries) {
          if (entry.transferGroupId != null &&
              (entry.type == AccountEntryType.transferIn ||
                  entry.type == AccountEntryType.transferOut)) {
            groups
                .putIfAbsent(entry.transferGroupId!.value, () => [])
                .add(entry);
          }
        }
        final related = {
          for (final item in projected)
            item.entry.id:
                item.kind == CalendarTransactionKind.transfer &&
                    item.entry.transferGroupId != null
                ? [
                    item.entry,
                    ...groups[item.entry.transferGroupId!.value]!.where(
                      (leg) => leg.id != item.entry.id,
                    ),
                  ]
                : [item.entry],
        };
        final memberships = await tagRepository.tagsForMany(
          related.values.expand((legs) => legs.map((leg) => leg.id.value)),
          TaggableType.accountEntry,
        );
        return [
          for (final item in projected)
            CalendarTransaction(
              entry: item.entry,
              kind: item.kind,
              reversed: item.reversed,
              accounts: List.unmodifiable({
                for (final leg in related[item.entry.id]!)
                  ?accounts[leg.accountId],
              }),
              tags: List.unmodifiable(
                tags.where(
                  (tag) => related[item.entry.id]!.any(
                    (leg) =>
                        memberships[leg.id.value]?.contains(tag.id) ?? false,
                  ),
                ),
              ),
            ),
        ];
      }),
    );
  }
}
