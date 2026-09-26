import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planact/app/planact_app.dart';
import 'package:planact/features/commitments/application/commitment_repository.dart';
import 'package:planact/features/commitments/domain/commitment.dart';

Future<void> openActions(WidgetTester tester, String title) async {
  await tester.tap(find.byTooltip('گزینه‌های بیشتر'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('خط زمانی تعهدات'));
  await tester.pumpAndSettle();
  await tester.tap(find.widgetWithText(ListTile, title));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}

void main() {
  testWidgets('اقدام‌های والد فقط در شیت و با وضعیت معتبر نمایش داده می‌شوند', (
    tester,
  ) async {
    final repository = InMemoryCommitmentRepository();
    final commitment = Commitment.create(title: 'کلاس موسیقی');
    await repository.save(commitment);
    await tester.pumpWidget(PlanActApp(repository: repository));
    await tester.pumpAndSettle();

    await openActions(tester, 'کلاس موسیقی');
    expect(find.text('انجام شد'), findsOneWidget);
    expect(find.text('توقف موقت'), findsOneWidget);
    expect(find.text('لغو تعهد'), findsOneWidget);
    expect(find.text('بایگانی'), findsOneWidget);
    expect(find.byType(AlertDialog), findsNothing);

    await tester.tap(find.text('انجام شد'));
    await tester.pumpAndSettle();
    expect(
      (await repository.findById(commitment.id))!.status,
      CommitmentStatus.completed,
    );
  });

  testWidgets('جزئیات route مستقل است و metadata را ذخیره می‌کند', (
    tester,
  ) async {
    final repository = InMemoryCommitmentRepository();
    final commitment = Commitment.create(
      title: 'کلاس موسیقی',
      description: 'توضیحات کلاس',
      tags: {'آموزش'},
      attachmentIds: ['برنامه.pdf'],
    );
    await repository.save(commitment);
    await tester.pumpWidget(PlanActApp(repository: repository));
    await tester.pumpAndSettle();
    await openActions(tester, 'کلاس موسیقی');
    await tester.scrollUntilVisible(
      find.text('جزئیات و ویرایش'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('جزئیات و ویرایش'));
    await tester.pumpAndSettle();

    expect(find.text('جزئیات تعهد'), findsOneWidget);
    expect(find.text('توضیحات کلاس'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, 'کلاس جدید');
    await tester.tap(find.text('ذخیره'));
    await tester.pumpAndSettle();
    expect((await repository.findById(commitment.id))!.title, 'کلاس جدید');
  });

  testWidgets('خروج از ویرایش تغییرات ذخیره‌نشده را محافظت می‌کند', (
    tester,
  ) async {
    final repository = InMemoryCommitmentRepository();
    final commitment = Commitment.create(title: 'تعهد');
    await repository.save(commitment);
    await tester.pumpWidget(PlanActApp(repository: repository));
    await tester.pumpAndSettle();
    await openActions(tester, 'تعهد');
    await tester.scrollUntilVisible(
      find.text('جزئیات و ویرایش'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('جزئیات و ویرایش'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'تغییر');
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('تغییرات ذخیره نشده'), findsOneWidget);
    expect((await repository.findById(commitment.id))!.title, 'تعهد');
  });
}
