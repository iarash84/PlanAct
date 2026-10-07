import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planact/app/planact_app.dart';
import 'package:planact/app/theme/planact_theme.dart';
import 'package:planact/core/database/app_database.dart' show AppDatabase;
import 'package:planact/features/classification/application/tag_repository.dart';
import 'package:planact/features/classification/data/drift_tag_repository.dart';
import 'package:planact/features/commitments/application/commitment_plan_use_case.dart';
import 'package:planact/features/commitments/data/drift_commitment_repository.dart';
import 'package:planact/features/commitments/domain/commitment.dart';
import 'package:planact/features/finance/application/financial_expectation_use_cases.dart';
import 'package:planact/features/scheduling/application/occurrence_actions.dart';

void main() {
  testWidgets(
    'detached persisted tag is not resurrected by detail metadata save',
    (tester) async {
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final commitments = DriftCommitmentRepository(database);
      final tags = DriftTagRepository(database);
      final commitment = Commitment.create(
        title: 'کلاس',
        tags: {'آموزش'},
        color: CommitmentColor.rose,
      );
      await commitments.save(commitment);
      final plans = InMemoryCommitmentPlanRepository();
      var refreshes = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: PlanActTheme.light(),
          builder: (context, child) =>
              Directionality(textDirection: TextDirection.rtl, child: child!),
          home: CommitmentDetailsPage(
            commitment: commitment,
            repository: commitments,
            tagRepository: tags,
            planRepository: plans,
            expectationRepository: InMemoryFinancialExpectationRepository(),
            occurrenceExecutor: PersistedOccurrenceActionExecutor(plans: plans),
            onSaved: () async {
              refreshes++;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      final detailsScroll = find.byType(Scrollable).first;
      await tester.scrollUntilVisible(
        find.text('#آموزش'),
        200,
        scrollable: detailsScroll,
      );
      await tester.tap(find.text('#آموزش'));
      await tester.pumpAndSettle();
      expect((await commitments.findById(commitment.id))!.tags, isEmpty);
      await tester.scrollUntilVisible(
        find.widgetWithText(TextField, 'عنوان'),
        -200,
        scrollable: detailsScroll,
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'عنوان'),
        'کلاس جدید',
      );
      final color = find.byKey(const ValueKey('commitment-color-blue'));
      await tester.ensureVisible(color);
      await tester.tap(color);
      await tester.pumpAndSettle();
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.widgetWithText(FilledButton, 'ذخیره'),
        200,
        scrollable: detailsScroll,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'ذخیره'));
      await tester.pumpAndSettle();
      final stored = (await commitments.findById(commitment.id))!;
      expect(stored.title, 'کلاس جدید');
      expect(stored.tags, isEmpty);
      expect(stored.color, CommitmentColor.blue);
      expect(
        await tags.tagsFor(commitment.id.value, TaggableType.commitment),
        isEmpty,
      );
      expect(refreshes, 2);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
