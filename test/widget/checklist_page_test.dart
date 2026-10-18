import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planact/app/theme/planact_theme.dart';
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/core/localization/planact_localizations.dart';
import 'package:planact/features/commitments/application/checklist_repository.dart';
import 'package:planact/features/commitments/application/commitment_repository.dart';
import 'package:planact/features/commitments/domain/commitment.dart';
import 'package:planact/features/commitments/domain/commitment_checklist.dart';
import 'package:planact/features/commitments/presentation/checklist_page.dart';

final class ControlledChecklist implements ChecklistRepository {
  ControlledChecklist(this.inner);
  final ChecklistRepository inner;
  bool failRead = false;
  bool failSave = false;
  bool failReadAfterCommit = false;
  @override
  Future<ChecklistSnapshot> load(StableId commitmentId) async {
    if (failRead) throw StateError('read failure');
    return inner.load(commitmentId);
  }

  @override
  Future<void> save(
    CommitmentChecklist next, {
    required int expectedRevision,
  }) async {
    if (failSave) throw const ChecklistConflict();
    await inner.save(next, expectedRevision: expectedRevision);
    if (failReadAfterCommit) failRead = true;
  }
}

Widget app(
  ChecklistRepository repo,
  Commitment owner, {
  Brightness brightness = Brightness.light,
  double scale = 1,
}) => MaterialApp(
  locale: const Locale('fa'),
  supportedLocales: AppLocalizations.supportedLocales,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  theme: brightness == Brightness.light
      ? PlanActTheme.light()
      : PlanActTheme.dark(),
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
    child: child!,
  ),
  home: ChecklistPage(
    repository: repo,
    commitmentId: owner.id,
    title: owner.title,
  ),
);

void main() {
  testWidgets(
    'read retry, stale save retains draft, cancellation writes nothing, committed read failure is distinct',
    (tester) async {
      final owner = Commitment.create(title: 'خرید');
      final owners = InMemoryCommitmentRepository();
      await owners.save(owner);
      final inner = InMemoryChecklistRepository(owners);
      final repo = ControlledChecklist(inner)..failRead = true;
      await tester.pumpWidget(app(repo, owner));
      await tester.pumpAndSettle();
      expect(find.textContaining('فهرست به‌روز نشد'), findsOneWidget);
      repo.failRead = false;
      await tester.tap(find.text('تلاش دوباره'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('checklist-add')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('checklist-item-title')),
        'نان',
      );
      // Another user action wins while the item dialog is open.
      final initial = (await inner.load(owner.id)).list;
      await inner.save(initial.add('شیر'), expectedRevision: 0);
      await tester.tap(find.byKey(const ValueKey('checklist-item-save')));
      await tester.pumpAndSettle();
      expect(find.textContaining('تغییر ذخیره نشد'), findsWidgets);
      expect(
        tester
            .widget<TextField>(
              find.byKey(const ValueKey('checklist-item-title')),
            )
            .controller!
            .text,
        'نان',
      );
      expect((await inner.load(owner.id)).list.items.single.title, 'شیر');
      await tester.tap(find.text('انصراف'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('تلاش دوباره'));
      await tester.pumpAndSettle();
      expect(find.text('شیر'), findsOneWidget);
      repo.failReadAfterCommit = true;
      await tester.tap(find.byKey(const ValueKey('checklist-add')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('checklist-item-title')),
        'نان',
      );
      await tester.tap(find.byKey(const ValueKey('checklist-item-save')));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.textContaining('فهرست به‌روز نشد'), findsOneWidget);
      expect(find.textContaining('تغییر ذخیره نشد'), findsNothing);
      expect((await inner.load(owner.id)).list.items, hasLength(2));
      repo.failRead = false;
      repo.failReadAfterCommit = false;
      await tester.tap(find.text('تلاش دوباره'));
      await tester.pumpAndSettle();
      expect(find.text('نان'), findsOneWidget);
      expect((await inner.load(owner.id)).list.revision, 2);
    },
  );

  for (final brightness in Brightness.values) {
    testWidgets(
      'narrow RTL 2× text tasks, edit dialog and archived read-only in $brightness',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(320, 640));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final owner = Commitment.create(title: 'لیست خرید هفته برای خانه');
        final owners = InMemoryCommitmentRepository();
        await owners.save(owner);
        final repo = InMemoryChecklistRepository(owners);
        final first = (await repo.load(owner.id)).list
            .add('خرید نان و شیر و میوه برای خانواده');
        final semantics = tester.ensureSemantics();
        await repo.save(first, expectedRevision: 0);
        await tester.pumpWidget(
          app(repo, owner, brightness: brightness, scale: 2),
        );
        await tester.pumpAndSettle();
        expect(
          Directionality.of(tester.element(find.byType(ChecklistPage))),
          TextDirection.rtl,
        );
        expect(tester.takeException(), isNull);
        await tester.scrollUntilVisible(find.byType(CheckboxListTile), 180);
        final itemNode = tester.getSemantics(find.byType(CheckboxListTile));
        final menuNode = tester.getSemantics(
          find.byTooltip('اقدام‌های این کار'),
        );
        expect(itemNode.id, isNot(menuNode.id));
        expect(itemNode.label, contains(first.items.single.title));
        expect(menuNode.tooltip, contains('اقدام‌های این کار'));
        semantics.dispose();
        await tester.scrollUntilVisible(
          find.byKey(const ValueKey('checklist-add')),
          180,
        );
        await tester.tap(find.byKey(const ValueKey('checklist-add')));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(const ValueKey('checklist-item-title')),
          'نان',
        );
        expect(tester.takeException(), isNull);
        await tester.tap(find.text('انصراف'));
        await tester.pumpAndSettle();
        expect((await repo.load(owner.id)).list.revision, 1);
        await owners.save(owner.archive());
        await tester.pumpWidget(const SizedBox());
        await tester.pumpWidget(
          app(repo, owner, brightness: brightness, scale: 2),
        );
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(find.byType(CheckboxListTile), 180);
        expect(
          tester
              .widget<CheckboxListTile>(find.byType(CheckboxListTile))
              .onChanged,
          isNull,
        );
        await tester.scrollUntilVisible(
          find.byKey(const ValueKey('checklist-add')),
          180,
        );
        expect(
          tester
              .widget<FilledButton>(find.byKey(const ValueKey('checklist-add')))
              .onPressed,
          isNull,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }
}
