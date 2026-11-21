import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planact/core/database/app_database.dart' show AppDatabase;
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/core/money/money.dart';
import 'package:planact/features/backup/data/sqlite_backup_snapshot.dart';
import 'package:planact/features/classification/application/tag_repository.dart';
import 'package:planact/features/classification/data/drift_tag_repository.dart';
import 'package:planact/features/finance/application/finance_use_cases.dart';
import 'package:planact/features/finance/data/drift_finance_repository.dart';
import 'package:planact/features/finance/domain/finance.dart';
import 'package:planact/features/finance/domain/transaction_history.dart';

void main() {
  test(
    'durable correction chain and cancellation preserve money and notes',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'correction-role-',
      );
      final file = File('${directory.path}/state.sqlite');
      var database = AppDatabase.forTesting(NativeDatabase(file));
      var repository = DriftFinanceRepository(database);
      var commands = FinanceUseCases(repository);
      try {
        final account = FinancialAccount(
          id: StableId.generate(),
          name: 'حساب',
          currency: 'IRR',
          type: FinancialAccountType.bank,
        );
        final other = FinancialAccount(
          id: StableId.generate(),
          name: 'دوم',
          currency: 'IRR',
          type: FinancialAccountType.bank,
        );
        await commands.createAccount(account);
        await commands.createAccount(other);
        final original = await commands.record(
          account: account,
          type: AccountEntryType.expense,
          amount: const Money(minorUnits: 100, currency: 'IRR'),
          occurredAt: DateTime.utc(2026, 11),
          note: 'یادداشت اصلی',
          category: 'دسته اصلی',
          tags: {'برچسب اصلی', 'مشترک'},
        );
        final replacement = await commands.correctEntry(
          original: original,
          account: other,
          type: AccountEntryType.expense,
          amount: const Money(minorUnits: 200, currency: 'IRR'),
          occurredAt: original.occurredAt,
          note: 'یادداشت کاربر',
        );
        final tagRepository = DriftTagRepository(database);
        final replacementTag = await tagRepository.getOrCreate('برچسب جایگزین');
        await tagRepository.attach(
          recordId: replacement.id.value,
          tag: replacementTag,
          type: TaggableType.accountEntry,
        );
        final finalEntry = await commands.correctEntry(
          original: replacement,
          account: other,
          type: AccountEntryType.income,
          amount: const Money(minorUnits: 300, currency: 'IRR'),
          occurredAt: original.occurredAt,
          note: 'نهایی',
        );
        await commands.voidEntry(original: finalEntry, account: other);
        Future<void> verify() async {
          final entries = await repository.listEntries();
          expect(entries, hasLength(6));
          final first = entries.singleWhere((e) => e.id == original.id);
          final middle = entries.singleWhere((e) => e.id == replacement.id);
          final last = entries.singleWhere((e) => e.id == finalEntry.id);
          expect(first.history!.role.corrected, isTrue);
          expect(first.note, 'یادداشت اصلی');
          expect(first.category, 'دسته اصلی');
          expect(first.source, original.source);
          expect(first.accountId, original.accountId);
          expect(first.amount, original.amount);
          expect(first.referenceId, original.referenceId);
          expect(first.noteRevision, original.noteRevision);
          final tags = DriftTagRepository(database);
          final labels = {
            for (final tag in await tags.list()) tag.id: tag.label,
          };
          Future<Set<String>> directTags(AccountEntry entry) async => {
            for (final id in await tags.tagsFor(
              entry.id.value,
              TaggableType.accountEntry,
            ))
              labels[id]!,
          };
          expect(await directTags(first), {'برچسب اصلی', 'مشترک'});
          expect(await directTags(middle), {'برچسب جایگزین'});
          expect(await directTags(last), isEmpty);
          final originalItem = last.history!.chain.singleWhere(
            (item) => item.entry.id == original.id,
          );
          expect(originalItem.tags, unorderedEquals(['برچسب اصلی', 'مشترک']));
          expect(originalItem.entry.note, 'یادداشت اصلی');
          expect(originalItem.entry.category, 'دسته اصلی');
          expect(
            last.history!.chain
                .singleWhere((item) => item.entry.id == replacement.id)
                .tags,
            ['برچسب جایگزین'],
          );
          expect(middle.history!.role.replacement, isTrue);
          expect(middle.history!.role.corrected, isTrue);
          expect(middle.history!.role.reversed, isTrue);
          expect(middle.note, 'یادداشت کاربر');
          expect(last.history!.role.replacement, isTrue);
          expect(last.history!.role.corrected, isFalse);
          expect(last.history!.role.reversed, isTrue);
          expect(last.history!.chain, hasLength(6));
          expect(
            entries.where(
              (e) =>
                  e.history!.role.reversalPurpose == ReversalPurpose.correction,
            ),
            hasLength(2),
          );
          expect(
            entries.where(
              (e) =>
                  e.history!.role.reversalPurpose ==
                  ReversalPurpose.cancellation,
            ),
            hasLength(1),
          );
          expect((await commands.balance(account)).minorUnits, 0);
          expect((await commands.balance(other)).minorUnits, 0);
        }

        await verify();
        await database.close();
        database = AppDatabase.forTesting(NativeDatabase(file));
        repository = DriftFinanceRepository(database);
        commands = FinanceUseCases(repository);
        await verify();
        final bytes = await sqliteBackupSnapshot(
          database: database,
          target: File('${directory.path}/snapshot.sqlite'),
          redact: true,
        );
        await database.close();
        await file.writeAsBytes(bytes, flush: true);
        database = AppDatabase.forTesting(NativeDatabase(file));
        repository = DriftFinanceRepository(database);
        commands = FinanceUseCases(repository);
        await verify();
      } finally {
        await database.close();
        await directory.delete(recursive: true);
      }
    },
  );
}
