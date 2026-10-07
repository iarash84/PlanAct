import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planact/app/theme/planact_theme.dart';
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/core/money/money.dart';
import 'package:planact/features/classification/application/tag_repository.dart';
import 'package:planact/features/classification/domain/tag.dart';
import 'package:planact/features/classification/presentation/tag_controls.dart';
import 'package:planact/features/finance/application/finance_use_cases.dart';
import 'package:planact/features/finance/domain/finance.dart';
import 'package:planact/features/finance/presentation/finance_page.dart';

Widget host(Widget child, {bool dark = false}) => MaterialApp(
  theme: dark ? PlanActTheme.dark() : PlanActTheme.light(),
  builder: (context, child) =>
      Directionality(textDirection: TextDirection.rtl, child: child!),
  home: Scaffold(body: SingleChildScrollView(child: child)),
);

class ControlledTags extends InMemoryTagRepository {
  bool failAttach = false;
  bool failList = false;
  Completer<void>? pending;

  @override
  Future<List<Tag>> list() async {
    if (failList) throw StateError('Unavailable');
    return super.list();
  }

  @override
  Future<void> attach({
    required String recordId,
    required Tag tag,
    required TaggableType type,
  }) async {
    await pending?.future;
    if (failAttach) throw StateError('Unavailable');
    await super.attach(recordId: recordId, tag: tag, type: type);
  }
}

void main() {
  testWidgets('assign and detach affect only this record, not global tag', (
    tester,
  ) async {
    final repository = InMemoryTagRepository();
    final tag = await repository.getOrCreate('آموزش');
    var changes = 0;
    await repository.attach(
      recordId: 'other',
      tag: tag,
      type: TaggableType.commitment,
    );
    await tester.pumpWidget(
      host(
        RecordTagEditor(
          repository: repository,
          recordId: 'one',
          type: TaggableType.commitment,
          onChanged: () async {
            changes++;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('#آموزش'));
    await tester.pumpAndSettle();
    expect(await repository.tagsFor('one', TaggableType.commitment), {tag.id});
    expect(tester.widget<FilterChip>(find.byType(FilterChip)).selected, isTrue);
    await tester.tap(find.text('#آموزش'));
    await tester.pumpAndSettle();
    expect(await repository.tagsFor('one', TaggableType.commitment), isEmpty);
    expect(await repository.tagsFor('other', TaggableType.commitment), {
      tag.id,
    });
    expect(await repository.list(), hasLength(1));
    expect(changes, 2);
  });

  testWidgets(
    'global deletion requires explicit confirmation and preserves records',
    (tester) async {
      final repository = InMemoryTagRepository();
      final tag = await repository.getOrCreate('خانه');
      await repository.attach(
        recordId: 'commitment',
        tag: tag,
        type: TaggableType.commitment,
      );
      await repository.attach(
        recordId: 'entry',
        tag: tag,
        type: TaggableType.accountEntry,
      );
      await tester.pumpWidget(
        host(
          Builder(
            builder: (context) => TextButton(
              onPressed: () => showTagManager(
                context,
                repository: repository,
                onChanged: () async {},
              ),
              child: const Text('باز کردن'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('باز کردن'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('حذف سراسری #خانه'));
      await tester.pumpAndSettle();
      expect(await repository.list(), hasLength(1));
      await tester.tap(find.text('انصراف'));
      await tester.pumpAndSettle();
      expect(await repository.list(), hasLength(1));
      await tester.tap(find.byTooltip('حذف سراسری #خانه'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('حذف از همهٔ موارد'));
      await tester.pumpAndSettle();
      expect(await repository.list(), isEmpty);
      expect(
        await repository.tagsFor('commitment', TaggableType.commitment),
        isEmpty,
      );
      expect(
        await repository.tagsFor('entry', TaggableType.accountEntry),
        isEmpty,
      );
    },
  );

  testWidgets(
    'rename preserves membership and updates the editor after management',
    (tester) async {
      final repository = InMemoryTagRepository();
      final tag = await repository.getOrCreate('قدیمی');
      await repository.attach(
        recordId: 'one',
        tag: tag,
        type: TaggableType.commitment,
      );
      await tester.pumpWidget(
        host(
          RecordTagEditor(
            repository: repository,
            recordId: 'one',
            type: TaggableType.commitment,
            onChanged: () async {},
          ),
          dark: true,
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('مدیریت برچسب‌ها'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('تغییر نام #قدیمی'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, 'نام برچسب'),
        'جدید',
      );
      await tester.tap(find.text('ذخیره'));
      await tester.pumpAndSettle();
      expect((await repository.list()).single.label, 'جدید');
      expect(await repository.tagsFor('one', TaggableType.commitment), {
        tag.id,
      });
      Navigator.of(tester.element(find.text('مدیریت برچسب‌ها').last)).pop();
      await tester.pumpAndSettle();
      expect(find.text('#جدید'), findsOneWidget);
      expect(
        tester.widget<FilterChip>(find.byType(FilterChip)).selected,
        isTrue,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'pending assignment disables duplicate actions; failure is recoverable',
    (tester) async {
      final repository = ControlledTags();
      final tag = await repository.getOrCreate('کار');
      repository.pending = Completer<void>();
      repository.failAttach = true;
      await tester.pumpWidget(
        host(
          RecordTagEditor(
            repository: repository,
            recordId: 'one',
            type: TaggableType.accountEntry,
            onChanged: () async {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('#کار'));
      await tester.pump();
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(
        tester.widget<FilterChip>(find.byType(FilterChip)).onSelected,
        isNull,
      );
      repository.pending!.complete();
      await tester.pumpAndSettle();
      expect(find.textContaining('تغییر برچسب انجام نشد'), findsOneWidget);
      expect(
        await repository.tagsFor('one', TaggableType.accountEntry),
        isEmpty,
      );
      repository.failAttach = false;
      await tester.tap(find.text('#کار'));
      await tester.pumpAndSettle();
      expect(await repository.tagsFor('one', TaggableType.accountEntry), {
        tag.id,
      });
    },
  );

  testWidgets('load failure is distinct from empty and can retry', (
    tester,
  ) async {
    final repository = ControlledTags()..failList = true;
    await tester.pumpWidget(
      host(
        RecordTagEditor(
          repository: repository,
          recordId: 'one',
          type: TaggableType.commitment,
          onChanged: () async {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('خواندن برچسب‌ها انجام نشد'), findsOneWidget);
    repository.failList = false;
    await repository.getOrCreate('کار');
    await tester.tap(find.text('تلاش دوباره'));
    await tester.pumpAndSettle();
    expect(find.text('#کار'), findsOneWidget);
  });

  testWidgets(
    'finance filter uses persisted account entry memberships and clears',
    (tester) async {
      final finance = InMemoryFinanceRepository();
      final tags = InMemoryTagRepository();
      final account = FinancialAccount(
        id: StableId.generate(),
        name: 'نقدی',
        currency: 'IRR',
        type: FinancialAccountType.cash,
      );
      await finance.saveAccount(account);
      final useCases = FinanceUseCases(finance);
      final tagged = await useCases.record(
        account: account,
        type: AccountEntryType.expense,
        amount: const Money(minorUnits: 100, currency: 'IRR'),
        occurredAt: DateTime(2026, 10, 6),
        note: 'تراکنش برچسب‌دار',
      );
      await useCases.record(
        account: account,
        type: AccountEntryType.expense,
        amount: const Money(minorUnits: 200, currency: 'IRR'),
        occurredAt: DateTime(2026, 10, 6),
        note: 'تراکنش دیگر',
      );
      final tag = await tags.getOrCreate('خانه');
      await tags.attach(
        recordId: tagged.id.value,
        tag: tag,
        type: TaggableType.accountEntry,
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: PlanActTheme.light(),
          builder: (context, child) =>
              Directionality(textDirection: TextDirection.rtl, child: child!),
          home: FinancePage(repository: finance, tagRepository: tags),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilterChip, '#خانه'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.textContaining('تراکنش برچسب‌دار'),
        200,
      );
      expect(find.textContaining('تراکنش دیگر'), findsNothing);
      expect(find.byType(TagLabels), findsOneWidget);
      await tester.scrollUntilVisible(find.text('همهٔ برچسب‌ها'), -200);
      await tester.tap(find.text('همهٔ برچسب‌ها'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.textContaining('تراکنش دیگر'), 200);
      expect(find.textContaining('تراکنش دیگر'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
