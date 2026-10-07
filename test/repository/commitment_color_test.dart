import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planact/app/theme/commitment_identity_palette.dart';
import 'package:planact/core/database/app_database.dart' hide Commitment;
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/features/commitments/application/commitment_draft.dart';
import 'package:planact/features/commitments/application/commitment_use_cases.dart';
import 'package:planact/features/commitments/data/drift_commitment_repository.dart';
import 'package:planact/features/commitments/domain/commitment.dart';
import 'package:planact/features/commitments/presentation/commitment_color_picker.dart';

void main() {
  test('identity survives every immutable operation; null can be explicit', () {
    final item = Commitment.create(title: 'کلاس', color: CommitmentColor.rose);
    for (final changed in [
      item.pause(),
      item.pause().resume(),
      item.archive(),
      item.archive().restore(),
      item.complete(),
      item.cancel(),
      item.withTags({'آموزش'}),
      item.updateMetadata(title: 'نام تازه'),
    ]) {
      expect(changed.color, CommitmentColor.rose);
    }
    expect(item.withColor(null).color, isNull);
    const draft = CommitmentDraft(color: CommitmentColor.blue);
    expect(draft.copyWith(title: 'عنوان').color, CommitmentColor.blue);
    expect(draft.copyWith(clearColor: true).color, isNull);
  });

  test('stable fallback and readable Light/Dark identity pairs', () {
    final id = StableId.parse('019a1234-5678-7123-8123-123456789abc');
    expect(
      CommitmentIdentityPalette.fallback(id),
      CommitmentIdentityPalette.fallback(StableId.parse(id.value)),
    );
    for (final brightness in Brightness.values) {
      for (final color in CommitmentColor.values) {
        final a = CommitmentIdentityPalette.background(
          color,
          brightness,
        ).computeLuminance();
        final b = CommitmentIdentityPalette.foreground(
          color,
          brightness,
        ).computeLuminance();
        expect(
          ((a > b ? a : b) + .05) / ((a > b ? b : a) + .05),
          greaterThanOrEqualTo(4.5),
        );
        expect(CommitmentIdentityPalette.resolve(color, id), color);
      }
    }
  });

  test(
    'file-backed create/edit/status/tag/clear survive cold restart',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'commitment-color-',
      );
      final file = File('${directory.path}/data.sqlite');
      var database = AppDatabase.forTesting(NativeDatabase(file));
      try {
        var repository = DriftCommitmentRepository(database);
        final item = await CreateCommitment(repository)(
          title: 'کلاس',
          color: CommitmentColor.violet,
        );
        await UpdateCommitmentMetadata(repository)(
          commitmentId: item.id,
          title: 'نام تازه',
          description: null,
          priority: CommitmentPriority.high,
        );
        await PauseCommitment(repository)(item.id);
        await repository.save(
          (await repository.findById(item.id))!.withTags({'آموزش'}),
        );
        await database.close();
        database = AppDatabase.forTesting(NativeDatabase(file));
        repository = DriftCommitmentRepository(database);
        expect(
          (await repository.findById(item.id))!.color,
          CommitmentColor.violet,
        );
        await UpdateCommitmentMetadata(repository)(
          commitmentId: item.id,
          title: 'نام تازه',
          description: null,
          priority: CommitmentPriority.high,
          color: null,
          updateColor: true,
        );
        await database.close();
        database = AppDatabase.forTesting(NativeDatabase(file));
        expect(
          (await DriftCommitmentRepository(database).findById(item.id))!.color,
          isNull,
        );
        await expectLater(
          database.customStatement(
            "UPDATE commitments SET color_key = 'unknown'",
          ),
          throwsA(anything),
        );
      } finally {
        await database.close();
        await directory.delete(recursive: true);
      }
    },
  );

  for (final brightness in Brightness.values) {
    testWidgets('picker selects, clears and disables in $brightness RTL', (
      tester,
    ) async {
      CommitmentColor? selected;
      var enabled = true;
      late StateSetter update;
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(brightness: brightness),
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              body: StatefulBuilder(
                builder: (context, setState) {
                  update = setState;
                  return SingleChildScrollView(
                    child: CommitmentColorPicker(
                      selected: selected,
                      enabled: enabled,
                      onChanged: (value) => setState(() => selected = value),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.byKey(const ValueKey('commitment-color-blue')));
      await tester.pump();
      expect(selected, CommitmentColor.blue);
      await tester.tap(find.text('خودکار'));
      await tester.pump();
      expect(selected, isNull);
      update(() => enabled = false);
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('commitment-color-blue')));
      expect(selected, isNull);
      expect(tester.takeException(), isNull);
    });
  }
}
