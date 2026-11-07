import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planact/app/theme/planact_theme.dart';
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/features/commitments/application/commitment_correction.dart';
import 'package:planact/features/commitments/presentation/commitment_correction_card.dart';
import 'package:planact/features/finance/application/financial_expectation_use_cases.dart';
import 'package:planact/features/finance/presentation/financial_expectation_editor.dart';
import 'package:planact/features/finance/domain/financial_expectation.dart';

class _Corrections implements CommitmentCorrectionRepository {
  @override
  Future<List<CommitmentCorrectionRecord>> history(StableId id) async => [];
  @override
  Future<CommitmentCorrectionPreview> preview(
    CommitmentCorrectionRequest request,
    DateTime now,
  ) async =>
      throw UnimplementedError('Layout tests must not submit corrections');
  @override
  Future<void> confirm(
    CommitmentCorrectionPreview preview,
    DateTime now,
  ) async {
    fail('Browsing must not confirm a correction');
  }
}

void _expectGap(WidgetTester tester, Finder first, Finder second) {
  expect(
    tester.getRect(second).top - tester.getRect(first).bottom,
    greaterThanOrEqualTo(12),
  );
}

void main() {
  for (final dark in [false, true]) {
    for (final scale in [1.0, 2.0]) {
      for (final correction in [true, false]) {
        testWidgets(
          'expanded detail form spacing: correction=$correction dark=$dark scale=$scale',
          (tester) async {
            tester.view.physicalSize = const Size(360, 900);
            tester.view.devicePixelRatio = 1;
            addTearDown(tester.view.resetPhysicalSize);
            addTearDown(tester.view.resetDevicePixelRatio);
            final repository = InMemoryFinancialExpectationRepository();
            final id = StableId.generate();
            final useCases = FinancialExpectationUseCases(repository);
            await tester.pumpWidget(
              MaterialApp(
                theme: dark ? PlanActTheme.dark() : PlanActTheme.light(),
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(context)
                      .copyWith(textScaler: TextScaler.linear(scale)),
                  child: Directionality(
                    textDirection: TextDirection.rtl,
                    child: child!,
                  ),
                ),
                home: Scaffold(
                  body: SingleChildScrollView(
                    child: correction
                        ? CommitmentCorrectionCard(
                            repository: _Corrections(),
                            commitmentId: id,
                            onSaved: () async {},
                          )
                        : FinancialExpectationEditor(
                            occurrenceId: id,
                            useCases: useCases,
                            accounts: const [],
                          ),
                  ),
                ),
              ),
            );
            await tester.pumpAndSettle();
            await tester.tap(find.byType(ExpansionTile).first);
            await tester.pumpAndSettle();
            final fields = find.byType(TextField);
            expect(fields, findsNWidgets(2));
            _expectGap(tester, fields.at(0), fields.at(1));
            if (correction) {
              _expectGap(
                tester,
                find.byType(DropdownButtonFormField<bool>),
                fields.first,
              );
              await tester.enterText(fields.first, '8');
              await tester.enterText(fields.last, 'دلیل اصلاح');
              await tester.ensureVisible(
                find.byType(DropdownButtonFormField<bool>),
              );
              await tester.tap(find.byType(DropdownButtonFormField<bool>));
              await tester.pumpAndSettle();
              await tester.tap(find.byType(DropdownMenuItem<bool>).last);
              await tester.pumpAndSettle();
              _expectGap(tester, fields.first, fields.last);
              expect(
                tester.widget<TextField>(fields.first).controller!.text,
                '8',
              );
              expect(
                tester.widget<TextField>(fields.last).controller!.text,
                'دلیل اصلاح',
              );
            } else {
              _expectGap(
                tester,
                find.byType(SegmentedButton<FinancialExpectationDirection>),
                fields.first,
              );
              expect(await useCases.getByOccurrence(id), isNull);
            }
            expect(tester.takeException(), isNull);
          },
        );
      }
    }
  }
}
