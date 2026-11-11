import 'package:flutter/material.dart';
import 'package:planact/app/theme/tag_identity_colors.dart';
import 'package:planact/features/classification/domain/tag.dart';

/// Shared identity treatment. Selection is still conveyed by the Material check.
class TagBadge extends StatelessWidget {
  const TagBadge({
    super.key,
    required this.label,
    this.selected = false,
    this.onSelected,
    this.selectable = false,
  });

  final String label;
  final bool selected;
  final bool selectable;
  final ValueChanged<bool>? onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = TagIdentityColors.forLabel(label, theme.brightness);
    final text = Text('#${normalizeTagLabel(label)}');
    final style = theme.textTheme.labelLarge?.copyWith(
      color: colors.foreground,
    );
    if (selectable) {
      return FilterChip(
        label: text,
        labelStyle: style,
        backgroundColor: colors.container,
        selectedColor: colors.container,
        disabledColor: colors.container,
        checkmarkColor: colors.foreground,
        side: BorderSide(color: colors.foreground),
        selected: selected,
        onSelected: onSelected,
      );
    }
    return Chip(
      label: text,
      labelStyle: style,
      backgroundColor: colors.container,
      side: BorderSide(color: colors.foreground),
    );
  }
}

/// Colors known tag names inside localized prose without parsing user text.
class TagSummaryText extends StatelessWidget {
  const TagSummaryText({super.key, required this.text, required this.labels});
  final String text;
  final Iterable<String> labels;

  @override
  Widget build(BuildContext context) {
    final names =
        labels.map((label) => '#${normalizeTagLabel(label)}').toSet().toList()
          ..sort((a, b) => b.length.compareTo(a.length));
    if (names.isEmpty) return Text(text);
    final pattern = RegExp(names.map(RegExp.escape).join('|'));
    final spans = <InlineSpan>[];
    var start = 0;
    for (final match in pattern.allMatches(text)) {
      spans.add(TextSpan(text: text.substring(start, match.start)));
      final name = match.group(0)!;
      final colors = TagIdentityColors.forLabel(
        name,
        Theme.of(context).brightness,
      );
      spans.add(
        TextSpan(
          text: name,
          style: TextStyle(
            color: colors.foreground,
            backgroundColor: colors.container,
          ),
        ),
      );
      start = match.end;
    }
    spans.add(TextSpan(text: text.substring(start)));
    return Text.rich(TextSpan(children: spans));
  }
}
