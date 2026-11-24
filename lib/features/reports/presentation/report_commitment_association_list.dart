import 'package:flutter/material.dart';
import 'package:planact/features/reports/domain/personal_reports.dart';

/// A deliberately amount-free section, separate from cash/settlement widgets.
/// The caller supplies registered localized copy explicitly identifying these
/// rows as descriptive, not settlement. No money formatter is accepted here.
class ReportCommitmentAssociationList extends StatelessWidget {
  const ReportCommitmentAssociationList({
    super.key,
    required this.associations,
    required this.title,
    required this.descriptiveNotSettlementLabel,
  });

  final List<ReportCommitmentAssociation> associations;
  final String title;
  final String descriptiveNotSettlementLabel;

  @override
  Widget build(BuildContext context) {
    if (associations.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListTile(
          title: Text(title),
          subtitle: Text(descriptiveNotSettlementLabel),
        ),
        for (final row in associations)
          ListTile(
            leading: const Icon(Icons.link),
            title: Text(row.commitment.title),
            subtitle: Text(
              row.transaction.note ?? descriptiveNotSettlementLabel,
            ),
          ),
      ],
    );
  }
}
