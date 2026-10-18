import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planact/core/database/app_database.dart' show AppDatabase;
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/core/money/money.dart';
import 'package:planact/features/classification/application/tag_repository.dart';
import 'package:planact/features/classification/data/drift_tag_repository.dart';
import 'package:planact/features/commitments/data/drift_commitment_repository.dart';
import 'package:planact/features/commitments/domain/commitment.dart';
import 'package:planact/features/finance/data/drift_finance_repository.dart';
import 'package:planact/features/finance/domain/finance.dart';
import 'package:planact/features/notes/data/drift_calendar_note_repository.dart';
import 'package:planact/features/notes/domain/calendar_note.dart';
import 'package:planact/features/scheduling/domain/schedule_definition.dart';
import 'package:planact/features/search/data/drift_search_reader.dart';
import 'package:planact/features/search/domain/search.dart';

void main() {
  test('production search reads current durable records, all history/types and tags without writes after cold reopen', () async {
    final directory = await Directory.systemTemp.createTemp('search-test-');
    final file = File('${directory.path}/search.sqlite');
    var database = AppDatabase.forTesting(NativeDatabase(file));
    try {
      final commitments = DriftCommitmentRepository(database);
      await commitments.save(
        Commitment.create(
          title: 'كلاس موسيقي',
          description: 'پاییز',
          tags: {'آموزش'},
        ).archive(),
      );
      final finance = DriftFinanceRepository(database);
      final account = FinancialAccount(
        id: StableId.generate(),
        name: 'کیف موسیقی',
        currency: 'IRR',
        type: FinancialAccountType.cash,
      );
      await finance.saveAccount(account);
      final tags = DriftTagRepository(database);
      final tag = await tags.getOrCreate('شهریه');
      for (final type in AccountEntryType.values) {
        final entry = AccountEntry(
          id: StableId.generate(),
          accountId: account.id,
          type: type,
          amount: Money(
            minorUnits: type == AccountEntryType.reversal ? -1234567 : 1234567,
            currency: 'IRR',
          ),
          occurredAt: DateTime.utc(2026, 10, 14),
          note: 'واریزی موسیقی',
          category: 'تحصیل',
        );
        await finance.saveEntry(entry);
        await tags.attach(
          recordId: entry.id.value,
          tag: tag,
          type: TaggableType.accountEntry,
        );
      }
      await finance.setAccountStatus(
        account.id,
        FinancialAccountStatus.archived,
      );
      final notes = DriftCalendarNoteRepository(database);
      final noteId = StableId.generate();
      await notes.save(
        CalendarNote(
          id: noteId,
          title: 'قدیمی حذف از جستجو',
          description: 'متن قبلی',
          date: LocalDate(1900, 1, 1),
          color: CommitmentColor.rose,
          revision: 1,
        ),
        expectedRevision: 0,
      );
      await notes.save(
        CalendarNote(
          id: noteId,
          title: 'یادداشت موسیقی ۱۲۳',
          description: 'متن جدید',
          date: LocalDate(2100, 1, 1),
          color: CommitmentColor.blue,
          revision: 2,
        ),
        expectedRevision: 1,
      );
      await database.close();
      database = AppDatabase.forTesting(NativeDatabase(file));
      final before = await database
          .customSelect('SELECT * FROM schema_metadata ORDER BY key')
          .get();
      final entriesBefore = await DriftFinanceRepository(database)
          .listEntries();
      final reader = DriftSearchReader(database);
      final documents = await reader.read();
      expect(documents, hasLength(11));
      expect(searchDocuments(documents, 'موسیقی'), hasLength(11));
      expect(
        searchDocuments(documents, 'آموزش').single.target,
        isA<CommitmentSearchTarget>(),
      );
      expect(searchDocuments(documents, 'شهریه تحصیل'), hasLength(8));
      expect(
        searchDocuments(documents, 'متن جدید 123').single.target,
        isA<NoteSearchTarget>(),
      );
      expect(searchDocuments(documents, 'متن قبلی'), isEmpty);
      expect(searchDocuments(documents, 'حذف'), isEmpty);
      final commitment =
          documents
                  .firstWhere((doc) => doc.target.kind == SearchKind.commitment)
                  .target
              as CommitmentSearchTarget;
      expect(commitment.value.status, CommitmentStatus.archived);
      final accountResult =
          documents
                  .firstWhere((doc) => doc.target.kind == SearchKind.account)
                  .target
              as AccountSearchTarget;
      expect(accountResult.value.status, FinancialAccountStatus.archived);
      expect(accountResult.entries, hasLength(8));
      final after = await database
          .customSelect('SELECT * FROM schema_metadata ORDER BY key')
          .get();
      expect(
        after.map((row) => row.data).toList(),
        before.map((row) => row.data).toList(),
      );
      final entriesAfter = await DriftFinanceRepository(database).listEntries();
      expect(
        entriesAfter.map((entry) => entry.signedAmount.minorUnits),
        entriesBefore.map((entry) => entry.signedAmount.minorUnits),
      );
      expect(await database.select(database.occurrences).get(), isEmpty);
      expect(await database.select(database.reminderRules).get(), isEmpty);
      expect(
        await database.select(database.entitlementLedgerEntries).get(),
        isEmpty,
      );
    } finally {
      await database.close();
      await directory.delete(recursive: true);
    }
  });
}
