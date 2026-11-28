import 'package:drift/drift.dart';
import 'package:planact/core/application/command_gate.dart';
import 'package:planact/core/database/app_database.dart' as db;
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/core/localization/persian_numbers.dart';
import 'package:planact/core/money/money.dart';
import 'package:planact/core/time/jalali_date.dart';
import 'package:planact/features/commitments/data/drift_commitment_repository.dart';
import 'package:planact/features/commitments/domain/commitment.dart';
import 'package:planact/features/finance/domain/finance.dart';
import 'package:planact/features/finance/domain/financial_expectation.dart';
import 'package:planact/features/reconciliation/application/contextual_reconciliation.dart';
import 'package:planact/features/reconciliation/application/relationship_target_reader.dart';
import 'package:planact/features/reconciliation/domain/reconciliation.dart';
import 'package:planact/features/scheduling/domain/occurrence.dart';
import 'package:planact/features/scheduling/domain/schedule_definition.dart';
import 'package:planact/features/search/domain/search.dart';

final class DriftRelationshipTargetReader
    implements RelationshipTargetReader, CommandGateProvider {
  const DriftRelationshipTargetReader(this.database);
  final db.AppDatabase database;

  @override
  CommandGate? get commandGate => CommandGate.forOwner(database);

  @override
  Future<RelationshipTargetPage> read(
    RelationshipTargetQuery query,
    String currency,
  ) {
    if (query.page < 0) throw ArgumentError.value(query.page, 'page');
    return CommandGate.runFor(
      this,
      () => database.transaction(() async {
        final variables = <Variable>[Variable<String>(currency)];
        final predicates = <String>[];
        void filter(String expression, Object? value) {
          if (value == null) return;
          predicates.add(expression);
          variables.add(
            value is int
                ? Variable<int>(value)
                : Variable<String>(value as String),
          );
        }

        filter(
          'date(sort_value) >= ?',
          query.from == null ? null : _date(query.from!),
        );
        filter(
          'date(sort_value) <= ?',
          query.to == null ? null : _date(query.to!),
        );
        filter('outstanding >= ?', query.minimumOutstanding);
        filter('outstanding <= ?', query.maximumOutstanding);
        filter('status = ?', query.occurrenceStatus?.index);
        filter('owner_status = ?', query.commitmentStatus?.index);
        filter('cycle_id = ?', query.cycleId?.value);
        for (final token in normalizeSearchText(
          query.query,
        ).split(' ').where((s) => s.isNotEmpty)) {
          filter('instr(search_text, ?) > 0', token);
        }
        final where = predicates.isEmpty
            ? ''
            : 'WHERE ${predicates.join(' AND ')}';
        final prefix = _projection;
        final total =
            (await database
                    .customSelect(
                      '$prefix SELECT COUNT(*) AS total FROM targets $where',
                      variables: variables,
                    )
                    .getSingle())
                .read<int>('total');
        final order = switch (query.sort) {
          RelationshipTargetSort.dateAscending => 'sort_value ASC, id ASC',
          RelationshipTargetSort.dateDescending => 'sort_value DESC, id ASC',
          RelationshipTargetSort.amountAscending =>
            'outstanding IS NULL, outstanding ASC, sort_value ASC, id ASC',
          RelationshipTargetSort.amountDescending =>
            'outstanding IS NULL, outstanding DESC, sort_value ASC, id ASC',
        };
        final rows = await database
            .customSelect(
              '$prefix SELECT * FROM targets $where ORDER BY $order LIMIT ? OFFSET ?',
              variables: [
                ...variables,
                Variable<int>(query.pageSize),
                Variable<int>(query.page * query.pageSize),
              ],
            )
            .get();
        final cycles = await database
            .customSelect(
              '$prefix SELECT DISTINCT cycle_id, cycle_start FROM targets $where ORDER BY cycle_start, cycle_id',
              variables: variables,
            )
            .get();
        return RelationshipTargetPage(
          items: await _map(rows, currency),
          total: total,
          cycles: cycles.map(
            (row) => RelationshipTargetCycleOption(
              id: StableId.parse(row.read<String>('cycle_id')),
              label: _cycleLabel(row.read<int>('cycle_start')),
            ),
          ),
        );
      }),
    );
  }

  @override
  Future<List<RelationshipTarget>> byIds(
    Iterable<StableId> ids,
    String currency,
  ) {
    final keys = ids.map((id) => id.value).toSet().toList();
    if (keys.isEmpty) return Future.value(const []);
    return CommandGate.runFor(
      this,
      () => database.transaction(() async {
        final found = <String, RelationshipTarget>{};
        // Keep each SQL request below SQLite's conservative bound-variable limit.
        for (var offset = 0; offset < keys.length; offset += 200) {
          final batch = keys.skip(offset).take(200).toList();
          final rows = await database
              .customSelect(
                '$_projection SELECT * FROM targets WHERE id IN (${List.filled(batch.length, '?').join(',')})',
                variables: [
                  Variable<String>(currency),
                  ...batch.map(Variable<String>.new),
                ],
              )
              .get();
          for (final target in await _map(rows, currency)) {
            found[target.occurrence.id.value] = target;
          }
        }
        return List.unmodifiable(
          keys.map((key) => found[key]).whereType<RelationshipTarget>(),
        );
      }),
    );
  }

  String get _projection {
    final searchable = _normalizeSql(
      "c.title || char(10) || coalesce(c.description, '') || char(10) || c.tags || char(10) || coalesce((SELECT group_concat(t.label, char(10)) FROM commitment_tags ct JOIN tags t ON t.id = ct.tag_id WHERE ct.commitment_id = c.id), '')",
    );
    return '''
WITH source AS (
 SELECT o.*, cy.commitment_id AS owner_id, cy.start_date AS cycle_start,
 c.status AS owner_status, $searchable AS search_text,
 CASE WHEN substr(o.current_scheduled_value, 1, 8) = 'instant:'
 THEN strftime('%Y-%m-%dT%H:%M:%f', substr(o.current_scheduled_value, 9), 'localtime')
 WHEN substr(o.current_scheduled_value, 1, 5) = 'date:'
 THEN substr(o.current_scheduled_value, 6) || 'T00:00:00.000'
 ELSE NULL END AS direct_sort,
 substr(o.current_scheduled_value, 7) AS floating_value,
 (SELECT COUNT(*) FROM actuals a WHERE a.occurrence_id = o.id) AS result_revision,
 (SELECT e.minor_units FROM financial_expectations e
  WHERE e.occurrence_id = o.id AND e.status = ${FinancialExpectationStatus.active.index}
  AND e.currency = ? AND e.minor_units > 0
  AND (SELECT COUNT(*) FROM financial_expectations x WHERE x.occurrence_id = o.id AND x.status = ${FinancialExpectationStatus.active.index}) = 1) AS expected,
 (SELECT coalesce(SUM(a.minor_units), 0) FROM match_allocations a
  JOIN transaction_matches m ON m.id = a.match_id
  JOIN account_entries tx ON tx.id = m.transaction_id
  JOIN financial_expectations e ON e.occurrence_id = o.id
  WHERE a.occurrence_id = o.id AND m.status = ${MatchStatus.active.index}
   AND a.currency = e.currency AND m.currency = e.currency AND tx.currency = e.currency
   AND NOT EXISTS (SELECT 1 FROM account_entries r WHERE r.type = ${AccountEntryType.reversal.index} AND r.reference_id = tx.id)) AS used
 FROM occurrences o JOIN commitment_cycles cy ON cy.id = o.cycle_id
 JOIN commitments c ON c.id = cy.commitment_id
), parts AS (
 SELECT *, substr(floating_value, 1, instr(floating_value, 'T') - 1) AS floating_date,
 substr(floating_value, instr(floating_value, 'T') + 1) AS floating_time FROM source
), split AS (
 SELECT *, substr(floating_date, instr(floating_date, '-') + 1) AS month_day,
 substr(floating_time, instr(floating_time, ':') + 1) AS minute_second FROM parts
), targets AS (
 SELECT *, coalesce(direct_sort,
 printf('%04d-%02d-%02dT%02d:%02d:%06.3f',
 CAST(floating_date AS INTEGER), CAST(month_day AS INTEGER), CAST(substr(month_day, instr(month_day, '-') + 1) AS INTEGER),
 CAST(floating_time AS INTEGER), CAST(minute_second AS INTEGER), CAST(substr(minute_second, instr(minute_second, ':') + 1) AS REAL))) AS sort_value,
 CASE WHEN expected IS NULL THEN NULL ELSE max(0, expected - used) END AS outstanding
 FROM split
)
''';
  }

  Future<List<RelationshipTarget>> _map(
    List<QueryRow> rows,
    String currency,
  ) async {
    final owners = DriftCommitmentRepository(database);
    final commitments = <String, Future<Commitment?>>{};
    final result = <RelationshipTarget>[];
    for (final row in rows) {
      final ownerId = row.read<String>('owner_id');
      final owner = await commitments.putIfAbsent(
        ownerId,
        () => owners.findById(StableId.parse(ownerId)),
      );
      if (owner == null) continue;
      final record = database.occurrences.map(row.data);
      Money? money(int? value) =>
          value == null ? null : Money(minorUnits: value, currency: currency);
      final expected = row.readNullable<int>('expected');
      result.add(
        RelationshipTarget(
          owner,
          Occurrence(
            id: StableId.parse(record.id),
            cycleId: StableId.parse(record.cycleId),
            scheduleDefinitionId: StableId.parse(record.scheduleDefinitionId),
            occurrenceKey: record.occurrenceKey,
            originalScheduledAt: _parseValue(record.originalScheduledValue),
            currentScheduledAt: _parseValue(record.currentScheduledValue),
            status: OccurrenceStatus.values[record.status],
            isManualOverride: record.isManualOverride,
            resultRevision: row.read<int>('result_revision'),
          ),
          expected: money(expected),
          allocated: money(expected == null ? null : row.read<int>('used')),
          outstanding: money(row.readNullable<int>('outstanding')),
          cycleLabel: _cycleLabel(row.read<int>('cycle_start')),
        ),
      );
    }
    return List.unmodifiable(result);
  }

  static Object _parseValue(String value) {
    if (value.startsWith('date:')) {
      final parts = value.substring(5).split('-').map(int.parse).toList();
      return LocalDate(parts[0], parts[1], parts[2]);
    }
    if (value.startsWith('instant:')) {
      return DateTime.parse(value.substring(8)).toUtc();
    }
    final parts = value.substring(6).split('T');
    final date = parts[0].split('-').map(int.parse).toList();
    final time = parts[1].split(':');
    final seconds = time[2].split('.');
    return DateTime(
      date[0],
      date[1],
      date[2],
      int.parse(time[0]),
      int.parse(time[1]),
      int.parse(seconds[0]),
      int.parse(seconds[1]),
    );
  }

  static String _date(LocalDate value) =>
      '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';

  static String _cycleLabel(int seconds) {
    final date = JalaliDate.fromDateTime(
      DateTime.fromMillisecondsSinceEpoch(seconds * 1000, isUtc: true),
    );
    return '${PersianNumbers.format(date.year)}/${PersianNumbers.format(date.month)}/${PersianNumbers.format(date.day)}';
  }

  static String _normalizeSql(String expression) {
    var result = 'lower($expression)';
    final replacements = <String, String>{
      'ي': 'ی',
      'ى': 'ی',
      'ك': 'ک',
      '\u200c': '',
      '\u200d': '',
      '\u0640': '',
      '\t': ' ',
      '\r': ' ',
    };
    for (var rune = 0x064b; rune <= 0x065f; rune++) {
      replacements[String.fromCharCode(rune)] = '';
    }
    replacements['\u0670'] = '';
    for (var i = 0; i < 10; i++) {
      replacements[String.fromCharCode(0x06f0 + i)] = '$i';
      replacements[String.fromCharCode(0x0660 + i)] = '$i';
    }
    for (final entry in replacements.entries) {
      result = "replace($result, '${entry.key}', '${entry.value}')";
    }
    return result;
  }
}
