import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planact/core/application/command_gate.dart';
import 'package:planact/core/database/app_database.dart' show AppDatabase;
import 'package:planact/core/errors/app_error.dart';
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/features/classification/application/tag_repository.dart';
import 'package:planact/features/classification/data/drift_tag_repository.dart';
import 'package:planact/features/classification/domain/tag.dart';

void main() {
  test(
    'tag normalization preserves display spelling and rejects empty labels',
    () {
      final id = StableId.generate();
      final date = DateTime.utc(2026);
      final tag = Tag(id: id, label: '  # Work  ', createdAt: date);
      expect(tag.label, 'Work');
      expect(tag.normalizedLabel, 'work');
      expect(tag.displayLabel, '#Work');
      for (final label in ['', ' ', '#', '#   ']) {
        expect(
          () => Tag(id: id, label: label, createdAt: date),
          throwsA(isA<ValidationError>()),
        );
      }
    },
  );

  for (final durable in [false, true]) {
    group(durable ? 'Drift contract' : 'InMemory contract', () {
      late TagRepository repository;
      late Object owner;
      setUp(() {
        if (durable) {
          final database = AppDatabase.forTesting(NativeDatabase.memory());
          addTearDown(database.close);
          repository = DriftTagRepository(database);
          owner = database;
        } else {
          repository = InMemoryTagRepository();
          owner = repository;
        }
      });

      test('rename preserves identity/time, rejects normalized duplicates atomically', () async {
        final first = await repository.getOrCreate('Work');
        final second = await repository.getOrCreate('آموزش');
        final renamed = await repository.rename(first.id, ' # Office ');
        expect(renamed.id, first.id);
        expect(renamed.createdAt, first.createdAt);
        expect(renamed.label, 'Office');
        expect((await repository.getOrCreate('#OFFICE')).id, first.id);
        for (final label in ['#آموزش', '', '#  ']) {
          await expectLater(
            repository.rename(first.id, label),
            throwsA(isA<ValidationError>()),
          );
        }
        expect((await repository.list()).map((tag) => tag.label).toSet(), {
          'Office',
          second.label,
        });
        final same = await repository.rename(first.id, 'OFFICE');
        expect(same.id, first.id);
        await expectLater(
          repository.rename(StableId.generate(), 'missing'),
          throwsA(isA<ValidationError>()),
        );
      });

      test(
        'autocomplete treats percent underscore and backslash literally',
        () async {
          for (final label in ['ordinary', '100%', 'a_b', r'a\b', 'Work']) {
            await repository.getOrCreate(label);
          }
          for (final query in ['%', '_', r'\']) {
            final results = await repository.autocomplete(query);
            expect(results, hasLength(1));
            expect(results.single.label.contains(query), isTrue);
          }
          expect(
            (await repository.autocomplete(' # WO ')).single.label,
            'Work',
          );
          expect(await repository.autocomplete('missing'), isEmpty);
          expect(await repository.autocomplete(''), hasLength(5));
        },
      );

      test('retired CommandGate rejects reads and mutations', () async {
        final tag = await repository.getOrCreate('work');
        final gate = CommandGate();
        CommandGate.bind(owner, gate);
        await gate.retire();
        final operations = <Future<Object?> Function()>[
          () => repository.getOrCreate('new'),
          () => repository.rename(tag.id, 'new'),
          () => repository.remove(tag.id),
          () => repository.list(),
          () => repository.autocomplete(''),
          () => repository.tagsFor('record', TaggableType.commitment),
          () => repository.recordsWithTag(tag.id, TaggableType.accountEntry),
          () => repository.attach(
            recordId: 'record',
            tag: tag,
            type: TaggableType.commitment,
          ),
          () => repository.detach(
            recordId: 'record',
            tag: tag,
            type: TaggableType.commitment,
          ),
        ];
        for (final operation in operations) {
          await expectLater(
            operation(),
            throwsA(isA<StaleApplicationCommand>()),
          );
        }
      });
    });
  }

  test(
    'memory memberships are typed, idempotent, and globally removed',
    () async {
      final repository = InMemoryTagRepository();
      final tag = await repository.getOrCreate('کار');
      final other = await repository.getOrCreate('آموزش');
      for (final type in TaggableType.values) {
        await repository.attach(recordId: 'same', tag: tag, type: type);
        await repository.attach(recordId: 'same', tag: tag, type: type);
      }
      await repository.attach(
        recordId: 'another',
        tag: other,
        type: TaggableType.commitment,
      );
      expect(await repository.recordsWithTag(tag.id, TaggableType.commitment), {
        'same',
      });
      await repository.detach(
        recordId: 'same',
        tag: tag,
        type: TaggableType.commitment,
      );
      expect(
        await repository.recordsWithTag(tag.id, TaggableType.commitment),
        isEmpty,
      );
      expect(
        await repository.recordsWithTag(tag.id, TaggableType.accountEntry),
        {'same'},
      );
      await repository.remove(tag.id);
      await repository.remove(tag.id);
      expect(
        await repository.tagsFor('same', TaggableType.accountEntry),
        isEmpty,
      );
      expect(
        await repository.recordsWithTag(other.id, TaggableType.commitment),
        {'another'},
      );
      await expectLater(
        repository.attach(
          recordId: 'same',
          tag: tag,
          type: TaggableType.commitment,
        ),
        throwsA(isA<ValidationError>()),
      );
    },
  );
}
