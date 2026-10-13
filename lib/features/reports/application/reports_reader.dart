import 'package:planact/features/reports/domain/personal_reports.dart';

/// Production adapters must return a coherent snapshot, never generate on reads.
abstract interface class ReportsReader {
  Future<ReportSnapshot> read(
    ReportFilter filter, {
    required DateTime now,
    bool includePreviews = false,
  });
}
