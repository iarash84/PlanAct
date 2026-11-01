import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:planact/features/inbox/application/inbox_use_cases.dart';

void main() {
  const parser = LocalSmsParser();
  final corpusDirectory = Directory('test/fixtures/device_sms_corpus');
  final files =
      corpusDirectory
          .listSync()
          .whereType<File>()
          .where((file) => file.path.endsWith('.txt'))
          .where((file) => !file.path.endsWith('MANIFEST.txt'))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));

  test('audits every structured device SMS corpus row', () {
    final totals = _AuditTotals();

    for (final file in files) {
      final rows = _readRows(file.readAsStringSync());
      final report = _FileAudit(file.uri.pathSegments.last);

      for (final row in rows) {
        final parsed = parser.tryParse(
          text: row.body,
          currency: 'IRR',
          sourceAddress: row.address,
        );
        final expectedTransaction = _looksTransactional(row.body);
        final expectedNonTransaction = _looksNonTransactional(row.body);

        if (expectedTransaction) {
          report.transactionRows++;
          totals.transactionRows++;
          if (parsed == null) {
            report.unrecognizedTransactions.add(row.id);
            totals.unrecognizedTransactions.add(
              '${file.uri.pathSegments.last}:${row.id}',
            );
          }
        } else if (expectedNonTransaction) {
          report.nonTransactionRows++;
          totals.nonTransactionRows++;
          if (parsed != null) {
            report.falsePositives.add(row.id);
            totals.falsePositives.add(
              '${file.uri.pathSegments.last}:${row.id}',
            );
          }
        } else {
          report.uncertainRows.add(row.id);
          totals.uncertainRows.add('${file.uri.pathSegments.last}:${row.id}');
        }
      }

      _printReport(report);
    }

    // This is an audit, not a release gate: the output deliberately exposes
    // unsupported and ambiguous rows instead of hiding them behind a failure.
    // The test must still prove that every corpus file was actually visited.
    expect(files, isNotEmpty);
    expect(totals.rows, greaterThan(0));
    _printTotals(totals);
  });
}

class _SmsRow {
  const _SmsRow({required this.id, required this.address, required this.body});

  final String id;
  final String address;
  final String body;
}

class _FileAudit {
  _FileAudit(this.fileName);

  final String fileName;
  int transactionRows = 0;
  int nonTransactionRows = 0;
  final List<String> unrecognizedTransactions = <String>[];
  final List<String> falsePositives = <String>[];
  final List<String> uncertainRows = <String>[];
}

class _AuditTotals {
  int transactionRows = 0;
  int nonTransactionRows = 0;
  final List<String> unrecognizedTransactions = <String>[];
  final List<String> falsePositives = <String>[];
  final List<String> uncertainRows = <String>[];

  int get rows => transactionRows + nonTransactionRows + uncertainRows.length;
}

List<_SmsRow> _readRows(String source) {
  final rows = <_SmsRow>[];
  final chunks = source.split(RegExp(r'(?=^Row:)', multiLine: true));

  for (final chunk in chunks) {
    final firstLine = chunk.split('\n').first.trim();
    if (!firstLine.startsWith('Row:')) continue;

    final header = RegExp(r'^Row:\s*(\S+).*?address=([^,]+),\s*body=(.*)$')
        .firstMatch(firstLine);
    if (header == null) continue;

    final bodyLines = <String>[header.group(3)!];
    final chunkLines = chunk.split(RegExp(r'\r?\n'));
    for (var index = 1; index < chunkLines.length; index++) {
      final line = chunkLines[index];
      if (line.trim().isEmpty) continue;
      bodyLines.add(line);
    }

    final body = bodyLines
        .join('\n')
        .replaceFirst(RegExp(r',\s*date=\d+\s*$', multiLine: false), '');
    rows.add(
      _SmsRow(
        id: header.group(1)!,
        address: header.group(2)!.trim(),
        body: body.trim(),
      ),
    );
  }
  return rows;
}

bool _looksTransactional(String body) {
  final hasAmountSignal = RegExp(r'(?:مبلغ|مانده|موجودی|کارت|[+-]\s*[0-9۰-۹])')
      .hasMatch(body);
  final hasOperationSignal = RegExp(
    r'برداشت|واریز|انتقال|خرید|پرداخت|موجودی|مانده',
  ).hasMatch(body);
  return hasAmountSignal && hasOperationSignal && !_looksNonTransactional(body);
}

bool _looksNonTransactional(String body) => RegExp(
  r'رمز|otp|password|فعال.?سازی|ورود|خوش.?آمدید|ناموفق|لغو|خطا|تایید.*درخواست',
  caseSensitive: false,
).hasMatch(body);

void _printReport(_FileAudit report) {
  // ignore: avoid_print
  print(
    '[SMS AUDIT] ${report.fileName}: '
    'transaction=${report.transactionRows}, '
    'nonTransaction=${report.nonTransactionRows}, '
    'unrecognized=${report.unrecognizedTransactions}, '
    'falsePositive=${report.falsePositives}, '
    'uncertain=${report.uncertainRows}',
  );
}

void _printTotals(_AuditTotals totals) {
  // ignore: avoid_print
  print(
    '[SMS AUDIT TOTAL] rows=${totals.rows}, '
    'transactions=${totals.transactionRows}, '
    'nonTransactions=${totals.nonTransactionRows}, '
    'unrecognized=${totals.unrecognizedTransactions}, '
    'falsePositive=${totals.falsePositives}, '
    'uncertain=${totals.uncertainRows}',
  );
}
