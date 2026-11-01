import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planact/app/quick_add_fab.dart';
import 'package:planact/app/theme/planact_theme.dart';

void main() {
  testWidgets('quick add FAB gives a brief press-scale response', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: PlanActTheme.light(),
        home: Scaffold(
          floatingActionButton: QuickAddFab(
            size: 56,
            tooltip: 'افزودن سریع',
            onPressed: _noop,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final scale = find.byType(AnimatedScale);
    expect(tester.widget<AnimatedScale>(scale).scale, 1);

    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(const ValueKey('shell-quick-add'))),
    );
    await tester.pump();
    expect(tester.widget<AnimatedScale>(scale).scale, 0.96);

    await gesture.up();
    await tester.pump();
    expect(tester.widget<AnimatedScale>(scale).scale, 1);
  });

  testWidgets(
    'quick add FAB skips the scale transition when motion is reduced',
    (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: MaterialApp(
            theme: PlanActTheme.light(),
            home: Scaffold(
              floatingActionButton: QuickAddFab(
                size: 56,
                tooltip: 'افزودن سریع',
                onPressed: _noop,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final gesture = await tester.startGesture(
        tester.getCenter(find.byKey(const ValueKey('shell-quick-add'))),
      );
      await tester.pump();
      expect(
        tester.widget<AnimatedScale>(find.byType(AnimatedScale)).duration,
        Duration.zero,
      );

      await gesture.cancel();
    },
  );
}

void _noop() {}
