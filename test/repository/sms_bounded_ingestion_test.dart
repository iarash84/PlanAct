import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planact/core/database/app_database.dart';
import 'package:planact/features/finance/data/drift_finance_repository.dart';
import 'package:planact/features/inbox/application/android_sms_source.dart';
import 'package:planact/features/inbox/application/inbox_use_cases.dart';
import 'package:planact/features/inbox/application/sms_ingestion.dart';
import 'package:planact/features/inbox/data/drift_inbox_repository.dart';
import 'package:planact/features/inbox/domain/inbox.dart';
import 'package:planact/features/inbox/presentation/inbox_page.dart';

class PagedSource extends AndroidSmsSource {
  PagedSource(this.rows);
  final List<SmsProviderRow> rows;
  int reads = 0;
  bool fail = false;
  bool access = true;
  @override
  Future<bool> hasAccess() async => access;
  @override
  Stream<AndroidSmsMessage> get messages => const Stream.empty();
  @override
  Future<SmsProviderPage> readPage({
    required int from,
    required int until,
    required int afterTimestamp,
    required int afterId,
  }) async {
    reads++;
    if (fail) throw StateError('Injected source failure');
    return SmsProviderPage(
      rows
          .where(
            (r) =>
                r.timestamp >= from &&
                r.timestamp <= until &&
                (r.timestamp > afterTimestamp ||
                    (r.timestamp == afterTimestamp && r.id > afterId)),
          )
          .take(100)
          .toList(),
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('source channel carries explicit bounds and stable cursor; malformed page fails', () async {
    const channel = MethodChannel('test/bounded-sms');
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(channel, (call) async {
      expect(call.method, 'readPage');
      expect(call.arguments, {
        'from': 100,
        'until': 500,
        'afterTimestamp': 200,
        'afterId': 9,
        'limit': 100,
      });
      return [
        {'id': 10, 'receivedAt': 200},
      ];
    });
    addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
    final source = AndroidSmsSource(channel: channel);
    final page = await source.readPage(
      from: 100,
      until: 500,
      afterTimestamp: 200,
      afterId: 9,
    );
    expect(page.rows.single.id, 10);
    expect(page.rows.single.message, isNull);
    messenger.setMockMethodCallHandler(
      channel,
      (_) async => [
        {'body': 'invalid'},
      ],
    );
    await expectLater(
      source.readPage(from: 100, until: 500, afterTimestamp: 200, afterId: 9),
      throwsA(isA<AndroidSmsParseError>()),
    );
  });

  test(
    '10,000 equal-time rows cancel, cold reopen, retry and preserve rejection',
    () async {
      final directory = await Directory.systemTemp.createTemp('sms-bounded-');
      addTearDown(() => directory.delete(recursive: true));
      final file = File('${directory.path}/state.sqlite');
      var database = AppDatabase.forTesting(NativeDatabase(file));
      var repository = DriftInboxRepository(database);
      var inbox = InboxUseCases(repository);
      final source = PagedSource(
        List.generate(
          10000,
          (i) => SmsProviderRow(
            1000,
            i,
            i % 100 == 0
                ? AndroidSmsMessage(
                    sourceKey: 'android-sms:$i',
                    body: 'برداشت مبلغ ${i + 1000}',
                    receivedAt: DateTime.fromMillisecondsSinceEpoch(
                      1000,
                      isUtc: true,
                    ),
                  )
                : null,
          ),
        ),
      );
      var command = SmsIngestion(inbox, source);
      await expectLater(
        command.run(onProgress: (_) {}),
        throwsA(isA<Exception>()),
      );
      expect(source.reads, 0);
      await command.consent(
        from: DateTime.fromMillisecondsSinceEpoch(500),
        until: DateTime.fromMillisecondsSinceEpoch(1500),
        newOnly: false,
      );
      await command.run(
        onProgress: (s) {
          if (s.inspected == 137) command.cancel();
        },
      );
      expect((await command.load())!.id, 136);
      final original = (await repository.listSuggestions()).first;
      await inbox.reject(original);
      await database.close();
      database = AppDatabase.forTesting(NativeDatabase(file));
      addTearDown(() => database.close());
      repository = DriftInboxRepository(database);
      inbox = InboxUseCases(repository);
      command = SmsIngestion(inbox, source);
      expect((await command.load())!.inspected, 137);
      source.fail = true;
      await expectLater(command.run(onProgress: (_) {}), throwsStateError);
      expect((await command.load())!.id, 136);
      source.fail = false;
      await command.run(onProgress: (_) {});
      final scan = (await command.load())!;
      expect(scan.complete, isTrue);
      expect(scan.inspected, 10000);
      expect(scan.id, 9999);
      expect(await repository.listSuggestions(), hasLength(100));
      expect(
        (await repository.listSuggestions())
            .firstWhere((s) => s.id == original.id)
            .status,
        SuggestionStatus.rejected,
      );
      expect(await DriftFinanceRepository(database).listEntries(), isEmpty);
      final reads = source.reads;
      await command.run(onProgress: (_) {});
      expect(source.reads, reads);
    },
  );

  test(
    'new-only excludes history and stale checkpoint writes are rejected',
    () async {
      final database = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(database.close);
      final repository = DriftInboxRepository(database);
      final source = PagedSource([
        const SmsProviderRow(999, 1, null),
        const SmsProviderRow(1000, 2, null),
      ]);
      final command = SmsIngestion(InboxUseCases(repository), source);
      final at = DateTime.fromMillisecondsSinceEpoch(1000);
      await command.consent(from: at, until: at, newOnly: true);
      final initial = await repository.readSmsScan();
      await command.run(onProgress: (_) {});
      expect((await command.load())!.inspected, 1);
      // A provider insertion behind the old cursor is recovered on an explicit
      // new-only refresh, without broadening consent into older history.
      source.rows.insert(1, const SmsProviderRow(1000, 0, null));
      await command.run(onProgress: (_) {});
      expect((await command.load())!.inspected, 2);
      await expectLater(
        repository.writeSmsScan(initial, initial!),
        throwsStateError,
      );
    },
  );

  testWidgets(
    'permission alone, refresh and range-dialog cancellation never read provider',
    (tester) async {
      final database = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(database.close);
      final source = PagedSource([]);
      await tester.pumpWidget(
        MaterialApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              body: InboxPage(
                inbox: InboxUseCases(DriftInboxRepository(database)),
                finance: DriftFinanceRepository(database),
                smsSource: source,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(source.reads, 0);
      await tester.tap(find.text('انتخاب بازهٔ پیامک'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('انصراف'));
      await tester.pumpAndSettle();
      expect(source.reads, 0);
      await tester.tap(find.text('انتخاب بازهٔ پیامک'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('۷ روز گذشته'));
      await tester.pumpAndSettle();
      expect(source.reads, 1);
      expect(find.text('بررسی بازه کامل شد.'), findsOneWidget);
    },
  );
}
