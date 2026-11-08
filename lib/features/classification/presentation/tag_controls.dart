import 'package:planact/core/localization/planact_localizations.dart';
import 'package:planact/core/localization/persian_copy.g.dart';
import 'package:flutter/material.dart';
import 'package:planact/app/theme/planact_spacing.dart';
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/features/classification/application/tag_repository.dart';
import 'package:planact/features/classification/domain/tag.dart';

import 'tag_selection.dart';

/// Shared read-only metadata for commitment and financial surfaces.
class TagLabels extends StatelessWidget {
  const TagLabels({super.key, required this.labels});
  final Iterable<String> labels;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: PlanActSpacing.sm,
    runSpacing: PlanActSpacing.xs,
    children: [for (final label in labels) Chip(label: Text('#$label'))],
  );
}

/// Draft-only selection: reads reusable labels but never writes before creation.
class DraftTagPicker extends StatefulWidget {
  const DraftTagPicker({
    super.key,
    this.repository,
    required this.selected,
    required this.onChanged,
    this.enabled = true,
  });
  final TagRepository? repository;
  final Set<String> selected;
  final ValueChanged<Set<String>> onChanged;
  final bool enabled;

  @override
  State<DraftTagPicker> createState() => _DraftTagPickerState();
}

class _DraftTagPickerState extends State<DraftTagPicker> {
  List<Tag> _tags = [];
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final tags = await widget.repository?.list() ?? <Tag>[];
      if (mounted) {
        setState(() {
          _tags = tags;
          _loading = false;
          _error = null;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = PersianCopy.tagControlsLoadMessage;
        });
      }
    }
  }

  Future<void> _open() async {
    // Keep a local draft while the modal and parent rebuild independently.
    var draft = {...widget.selected};
    await showTagSelection(
      context,
      labels: () => <String, String>{
        for (final tag in _tags) tag.normalizedLabel: tag.label,
        for (final label in draft) normalizeTagKey(label): label,
      }.values.toList(),
      selected: (label) => draft.any(
        (value) => normalizeTagKey(value) == normalizeTagKey(label),
      ),
      onToggle: (label, selected) async {
        draft.removeWhere(
          (value) => normalizeTagKey(value) == normalizeTagKey(label),
        );
        if (selected) draft.add(label);
        widget.onChanged(Set.unmodifiable(draft));
      },
      onCreate: (label) async {
        draft.add(label);
        widget.onChanged(Set.unmodifiable(draft));
      },
      description: planActL10n(context).tagControlsBuildChildren2,
      error: () => _error,
      onRetry: _load,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          planActL10n(context).tagControlsBuildChildren,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        Text(planActL10n(context).tagControlsBuildChildren2),
        if (_loading) const LinearProgressIndicator(),
        if (_error != null) ...[
          Semantics(
            liveRegion: true,
            child: Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
          TextButton(
            onPressed: widget.enabled && !_loading ? _load : null,
            child: Text(planActL10n(context).commonRetry),
          ),
        ],
        CompactTagSelection(
          labels: widget.selected,
          enabled: widget.enabled && !_loading,
          onOpen: _open,
        ),
      ],
    );
  }
}

/// A single optional tag filter. Null means all records, not untagged records.
class TagFilter extends StatelessWidget {
  const TagFilter({
    super.key,
    required this.tags,
    required this.selected,
    required this.onChanged,
    this.enabled = true,
  });
  final List<Tag> tags;
  final StableId? selected;
  final ValueChanged<StableId?> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) => CompactTagSelection(
    labels: tags.where((tag) => tag.id == selected).map((tag) => tag.label),
    title: selected == null
        ? planActL10n(context).tagControlsBuildLabel2
        : null,
    enabled: enabled,
    onOpen: () => showTagSelection(
      context,
      labels: () => tags.map((tag) => tag.label).toList(),
      selected: (label) =>
          tags.any((tag) => tag.label == label && tag.id == selected),
      onToggle: (label, value) async => onChanged(
        value ? tags.firstWhere((tag) => tag.label == label).id : null,
      ),
      single: true,
      onAll: () => onChanged(null),
    ),
  );
}

Future<void> showTagManager(
  BuildContext context, {
  required TagRepository repository,
  required Future<void> Function() onChanged,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  builder: (_) => _TagPanel(repository: repository, onChanged: onChanged),
);

/// Assignments are persisted immediately; leaving the editor never implies save.
class RecordTagEditor extends StatefulWidget {
  const RecordTagEditor({
    super.key,
    required this.repository,
    required this.recordId,
    required this.type,
    required this.onChanged,
  });
  final TagRepository repository;
  final String recordId;
  final TaggableType type;
  final Future<void> Function() onChanged;

  @override
  State<RecordTagEditor> createState() => _RecordTagEditorState();
}

class _RecordTagEditorState extends State<RecordTagEditor> {
  int _revision = 0;

  @override
  Widget build(BuildContext context) => _TagPanel(
    key: ValueKey(_revision),
    repository: widget.repository,
    recordId: widget.recordId,
    type: widget.type,
    onChanged: widget.onChanged,
    onManage: () async {
      await showTagManager(
        context,
        repository: widget.repository,
        onChanged: widget.onChanged,
      );
      if (mounted) setState(() => _revision++);
    },
  );
}

class _TagPanel extends StatefulWidget {
  const _TagPanel({
    super.key,
    required this.repository,
    required this.onChanged,
    this.recordId,
    this.type,
    this.onManage,
  });
  final TagRepository repository;
  final Future<void> Function() onChanged;
  final String? recordId;
  final TaggableType? type;
  final VoidCallback? onManage;

  @override
  State<_TagPanel> createState() => _TagPanelState();
}

class _TagPanelState extends State<_TagPanel> {
  final _label = TextEditingController();
  List<Tag> _tags = [];
  Set<StableId> _assigned = {};
  bool _loading = true;
  bool _busy = false;
  String? _error;
  bool get _manager => widget.recordId == null;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _label.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (mounted) setState(() => _loading = true);
    try {
      final tags = await widget.repository.list();
      final assigned = _manager
          ? <StableId>{}
          : await widget.repository.tagsFor(widget.recordId!, widget.type!);
      _tags = tags;
      _assigned = assigned;
      _loading = false;
      _error = null;
      if (mounted) setState(() {});
    } catch (_) {
      _loading = false;
      _error = PersianCopy.tagControlsLoadMessage;
      if (mounted) setState(() {});
    }
  }

  Future<void> _mutate(Future<void> Function() action) async {
    if (_busy || _loading) return;
    _busy = true;
    _error = null;
    if (mounted) setState(() {});
    var committed = false;
    try {
      await action();
      committed = true;
      await widget.onChanged();
      await _load();
      if (mounted && _error == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(PersianCopy.tagControlsMutateContent)),
        );
      }
    } catch (_) {
      _error = committed
          ? PersianCopy.tagControlsMutateMessage
          : PersianCopy.tagControlsMutateMessage2;
      if (mounted) setState(() {});
    } finally {
      _busy = false;
      if (mounted) setState(() {});
    }
  }

  Future<void> _create([String? label]) => _mutate(() async {
    final tag = await widget.repository.getOrCreate(label ?? _label.text);
    if (!_manager) {
      await widget.repository.attach(
        recordId: widget.recordId!,
        tag: tag,
        type: widget.type!,
      );
    }
    if (mounted) _label.clear();
  });

  Future<void> _rename(Tag tag) async {
    final controller = TextEditingController(text: tag.label);
    Future<void>? removed;
    final label = await showDialog<String>(
      context: context,
      builder: (context) {
        removed ??= ModalRoute.of(context)!.completed.then((_) {});
        return AlertDialog(
          title: const Text(PersianCopy.tagControlsLabelTitle),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: PersianCopy.tagControlsLabelLabelText,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(PersianCopy.commonCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: const Text(PersianCopy.commonSave),
            ),
          ],
        );
      },
    );
    if (removed != null) await removed;
    controller.dispose();
    if (label == null || !mounted) return;
    await _mutate(() async {
      await widget.repository.rename(tag.id, label);
    });
  }

  Future<void> _remove(Tag tag) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(PersianCopy.tagControlsConfirmedTitle),
        content: Text(
          PersianCopy.tagControlsConfirmedContent(
            (tag.displayLabel).toString(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(PersianCopy.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(PersianCopy.tagControlsConfirmedActions),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await _mutate(() => widget.repository.remove(tag.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_manager) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(planActL10n(context).tagControlsContentChildren3),
          if (_loading || _busy) const LinearProgressIndicator(),
          if (_error != null) Text(_error!),
          CompactTagSelection(
            title: planActL10n(context).tagControlsContentChildren2,
            labels: _tags
                .where((tag) => _assigned.contains(tag.id))
                .map((tag) => tag.label),
            enabled: !_loading && !_busy,
            onOpen: () => showTagSelection(
              context,
              labels: () => _tags.map((tag) => tag.label).toList(),
              selected: (label) => _tags.any(
                (tag) => tag.label == label && _assigned.contains(tag.id),
              ),
              description: planActL10n(context).tagControlsContentChildren3,
              error: () => _error,
              onRetry: () => _mutate(() async {}),
              onCreate: (label) => _create(label),
              onToggle: (label, selected) => _mutate(() async {
                final tag = _tags.firstWhere((tag) => tag.label == label);
                if (selected) {
                  await widget.repository.attach(
                    recordId: widget.recordId!,
                    tag: tag,
                    type: widget.type!,
                  );
                  _assigned = {..._assigned, tag.id};
                } else {
                  await widget.repository.detach(
                    recordId: widget.recordId!,
                    tag: tag,
                    type: widget.type!,
                  );
                  _assigned = {..._assigned}..remove(tag.id);
                }
              }),
            ),
          ),
          if (_error != null)
            TextButton(
              onPressed: _busy ? null : _load,
              child: Text(planActL10n(context).commonRetry),
            ),
          if (widget.onManage != null)
            TextButton(
              onPressed: _busy || _loading ? null : widget.onManage,
              child: Text(planActL10n(context).tagControlsContentChildren),
            ),
        ],
      );
    }
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          planActL10n(context).tagControlsContentChildren,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: PlanActSpacing.sm),
        if (_loading || _busy) const LinearProgressIndicator(),
        if (_error != null) ...[
          Text(
            _error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
          TextButton(
            onPressed: _busy ? null : () => _mutate(() async {}),
            child: Text(planActL10n(context).commonRetry),
          ),
        ],
        if (!_loading && _error == null && _tags.isEmpty)
          Text(planActL10n(context).tagControlsContentChildren4),
        for (final tag in _tags)
          ListTile(
            title: Text(tag.displayLabel),
            trailing: Wrap(
              children: [
                IconButton(
                  tooltip: planActL10n(
                    context,
                  ).tagControlsContentTooltip3((tag.displayLabel).toString()),
                  onPressed: _busy ? null : () => _rename(tag),
                  icon: const Icon(Icons.edit_outlined),
                ),
                IconButton(
                  tooltip: planActL10n(
                    context,
                  ).tagControlsContentTooltip4((tag.displayLabel).toString()),
                  onPressed: _busy ? null : () => _remove(tag),
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
          ),
        const SizedBox(height: PlanActSpacing.sm),
        TextField(
          controller: _label,
          enabled: !_busy && !_loading,
          decoration: InputDecoration(
            labelText: planActL10n(context).tagControlsBuildLabelText,
          ),
          onSubmitted: (_) => _create(),
        ),
        const SizedBox(height: PlanActSpacing.sm),
        OutlinedButton.icon(
          onPressed: _busy || _loading ? null : _create,
          icon: const Icon(Icons.add),
          label: Text(planActL10n(context).tagControlsContentLabel),
        ),
        if (widget.onManage != null)
          TextButton(
            onPressed: _busy || _loading ? null : widget.onManage,
            child: Text(planActL10n(context).tagControlsContentChildren),
          ),
      ],
    );
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsetsDirectional.only(
          start: PlanActSpacing.page,
          end: PlanActSpacing.page,
          top: PlanActSpacing.lg,
          bottom: MediaQuery.viewInsetsOf(context).bottom + PlanActSpacing.lg,
        ),
        child: content,
      ),
    );
  }
}
