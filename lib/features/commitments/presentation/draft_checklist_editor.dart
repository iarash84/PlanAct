import 'package:flutter/material.dart';
import 'package:planact/app/theme/planact_spacing.dart';
import 'package:planact/core/localization/planact_localizations.dart';

/// Draft-only checklist composer. It follows the tag interaction pattern and
/// writes nothing until the surrounding commitment is saved.
class DraftChecklistEditor extends StatefulWidget {
  const DraftChecklistEditor({
    super.key,
    required this.items,
    required this.onChanged,
    this.enabled = true,
  });

  final List<String> items;
  final ValueChanged<List<String>> onChanged;
  final bool enabled;

  @override
  State<DraftChecklistEditor> createState() => _DraftChecklistEditorState();
}

class _DraftChecklistEditorState extends State<DraftChecklistEditor> {
  final _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _add() {
    if (!widget.enabled) return;
    final value = _controller.text.trim();
    if (value.isEmpty) {
      setState(() => _error = planActL10n(context).checklistEmptyTitle);
      return;
    }
    widget.onChanged([...widget.items, value]);
    _controller.clear();
    setState(() => _error = null);
  }

  void _remove(int index) {
    final next = [...widget.items]..removeAt(index);
    widget.onChanged(next);
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        planActL10n(context).checklistTitle,
        style: Theme.of(context).textTheme.titleMedium,
      ),
      Text(planActL10n(context).checklistDraftScope),
      if (widget.items.isNotEmpty) ...[
        const SizedBox(height: PlanActSpacing.sm),
        Wrap(
          spacing: PlanActSpacing.sm,
          runSpacing: PlanActSpacing.xs,
          children: [
            for (var index = 0; index < widget.items.length; index++)
              InputChip(
                key: ValueKey('draft-checklist-item-$index'),
                label: Text(widget.items[index]),
                onDeleted: widget.enabled ? () => _remove(index) : null,
              ),
          ],
        ),
      ],
      const SizedBox(height: PlanActSpacing.sm),
      TextField(
        key: const ValueKey('draft-checklist-title'),
        controller: _controller,
        enabled: widget.enabled,
        decoration: InputDecoration(
          labelText: planActL10n(context).checklistAddHint,
          errorText: _error,
          suffixIcon: IconButton(
            tooltip: planActL10n(context).checklistAdd,
            onPressed: widget.enabled ? _add : null,
            icon: const Icon(Icons.add),
          ),
        ),
        onSubmitted: (_) => _add(),
      ),
    ],
  );
}
