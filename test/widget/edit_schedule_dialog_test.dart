import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/features/scheduling/application/series_editing.dart';
import 'package:planact/features/scheduling/domain/occurrence.dart';
import 'package:planact/features/scheduling/domain/schedule_definition.dart';
import 'package:planact/features/scheduling/presentation/edit_schedule_dialog.dart';

void main() {
  testWidgets(
    'all-day edit preserves absent time and explicit only-this scope',
    (tester) async {
      final date = LocalDate(2027, 1, 2);
      final occurrence = Occurrence(
        id: StableId.generate(),
        cycleId: StableId.generate(),
        scheduleDefinitionId: StableId.generate(),
        occurrenceKey: 'date',
        originalScheduledAt: date,
        currentScheduledAt: date,
      );
      ScheduleEditSelection? result;
      await tester.pumpWidget(
        MaterialApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () async {
                    result = await showDialog<ScheduleEditSelection>(
                      context: context,
                      builder: (_) => EditScheduleDialog(
                        occurrence: occurrence,
                        recurring: false,
                      ),
                    );
                  },
                  child: const Text('ویرایش'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('ویرایش'));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.schedule), findsNothing);
      expect(find.text('فقط این نوبت'), findsOneWidget);
      await tester.tap(find.text('ذخیرهٔ زمان'));
      await tester.pumpAndSettle();
      expect(result!.scheduledAt, date);
      expect(result!.scope, SeriesEditScope.onlyThis);
      expect(tester.takeException(), isNull);
    },
  );
}
