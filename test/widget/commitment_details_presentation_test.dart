import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planact/app/planact_app.dart';
import 'package:planact/app/theme/planact_spacing.dart';
import 'package:planact/app/theme/planact_theme.dart';
import 'package:planact/features/commitments/application/commitment_plan_use_case.dart';
import 'package:planact/features/commitments/application/commitment_repository.dart';
import 'package:planact/features/commitments/domain/commitment.dart';
import 'package:planact/features/finance/application/financial_expectation_use_cases.dart';
import 'package:planact/features/scheduling/application/occurrence_actions.dart';

class _ControlledRepository extends InMemoryCommitmentRepository {
  bool fail = false;
  Completer<void>? pending;
  int writes = 0;

  @override
  Future<void> save(Commitment commitment) async {
    writes++;
    if (fail) throw StateError('test failure');
    await pending?.future;
    await super.save(commitment);
  }
}

Future<void> _open(
  WidgetTester tester,
  _ControlledRepository repository, {
  Brightness brightness = Brightness.light,
  double scale = 1,
  Future<void> Function()? onSaved,
}) async {
  final commitment = Commitment.create(
    title: 'تعهد نمونه',
    description: 'توضیح خواندنی',
    tags: {'آموزش'},
    attachmentIds: ['retained-evidence'],
    color: CommitmentColor.rose,
  );
  await repository.save(commitment);
  repository.writes = 0;
  final plans = InMemoryCommitmentPlanRepository();
  await tester.pumpWidget(
    MaterialApp(
      theme: brightness == Brightness.light
          ? PlanActTheme.light()
          : PlanActTheme.dark(),
      builder: (context, child) => Directionality(
        textDirection: TextDirection.rtl,
        child: MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
      ),
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => Navigator.of(context).push<void>(
              MaterialPageRoute(
                builder: (_) => CommitmentDetailsPage(
                  commitment: commitment,
                  repository: repository,
                  planRepository: plans,
                  expectationRepository:
                      InMemoryFinancialExpectationRepository(),
                  occurrenceExecutor: PersistedOccurrenceActionExecutor(
                    plans: plans,
                  ),
                  onSaved: onSaved ?? () async {},
                ),
              ),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

Future<void> _edit(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('commitment-details-edit')));
  await tester.pumpAndSettle();
}

Future<void> _show(WidgetTester tester, Finder target) async {
  await tester.scrollUntilVisible(
    target,
    160,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'metadata is read-only until explicit edit; cancel retains or discards',
    (tester) async {
      final repository = _ControlledRepository();
      await _open(tester, repository);
      expect(find.text('تعهد نمونه'), findsOneWidget);
      expect(find.text('توضیح خواندنی'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'عنوان'), findsNothing);
      expect(find.widgetWithText(FilledButton, 'ذخیره'), findsNothing);
      await _edit(tester);
      await tester.enterText(
        find.widgetWithText(TextField, 'عنوان'),
        'پیش‌نویس',
      );
      final cancel = find.byKey(
        const ValueKey('commitment-details-cancel-edit'),
      );
      await _show(tester, cancel);
      await tester.tap(cancel);
      await tester.pumpAndSettle();
      await tester.tap(find.text('ادامهٔ ویرایش'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextField>(find.widgetWithText(TextField, 'عنوان'))
            .controller!
            .text,
        'پیش‌نویس',
      );
      await tester.tap(cancel);
      await tester.pumpAndSettle();
      await tester.tap(find.text('خروج بدون ذخیره'));
      await tester.pumpAndSettle();
      expect(find.byType(CommitmentDetailsPage), findsOneWidget);
      expect(find.widgetWithText(TextField, 'عنوان'), findsNothing);
      expect(repository.writes, 0);
      await _edit(tester);
      expect(
        tester
            .widget<TextField>(find.widgetWithText(TextField, 'عنوان'))
            .controller!
            .text,
        'تعهد نمونه',
      );
    },
  );

  testWidgets(
    'failed save retains draft and retry preserves unrelated metadata',
    (tester) async {
      final repository = _ControlledRepository();
      await _open(tester, repository);
      await _edit(tester);
      await tester.enterText(
        find.widgetWithText(TextField, 'عنوان'),
        'عنوان تازه',
      );
      final save = find.widgetWithText(FilledButton, 'ذخیره');
      await _show(tester, save);
      repository.fail = true;
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.byType(CommitmentDetailsPage), findsOneWidget);
      expect(
        tester
            .widget<TextField>(find.widgetWithText(TextField, 'عنوان'))
            .controller!
            .text,
        'عنوان تازه',
      );
      expect((await repository.list()).single.title, 'تعهد نمونه');
      repository.fail = false;
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(find.byType(CommitmentDetailsPage), findsNothing);
      final stored = (await repository.list()).single;
      expect(stored.title, 'عنوان تازه');
      expect(stored.tags, {'آموزش'});
      expect(stored.attachmentIds, ['retained-evidence']);
      expect(stored.color, CommitmentColor.rose);
    },
  );

  testWidgets(
    'committed metadata exits stale editor when parent refresh fails',
    (tester) async {
      final repository = _ControlledRepository();
      final refresh = Completer<void>();
      var refreshCalls = 0;
      await _open(
        tester,
        repository,
        onSaved: () async {
          refreshCalls++;
          await refresh.future;
        },
      );
      await _edit(tester);
      await tester.enterText(
        find.widgetWithText(TextField, 'عنوان'),
        'عنوان ثبت‌شده',
      );
      final save = find.widgetWithText(FilledButton, 'ذخیره');
      await _show(tester, save);
      await tester.tap(save);
      await tester.pump();
      expect((await repository.list()).single.title, 'عنوان ثبت‌شده');
      expect(repository.writes, 1);
      expect(refreshCalls, 1);
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton).first).onPressed,
        isNull,
      );
      await tester.tap(find.byType(BackButton));
      await tester.pump();
      expect(find.byType(CommitmentDetailsPage), findsOneWidget);
      refresh.completeError(StateError('test refresh failure'));
      await tester.pumpAndSettle();
      expect(find.byType(CommitmentDetailsPage), findsNothing);
      expect(find.text('open'), findsOneWidget);
      expect(
        find.text(
          'تغییر ثبت شد؛ بازخوانی صفحه انجام نشد. دوباره بازخوانی کنید.',
        ),
        findsOneWidget,
      );
      expect(
        find.text('ذخیرهٔ تغییرات انجام نشد؛ دوباره تلاش کنید.'),
        findsNothing,
      );
      expect(find.widgetWithText(FilledButton, 'ذخیره'), findsNothing);
      expect(repository.writes, 1);
      expect(refreshCalls, 1);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('pending save disables edits, duplicate save and route exit', (
    tester,
  ) async {
    final repository = _ControlledRepository();
    await _open(tester, repository);
    await _edit(tester);
    final save = find.widgetWithText(FilledButton, 'ذخیره');
    await _show(tester, save);
    repository.pending = Completer<void>();
    await tester.tap(save);
    await tester.pump();
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton).first).onPressed,
      isNull,
    );
    await tester.scrollUntilVisible(
      find.widgetWithText(TextField, 'عنوان'),
      -160,
      scrollable: find.byType(Scrollable).first,
    );
    expect(
      tester.widget<TextField>(find.widgetWithText(TextField, 'عنوان')).enabled,
      isFalse,
    );
    await tester.tap(find.byType(BackButton));
    await tester.pump();
    expect(find.byType(CommitmentDetailsPage), findsOneWidget);
    expect(repository.writes, 1);
    repository.pending!.complete();
    await tester.pumpAndSettle();
    expect(find.byType(CommitmentDetailsPage), findsNothing);
  });

  for (final brightness in Brightness.values) {
    testWidgets('Details responsive RTL ${brightness.name} at large text', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await _open(
        tester,
        _ControlledRepository(),
        brightness: brightness,
        scale: 2,
      );
      expect(
        Directionality.of(tester.element(find.text('تعهد نمونه'))),
        TextDirection.rtl,
      );
      expect(tester.takeException(), isNull);
      await _edit(tester);
      await _show(
        tester,
        find.byKey(const ValueKey('commitment-details-cancel-edit')),
      );
      expect(tester.takeException(), isNull);
      tester.view.physicalSize = const Size(1400, 1100);
      await tester.pumpAndSettle();
      expect(
        tester.getSize(find.byType(ListView).first).width,
        PlanActSpacing.contentWidth,
      );
      expect(tester.takeException(), isNull);
    });
  }
}
