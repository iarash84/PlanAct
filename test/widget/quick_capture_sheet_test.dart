import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planact/features/capture/presentation/quick_capture_sheet.dart';

void main() {
  Widget host() => const MaterialApp(
    locale: Locale('fa'),
    home: Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(body: QuickCaptureSheet()),
    ),
  );

  testWidgets('cancelling an empty custom reminder does not crash', (
    tester,
  ) async {
    await tester.pumpWidget(host());

    await tester.enterText(
      find.byKey(const ValueKey('commitment-title-field')),
      'جلسه',
    );
    await tester.tap(find.text('افزودن جزئیات'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('زمان دلخواه'));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('custom-reminder-minutes-field')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('custom-reminder-cancel')));
    await tester.pumpAndSettle();

    expect(find.text('یادآوری دلخواه'), findsNothing);
    expect(find.text('یادآوری‌های این تعهد'), findsOneWidget);
  });
}
