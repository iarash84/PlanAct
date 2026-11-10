import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:planact/app/theme/planact_spacing.dart';
import 'package:planact/core/localization/persian_numbers.dart';
import 'package:planact/core/localization/planact_localizations.dart';
import 'package:planact/features/reports/domain/personal_reports.dart';

/// Presentation-only paging; summaries always use the complete report.
class ReportMovementList extends StatefulWidget {
  const ReportMovementList({
    super.key,
    required this.movements,
    required this.itemBuilder,
  });

  final List<ReportMovement> movements;
  final Widget Function(ReportMovement) itemBuilder;
  static const pageSize = 20;

  @override
  State<ReportMovementList> createState() => _ReportMovementListState();
}

class _ReportMovementListState extends State<ReportMovementList> {
  int _page = 0;
  final _anchor = GlobalKey();

  @override
  void didUpdateWidget(ReportMovementList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!listEquals(
      oldWidget.movements.map((m) => (m.entry.id, m.minorUnits)).toList(),
      widget.movements.map((m) => (m.entry.id, m.minorUnits)).toList(),
    )) {
      _page = 0;
    }
  }

  void _go(int page) {
    setState(() => _page = page);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _anchor.currentContext == null) return;
      Scrollable.ensureVisible(_anchor.currentContext!);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = planActL10n(context);
    final pages = (widget.movements.length / ReportMovementList.pageSize)
        .ceil();
    final start = _page * ReportMovementList.pageSize;
    final controls = pages <= 1
        ? null
        : Wrap(
            spacing: PlanActSpacing.sm,
            runSpacing: PlanActSpacing.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              OutlinedButton(
                onPressed: _page == 0 ? null : () => _go(_page - 1),
                child: Text(l10n.reportsPreviousPage),
              ),
              Semantics(
                liveRegion: true,
                child: Text(
                  l10n.reportsPagePosition(
                    PersianNumbers.format(_page + 1),
                    PersianNumbers.format(pages),
                    PersianNumbers.format(widget.movements.length),
                  ),
                ),
              ),
              OutlinedButton(
                onPressed: _page + 1 >= pages ? null : () => _go(_page + 1),
                child: Text(l10n.reportsNextPage),
              ),
            ],
          );
    return Column(
      key: _anchor,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: PlanActSpacing.md,
      children: [
        ?controls,
        ...widget.movements
            .skip(start)
            .take(ReportMovementList.pageSize)
            .map(widget.itemBuilder),
        ?controls,
      ],
    );
  }
}
