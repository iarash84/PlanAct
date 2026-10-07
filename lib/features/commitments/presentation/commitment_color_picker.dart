import 'package:flutter/material.dart';
import 'package:planact/app/theme/commitment_identity_palette.dart';
import 'package:planact/app/theme/planact_spacing.dart';
import 'package:planact/features/commitments/domain/commitment_color.dart';

class CommitmentColorPicker extends StatelessWidget {
  const CommitmentColorPicker({
    super.key,
    required this.selected,
    required this.onChanged,
    this.enabled = true,
  });
  final CommitmentColor? selected;
  final ValueChanged<CommitmentColor?> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'رنگ تعهد (اختیاری)',
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: PlanActSpacing.sm),
        Wrap(
          spacing: PlanActSpacing.sm,
          runSpacing: PlanActSpacing.sm,
          children: [
            ChoiceChip(
              label: const Text('خودکار'),
              selected: selected == null,
              onSelected: enabled ? (_) => onChanged(null) : null,
            ),
            for (final color in CommitmentColor.values)
              ChoiceChip(
                key: ValueKey('commitment-color-${color.name}'),
                label: Text(CommitmentIdentityPalette.label(color)),
                avatar: Icon(
                  Icons.circle,
                  color: CommitmentIdentityPalette.background(
                    color,
                    brightness,
                  ),
                ),
                selected: selected == color,
                onSelected: enabled ? (_) => onChanged(color) : null,
              ),
          ],
        ),
        const SizedBox(height: PlanActSpacing.sm),
        const Text('رنگ فقط برای شناسایی تعهد است؛ وضعیت را تغییر نمی‌دهد.'),
      ],
    );
  }
}
