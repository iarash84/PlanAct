import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planact/app/app_settings.dart';
import 'package:planact/app/planact_app.dart';
import 'package:planact/core/database/app_database.dart';
import 'package:planact/features/commitments/data/drift_commitment_repository.dart';
import 'package:planact/features/settings/presentation/background_settings_card.dart';
import 'package:planact/features/settings/presentation/settings_page.dart';

void main() {
  testWidgets('settings selection applies and persists the chosen background', (
    tester,
  ) async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    await tester.pumpWidget(
      PlanActApp(repository: DriftCommitmentRepository(database)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('بیشتر'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('تنظیمات'));
    await tester.pumpAndSettle();
    final settingsList = find.descendant(
      of: find.byType(SettingsPage),
      matching: find.byType(ListView),
    );
    await tester.drag(settingsList, const Offset(0, -150));
    await tester.pumpAndSettle();
    await tester.tap(find.text('تاریک'));
    await tester.pumpAndSettle();
    await tester.drag(settingsList, const Offset(0, -250));
    await tester.pumpAndSettle();
    await tester.tap(find.text('موج ایرانی'));
    await tester.pumpAndSettle();

    expect(
      await AppSettings(database).readBackground(),
      AppBackground.persianWaves,
    );
    expect(
      find.byKey(const ValueKey('background-selected-persian_waves')),
      findsOneWidget,
    );
    final optionRects = AppBackground.values
        .map(
          (background) => tester.getRect(
            find.byKey(
              ValueKey('background-option-${background.storageValue}'),
            ),
          ),
        )
        .toList();
    expect(optionRects, hasLength(4));
    expect(
      optionRects.map((rect) => rect.top).toSet(),
      hasLength(1),
      reason: 'All four background choices should share one horizontal row.',
    );
    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.themeMode, ThemeMode.dark);
    expect(app.darkTheme!.scaffoldBackgroundColor, Colors.transparent);
    expect(app.darkTheme!.cardTheme.color!.a, closeTo(0.62, 0.01));
    expect(app.darkTheme!.appBarTheme.backgroundColor!.a, closeTo(0.72, 0.01));
    expect(
      app.darkTheme!.navigationBarTheme.backgroundColor!.a,
      closeTo(0.72, 0.01),
    );
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image is AssetImage &&
            (widget.image as AssetImage).assetName ==
                'assets/backgrounds/persian-waves.png',
      ),
      findsWidgets,
    );
    await tester.drag(settingsList, const Offset(0, 650));
    await tester.pumpAndSettle();
    await tester.tap(find.text('روشن'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
      ThemeMode.light,
    );
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
    'failed selection keeps current value and displays retry feedback',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BackgroundSettingsCard(
              value: AppBackground.none,
              onChanged: (_) async => throw StateError('write failed'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('موج ایرانی'));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('background-selected-none')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('background-selected-persian_waves')),
        findsNothing,
      );
      expect(
        find.text('ذخیرهٔ پس‌زمینه انجام نشد؛ دوباره انتخاب کنید.'),
        findsOneWidget,
      );
    },
  );

  testWidgets('four background options fit in one row on a narrow screen', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 800);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BackgroundSettingsCard(
            value: AppBackground.none,
            onChanged: (_) async {},
          ),
        ),
      ),
    );

    final rects = AppBackground.values
        .map(
          (background) => tester.getRect(
            find.byKey(
              ValueKey('background-option-${background.storageValue}'),
            ),
          ),
        )
        .toList();
    expect(rects, hasLength(4));
    expect(rects.map((rect) => rect.top).toSet(), hasLength(1));
    expect(rects.every((rect) => rect.width >= 60), isTrue);
    expect(tester.takeException(), isNull);
  });
}
