import 'package:flutter/material.dart';
import 'package:planact/app/theme/planact_spacing.dart';
import 'package:planact/core/localization/persian_numbers.dart';
import 'package:planact/core/localization/planact_localizations.dart';
import 'package:planact/features/classification/domain/tag.dart';

/// Bounded form summary; the catalogue is only built lazily inside the sheet.
class CompactTagSelection extends StatelessWidget {
  const CompactTagSelection({
    super.key,
    required this.labels,
    required this.onOpen,
    this.enabled = true,
    this.title,
  });
  final Iterable<String> labels;
  final VoidCallback onOpen;
  final bool enabled;
  final String? title;

  @override
  Widget build(BuildContext context) {
    final selected = labels.toList(growable: false);
    final l10n = planActL10n(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (title != null)
          Text(title!, style: Theme.of(context).textTheme.titleMedium),
        Wrap(
          spacing: PlanActSpacing.sm,
          runSpacing: PlanActSpacing.xs,
          children: [
            for (final label in selected.take(3)) Chip(label: Text('#$label')),
            if (selected.length > 3)
              Chip(
                label: Text(
                  l10n.tagSelectionRemaining(
                    PersianNumbers.format(selected.length - 3),
                  ),
                ),
              ),
          ],
        ),
        OutlinedButton.icon(
          key: const ValueKey('tag-selection-open'),
          onPressed: enabled ? onOpen : null,
          icon: const Icon(Icons.label_outline),
          label: Text(l10n.tagSelectionChoose),
        ),
      ],
    );
  }
}

Future<void> showTagSelection(
  BuildContext context, {
  required List<String> Function() labels,
  required bool Function(String) selected,
  required Future<void> Function(String, bool) onToggle,
  Future<void> Function(String)? onCreate,
  String? Function()? error,
  Future<void> Function()? onRetry,
  String? description,
  String? title,
  bool single = false,
  VoidCallback? onAll,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  builder: (_) => _TagSelectionSheet(
    labels: labels,
    selected: selected,
    onToggle: onToggle,
    onCreate: onCreate,
    error: error,
    onRetry: onRetry,
    description: description,
    title: title,
    single: single,
    onAll: onAll,
  ),
);

class _TagSelectionSheet extends StatefulWidget {
  const _TagSelectionSheet({
    required this.labels,
    required this.selected,
    required this.onToggle,
    this.onCreate,
    this.error,
    this.onRetry,
    this.description,
    this.title,
    this.single = false,
    this.onAll,
  });
  final List<String> Function() labels;
  final bool Function(String) selected;
  final Future<void> Function(String, bool) onToggle;
  final Future<void> Function(String)? onCreate;
  final String? Function()? error;
  final Future<void> Function()? onRetry;
  final String? description, title;
  final bool single;
  final VoidCallback? onAll;
  @override
  State<_TagSelectionSheet> createState() => _TagSelectionSheetState();
}

class _TagSelectionSheetState extends State<_TagSelectionSheet> {
  final _query = TextEditingController();
  final _extent = DraggableScrollableController();
  bool _busy = false, _expanded = false;

  @override
  void dispose() {
    _query.dispose();
    _extent.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = planActL10n(context);
    final key = normalizeTagKey(_query.text);
    final labels = widget.labels();
    final results = labels
        .where((label) => normalizeTagKey(label).contains(key))
        .toList(growable: false);
    final create =
        widget.onCreate != null &&
        key.isNotEmpty &&
        !labels.any((label) => normalizeTagKey(label) == key);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: DraggableScrollableSheet(
        controller: _extent,
        initialChildSize: .75,
        minChildSize: .5,
        maxChildSize: 1,
        expand: false,
        builder: (context, controller) => SafeArea(
          top: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: PlanActSpacing.lg,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.title ?? l10n.tagSelectionChoose,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    IconButton(
                      tooltip: _expanded
                          ? l10n.commitmentBrowseCollapse
                          : l10n.commitmentBrowseExpand,
                      onPressed: () {
                        _expanded = !_expanded;
                        final target = _expanded ? 1.0 : .75;
                        final duration = PlanActMotion.duration(context);
                        if (duration == Duration.zero) {
                          _extent.jumpTo(target);
                        } else {
                          _extent.animateTo(
                            target,
                            duration: duration,
                            curve: PlanActMotion.curve,
                          );
                        }
                        setState(() {});
                      },
                      icon: Icon(
                        _expanded ? Icons.fullscreen_exit : Icons.fullscreen,
                      ),
                    ),
                    IconButton(
                      tooltip: l10n.commonClose,
                      onPressed: _busy ? null : () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: PlanActSpacing.lg,
                ),
                child: TextField(
                  key: const ValueKey('tag-selection-search'),
                  controller: _query,
                  decoration: InputDecoration(
                    labelText: l10n.tagSelectionSearch,
                    prefixIcon: const Icon(Icons.search),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              if (_busy) const LinearProgressIndicator(),
              Expanded(
                child: ListView.builder(
                  key: const ValueKey('tag-selection-results'),
                  controller: controller,
                  itemCount: results.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (widget.description != null)
                            Padding(
                              padding: const EdgeInsets.all(PlanActSpacing.lg),
                              child: Text(widget.description!),
                            ),
                          if (widget.error?.call() case final String error) ...[
                            Semantics(
                              liveRegion: true,
                              child: Text(
                                error,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.error,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: _busy || widget.onRetry == null
                                  ? null
                                  : () => _run(widget.onRetry!),
                              child: Text(l10n.commonRetry),
                            ),
                          ],
                          if (widget.onAll != null)
                            ListTile(
                              title: Text(l10n.tagControlsBuildLabel2),
                              onTap: _busy
                                  ? null
                                  : () {
                                      widget.onAll!();
                                      Navigator.pop(context);
                                    },
                            ),
                          if (create)
                            ListTile(
                              leading: const Icon(Icons.add),
                              title: Text(
                                l10n.tagSelectionCreate(
                                  normalizeTagLabel(_query.text),
                                ),
                              ),
                              onTap: _busy
                                  ? null
                                  : () => _run(() async {
                                      await widget.onCreate!(
                                        normalizeTagLabel(_query.text),
                                      );
                                    }),
                            ),
                          if (results.isEmpty && !create)
                            Padding(
                              padding: const EdgeInsets.all(PlanActSpacing.lg),
                              child: Text(l10n.tagSelectionEmpty),
                            ),
                        ],
                      );
                    }
                    final label = results[index - 1];
                    return CheckboxListTile(
                      key: ValueKey('tag-result-${normalizeTagKey(label)}'),
                      title: Text('#$label'),
                      value: widget.selected(label),
                      onChanged: _busy
                          ? null
                          : (value) => _run(() async {
                              await widget.onToggle(label, value!);
                              if (widget.single && context.mounted) {
                                Navigator.pop(context);
                              }
                            }),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
