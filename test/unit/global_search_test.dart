import 'package:flutter_test/flutter_test.dart';
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/features/commitments/domain/commitment.dart';
import 'package:planact/features/search/domain/search.dart';

SearchDocument document(
  String title, {
  String description = '',
  List<String> keywords = const [],
  int day = 1,
  String? id,
}) {
  final owner = Commitment(
    id: id == null ? StableId.generate() : StableId.parse(id),
    title: title,
    createdAt: DateTime.utc(2026, 10, day),
  );
  return SearchDocument(
    target: CommitmentSearchTarget(owner),
    title: title,
    description: description,
    keywords: keywords,
    sortDate: owner.createdAt,
  );
}

void main() {
  test(
    'Persian query normalization is symmetric and preserves source text',
    () {
      final source = document('كِلاس موسيقي ۱۲۳', description: 'ثبت‌نام ALI');
      for (final query in [
        'کلاس موسیقی 123',
        'موسيقي ١٢٣',
        'کلاس ali',
        'ثبت نام',
        'ثبتنام',
        'ثبت‌نام',
      ]) {
        expect(searchDocuments([source], query), [source], reason: query);
      }
      expect(source.title, 'كِلاس موسيقي ۱۲۳');
      expect(source.description, 'ثبت‌نام ALI');
    },
  );

  test('all query words must match, across title, description and tags', () {
    final source = document(
      'زبان',
      description: 'ترم پاییز',
      keywords: ['آموزش'],
    );
    expect(searchDocuments([source], 'پاییز آموزش زبان'), [source]);
    expect(searchDocuments([source], 'پاییز ورزش'), isEmpty);
    expect(searchDocuments([source], '  \n\t‌  '), isEmpty);
    expect(searchDocuments([source], 'زبان', kind: SearchKind.note), isEmpty);
  });

  test('literal symbols are text, not SQL or regular-expression operators', () {
    final source = document('پرداخت 50% _ [a]');
    expect(searchDocuments([source], '% _ [a]'), [source]);
    expect(searchDocuments([source], '.*'), isEmpty);
    expect(searchDocuments([source], "' OR 1=1"), isEmpty);
  });

  test(
    'one query word cannot be fabricated by adjoining independent fields',
    () {
      final source = document('آب', description: 'انبار', keywords: ['آموزش']);
      expect(searchDocuments([source], 'بان'), isEmpty);
      expect(searchDocuments([source], 'آب انبار'), [source]);
    },
  );

  test('exact title then prefix then recency, with stable ID ties', () {
    final exact = document('زبان', day: 1);
    final prefix = document('زبان فرانسه', day: 2);
    final recent = document('شهریه زبان', day: 14);
    final older = document('کتاب زبان', day: 3);
    final input = [recent, prefix, older, exact];
    expect(searchDocuments(input, 'زبان'), [exact, prefix, recent, older]);
    final sameA = document('کلاس', id: '01900000-0000-7000-8000-000000000001');
    final sameB = document('کلاس', id: '01900000-0000-7000-8000-000000000002');
    expect(searchDocuments([sameB, sameA], 'کلاس'), [sameA, sameB]);
    expect(input, [recent, prefix, older, exact]);
  });

  test('ten thousand records keep all matches without a hidden result cap', () {
    final documents = List.generate(10000, (i) => document('مورد $i'));
    expect(searchDocuments(documents, 'مورد'), hasLength(10000));
    expect(searchDocuments(documents, '۹۹۹۹').single.title, 'مورد 9999');
  });
}
