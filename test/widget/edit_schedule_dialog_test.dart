import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/core/time/jalali_date.dart';
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
      await tester.tap(find.byIcon(Icons.calendar_month_outlined));
      await tester.pumpAndSettle();
      expect(find.text('ش'), findsOneWidget);
      final target = find.byKey(const ValueKey('capture-date-1'));
      await tester.ensureVisible(target);
      await tester.tap(target);
      await tester.pumpAndSettle();
      await tester.tap(find.text('تأیید تاریخ'));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.schedule), findsNothing);
      expect(occurrence.currentScheduledAt, date);
      await tester.tap(find.text('ذخیرهٔ زمان'));
      await tester.pumpAndSettle();
      final month = JalaliDate.fromDateTime(DateTime(2027, 1, 2));
      final selected = JalaliDate(month.year, month.month, 1).toDateTime();
      expect(
        result!.scheduledAt,
        LocalDate(selected.year, selected.month, selected.day),
      );
      expect(occurrence.currentScheduledAt, date);
      expect(result!.scope, SeriesEditScope.onlyThis);
      expect(tester.takeException(), isNull);
    },
  );
}
