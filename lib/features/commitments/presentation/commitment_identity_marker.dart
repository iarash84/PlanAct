import 'package:flutter/material.dart';
import 'package:planact/app/theme/commitment_identity_palette.dart';
import 'package:planact/app/theme/planact_radius.dart';
import 'package:planact/app/theme/planact_spacing.dart';
import 'package:planact/features/commitments/domain/commitment.dart';

/// Commitment identity only; the icon and surrounding copy retain action/status
/// semantics independently of the user's selected color.
class CommitmentIdentityMarker extends StatelessWidget {
  const CommitmentIdentityMarker({
    super.key,
    required this.commitment,
    this.icon = Icons.event_note_outlined,
  });

  final Commitment commitment;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final identity = CommitmentIdentityPalette.resolve(
      commitment.color,
      commitment.id,
    );
    return Semantics(
      label: 'رنگ تعهد: ${CommitmentIdentityPalette.label(identity)}',
      child: ExcludeSemantics(
        child: Container(
          padding: const EdgeInsets.all(PlanActSpacing.sm),
          decoration: BoxDecoration(
            color: CommitmentIdentityPalette.background(identity, brightness),
            borderRadius: PlanActRadius.chip,
          ),
          child: Icon(
            icon,
            color: CommitmentIdentityPalette.foreground(identity, brightness),
          ),
        ),
      ),
    );
  }
}
