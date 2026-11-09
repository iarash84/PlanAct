import 'dart:async';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planact/app/app_settings.dart';
import 'package:planact/app/planact_app.dart';
import 'package:planact/app/theme/planact_colors.dart';
import 'package:planact/app/theme/planact_theme.dart';
import 'package:planact/app/theme/planact_status_colors.dart';
import 'package:planact/app/theme/theme_preset.dart';
import 'package:planact/app/theme/theme_preset_controller.dart';
import 'package:planact/core/database/app_database.dart';
import 'package:planact/features/backup/data/sqlite_backup_snapshot.dart';
import 'package:planact/features/commitments/data/drift_commitment_repository.dart';
import 'package:planact/features/settings/presentation/theme_preset_settings.dart';

class ControlledSettings extends AppSettings {
  ControlledSettings(super.database);
  bool failLoad = false;
  bool failSave = false;
  Completer<void>? pending;
  int writes = 0;
  @override
  Future<ThemePreset> readThemePreset() async {
    if (failLoad) throw StateError('load');
    return ThemePreset.original;
  }

  @override
  Future<void> writeThemePreset(ThemePreset preset) async {
    writes++;
    await pending?.future;
    if (failSave) throw StateError('save');
  }
}

double contrast(Color a, Color b) {
  final x = a.computeLuminance();
  final y = b.computeLuminance();
  return (x > y ? x + .05 : y + .05) / (x > y ? y + .05 : x + .05);
}

void main() {
  test('all eight palettes retain semantic colors and readable role pairs', () {
    for (final brightness in Brightness.values) {
      final primaries = <Color>{};
      for (final preset in ThemePreset.values) {
        final theme = brightness == Brightness.light
            ? PlanActTheme.light(preset: preset)
            : PlanActTheme.dark(preset: preset);
        final s = theme.colorScheme;
        primaries.add(s.primary);
        for (final pair in [
          (s.primary, s.onPrimary),
          (s.primaryContainer, s.onPrimaryContainer),
          (s.secondary, s.onSecondary),
          (s.secondaryContainer, s.onSecondaryContainer),
          (s.tertiary, s.onTertiary),
          (s.tertiaryContainer, s.onTertiaryContainer),
          (s.surface, s.onSurface),
          (s.surfaceContainer, s.onSurface),
          (s.surfaceContainerHighest, s.onSurfaceVariant),
          (s.error, s.onError),
        ]) {
          expect(
            contrast(pair.$1, pair.$2),
            greaterThanOrEqualTo(4.5),
            reason: '$preset $brightness $pair',
          );
        }
        expect(theme.scaffoldBackgroundColor, s.surface);
        expect(theme.cardTheme.color, s.surfaceContainer);
        expect(theme.navigationBarTheme.indicatorColor, s.primaryContainer);
        expect(
          theme.filledButtonTheme.style!.backgroundColor!.resolve({}),
          s.primary,
        );
        expect(
          theme.extension<PlanActStatusColors>(),
          brightness == Brightness.light
              ? PlanActStatusColors.light
              : PlanActStatusColors.dark,
        );
      }
      expect(primaries, hasLength(4));
    }
  });

  test('preset survives actual SQLite cold reopen independently of mode/background', () async {
    final dir = await Directory.systemTemp.createTemp('planact-theme-');
    final file = File('${dir.path}/app.sqlite');
    var db = AppDatabase.forTesting(NativeDatabase(file));
    try {
      final settings = AppSettings(db);
      expect(await settings.readThemePreset(), ThemePreset.original);
      await db.writeMetadata('theme_preset_v1', 'future-value');
      expect(await settings.readThemePreset(), ThemePreset.original);
      expect(await db.readMetadata('theme_preset_v1'), 'future-value');
      await settings.writeThemePreset(ThemePreset.earth);
      await settings.writeThemeMode(ThemeMode.dark);
      await settings.writeBackground(AppBackground.persianWaves);
      await db.close();
      db = AppDatabase.forTesting(NativeDatabase(file));
      expect(await AppSettings(db).readThemePreset(), ThemePreset.earth);
      expect(await AppSettings(db).readThemeMode(), ThemeMode.dark);
      expect(
        await AppSettings(db).readBackground(),
        AppBackground.persianWaves,
      );
      final backup = File('${dir.path}/backup.sqlite');
      final bytes = await sqliteBackupSnapshot(
        database: db,
        target: backup,
        redact: true,
      );
      await backup.writeAsBytes(bytes, flush: true);
      final restored = AppDatabase.forTesting(NativeDatabase(backup));
      try {
        expect(
          await AppSettings(restored).readThemePreset(),
          ThemePreset.earth,
        );
      } finally {
        await restored.close();
      }
    } finally {
      await db.close();
      await dir.delete(recursive: true);
    }
  });

  testWidgets(
    'load retry, pending admission, save failure and retry at large RTL text',
    (tester) async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final settings = ControlledSettings(db)..failLoad = true;
      final controller = ThemePresetController(settings);
      addTearDown(controller.dispose);
      await controller.load();
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(360, 900);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          home: ThemePresetScope(
            controller: controller,
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: MediaQuery(
                data: const MediaQueryData(textScaler: TextScaler.linear(2)),
                child: const Scaffold(
                  body: SingleChildScrollView(child: ThemePresetSettings()),
                ),
              ),
            ),
          ),
        ),
      );
      expect(
        find.text('خواندن تم ذخیره‌شده انجام نشد. دوباره تلاش کنید.'),
        findsOneWidget,
      );
      settings.failLoad = false;
      await tester.ensureVisible(find.byType(TextButton));
      await tester.tap(find.byType(TextButton));
      await tester.pumpAndSettle();
      expect(controller.ready, isTrue);
      expect(settings.writes, 0);
      settings.pending = Completer<void>();
      settings.failSave = true;
      await tester.ensureVisible(
        find.byKey(const ValueKey('theme-preset-blue')),
      );
      await tester.tap(find.byKey(const ValueKey('theme-preset-blue')));
      await tester.pump();
      expect(controller.preset, ThemePreset.original);
      expect(
        tester
            .widget<Semantics>(
              find.byKey(const ValueKey('theme-preset-purple')),
            )
            .properties
            .enabled,
        isFalse,
      );
      settings.pending!.complete();
      await tester.pumpAndSettle();
      expect(controller.saveFailed, isTrue);
      expect(
        find.text(
          'ذخیرهٔ تم انجام نشد؛ تم قبلی حفظ شده است. دوباره انتخاب کنید.',
        ),
        findsOneWidget,
      );
      settings.failSave = false;
      await tester.ensureVisible(
        find.byKey(const ValueKey('theme-preset-blue')),
      );
      await tester.tap(find.byKey(const ValueKey('theme-preset-blue')));
      await tester.pumpAndSettle();
      expect(controller.preset, ThemePreset.blue);
      expect(settings.writes, 2);
      expect(tester.takeException(), isNull);
    },
  );

  for (final brightness in Brightness.values) {
    testWidgets(
      'preview tiles use actual $brightness palettes and responsive RTL selection',
      (tester) async {
        final db = AppDatabase.forTesting(NativeDatabase.memory());
        addTearDown(db.close);
        final settings = ControlledSettings(db);
        final controller = ThemePresetController(settings);
        addTearDown(controller.dispose);
        await controller.load();
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(360, 900);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        Future<void> pump(double scale) => tester.pumpWidget(
          MaterialApp(
            theme: brightness == Brightness.light
                ? PlanActTheme.light()
                : PlanActTheme.dark(),
            home: ThemePresetScope(
              controller: controller,
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: MediaQuery(
                  data: MediaQueryData(textScaler: TextScaler.linear(scale)),
                  child: const Scaffold(
                    body: SingleChildScrollView(child: ThemePresetSettings()),
                  ),
                ),
              ),
            ),
          ),
        );
        Finder tile(ThemePreset preset) =>
            find.byKey(ValueKey('theme-preset-${preset.storageValue}'));
        await pump(1);
        expect(settings.writes, 0);
        final original = tester.getRect(tile(ThemePreset.original));
        final blue = tester.getRect(tile(ThemePreset.blue));
        final purple = tester.getRect(tile(ThemePreset.purple));
        expect(original.top, blue.top);
        expect(original.left, greaterThan(blue.left));
        expect(purple.top, greaterThan(original.bottom));
        for (final preset in ThemePreset.values) {
          final scheme = PlanActColors.scheme(brightness, preset: preset);
          final preview = find.byKey(
            ValueKey('palette-preview-${scheme.primary.toARGB32()}'),
          );
          expect(preview, findsOneWidget);
          final container = tester.widget<Container>(preview);
          expect(
            (container.decoration! as BoxDecoration).color,
            scheme.surface,
          );
          final icons = tester.widgetList<Icon>(
            find.descendant(of: preview, matching: find.byType(Icon)),
          );
          expect(icons.any((icon) => icon.color == scheme.primary), isTrue);
          expect(icons.any((icon) => icon.color == scheme.onPrimary), isTrue);
          expect(tester.getSize(tile(preset)).height, greaterThanOrEqualTo(48));
        }
        // Tap the decorative preview rather than the label: the whole tile selects.
        await tester.tapAt(blue.topCenter + const Offset(0, 28));
        await tester.pumpAndSettle();
        expect(controller.preset, ThemePreset.blue);
        expect(settings.writes, 1);
        expect(
          tester.widget<Semantics>(tile(ThemePreset.blue)).properties.selected,
          isTrue,
        );
        expect(
          tester
              .widget<Semantics>(tile(ThemePreset.original))
              .properties
              .selected,
          isFalse,
        );
        await pump(2);
        expect(
          tester.getRect(tile(ThemePreset.blue)).top,
          greaterThan(tester.getRect(tile(ThemePreset.original)).bottom),
        );
        expect(tester.takeException(), isNull);
        tester.view.physicalSize = const Size(280, 900);
        await pump(1);
        expect(
          tester.getRect(tile(ThemePreset.blue)).top,
          greaterThan(tester.getRect(tile(ThemePreset.original)).bottom),
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'real settings route updates root, retained route, subsequent dialog and restart',
    (tester) async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      await AppSettings(db).writeThemeMode(ThemeMode.dark);
      await tester.pumpWidget(
        PlanActApp(repository: DriftCommitmentRepository(db)),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(NavigationDestination, 'بیشتر'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('تنظیمات'));
      await tester.pumpAndSettle();
      final option = find.byKey(const ValueKey('theme-preset-purple'));
      await tester.ensureVisible(option);
      await tester.pumpAndSettle();
      await tester.tap(option);
      await tester.pumpAndSettle();
      expect(await AppSettings(db).readThemePreset(), ThemePreset.purple);
      final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(app.themeMode, ThemeMode.dark);
      final expected = PlanActColors.scheme(
        Brightness.dark,
        preset: ThemePreset.purple,
      );
      expect(app.darkTheme!.colorScheme, expected);
      final context = tester.element(option);
      expect(Theme.of(context).colorScheme, expected);
      showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          key: const Key('theme-dialog'),
          content: Text(Theme.of(context).colorScheme.primary.toString()),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        Theme.of(tester.element(find.byKey(const Key('theme-dialog'))))
            .colorScheme,
        expected,
      );
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(
        PlanActApp(repository: DriftCommitmentRepository(db)),
      );
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<MaterialApp>(find.byType(MaterialApp))
            .darkTheme!
            .colorScheme,
        expected,
      );
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
