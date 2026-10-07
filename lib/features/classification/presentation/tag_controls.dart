import 'package:flutter/material.dart';
import 'package:planact/app/theme/planact_spacing.dart';
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/features/classification/application/tag_repository.dart';
import 'package:planact/features/classification/domain/tag.dart';

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
  final _label = TextEditingController();
  List<Tag> _tags = [];
  bool _loading = false;
  String? _error;

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
          _error = 'خواندن برچسب‌ها انجام نشد؛ دوباره تلاش کنید.';
        });
      }
    }
  }

  void _toggle(String label, bool selected) {
    final key = normalizeTagKey(label);
    final labels = {...widget.selected}
      ..removeWhere((value) => normalizeTagKey(value) == key);
    if (selected) labels.add(label);
    widget.onChanged(Set.unmodifiable(labels));
  }

  void _add() {
    if (!widget.enabled) return;
    final label = normalizeTagLabel(_label.text);
    if (label.isEmpty) {
      setState(() => _error = 'نام برچسب را وارد کنید.');
      return;
    }
    final existing = _tags
        .where((tag) => tag.normalizedLabel == normalizeTagKey(label))
        .firstOrNull;
    _toggle(existing?.label ?? label, true);
    _label.clear();
    setState(() => _error = null);
  }

  @override
  Widget build(BuildContext context) {
    final labels = <String, String>{
      for (final tag in _tags) tag.normalizedLabel: tag.label,
      for (final label in widget.selected) normalizeTagKey(label): label,
    };
    final selected = widget.selected.map(normalizeTagKey).toSet();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'برچسب‌ها (اختیاری)',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const Text(
          'برچسب‌ها همراه با ثبت نهایی ذخیره می‌شوند؛ انصراف تغییری ایجاد نمی‌کند.',
        ),
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
            child: const Text('تلاش دوباره'),
          ),
        ],
        Wrap(
          spacing: PlanActSpacing.sm,
          runSpacing: PlanActSpacing.xs,
          children: [
            for (final entry in labels.entries)
              FilterChip(
                label: Text('#${entry.value}'),
                selected: selected.contains(entry.key),
                onSelected: widget.enabled
                    ? (value) => _toggle(entry.value, value)
                    : null,
              ),
          ],
        ),
        const SizedBox(height: PlanActSpacing.sm),
        TextField(
          key: const ValueKey('draft-tag-label'),
          controller: _label,
          enabled: widget.enabled,
          decoration: const InputDecoration(labelText: 'برچسب جدید'),
          onSubmitted: (_) => _add(),
        ),
        OutlinedButton.icon(
          onPressed: widget.enabled ? _add : null,
          icon: const Icon(Icons.add),
          label: const Text('افزودن برچسب به پیش‌نویس'),
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
  Widget build(BuildContext context) => Wrap(
    spacing: PlanActSpacing.sm,
    runSpacing: PlanActSpacing.xs,
    children: [
      FilterChip(
        label: const Text('همهٔ برچسب‌ها'),
        selected: selected == null,
        onSelected: enabled ? (_) => onChanged(null) : null,
      ),
      for (final tag in tags)
        FilterChip(
          label: Text(tag.displayLabel),
          selected: selected == tag.id,
          onSelected: enabled
              ? (value) => onChanged(value ? tag.id : null)
              : null,
        ),
    ],
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
      if (mounted) {
        setState(() {
          _tags = tags;
          _assigned = assigned;
          _loading = false;
          _error = null;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'خواندن برچسب‌ها انجام نشد؛ دوباره تلاش کنید.';
        });
      }
    }
  }

  Future<void> _mutate(Future<void> Function() action) async {
    if (_busy || _loading) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    var committed = false;
    try {
      await action();
      committed = true;
      await widget.onChanged();
      await _load();
      if (mounted && _error == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('برچسب‌ها به‌روز شدند.')));
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = committed
              ? 'تغییر ذخیره شد؛ نمایش اطلاعات به‌روز نشد. دوباره تلاش کنید.'
              : 'تغییر برچسب انجام نشد؛ نام تکراری یا نامعتبر را بررسی و دوباره تلاش کنید.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _create() => _mutate(() async {
    final tag = await widget.repository.getOrCreate(_label.text);
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
          title: const Text('تغییر نام برچسب'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'نام برچسب'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('انصراف'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: const Text('ذخیره'),
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
        title: const Text('حذف برچسب از همهٔ موارد؟'),
        content: Text(
          'برچسب ${tag.displayLabel} و اتصال آن به همهٔ تعهدها و تراکنش‌ها حذف می‌شود. خود تعهدها و تراکنش‌ها باقی می‌مانند. این کار قابل بازگردانی نیست.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('انصراف'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('حذف از همهٔ موارد'),
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
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _manager ? 'مدیریت برچسب‌ها' : 'برچسب‌های این مورد',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: PlanActSpacing.sm),
        if (!_manager)
          const Text(
            'تغییر برچسب‌ها بلافاصله ذخیره می‌شود؛ نیازی به ذخیرهٔ فرم نیست.',
          ),
        if (_loading || _busy) const LinearProgressIndicator(),
        if (_error != null) ...[
          Text(
            _error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
          TextButton(
            onPressed: _busy ? null : () => _mutate(() async {}),
            child: const Text('تلاش دوباره'),
          ),
        ],
        if (!_loading && _error == null && _tags.isEmpty)
          const Text('هنوز برچسبی ندارید؛ یک برچسب بسازید.'),
        if (!_manager)
          Wrap(
            spacing: PlanActSpacing.sm,
            runSpacing: PlanActSpacing.xs,
            children: [
              for (final tag in _tags)
                FilterChip(
                  label: Text(tag.displayLabel),
                  selected: _assigned.contains(tag.id),
                  tooltip: _assigned.contains(tag.id)
                      ? 'برداشتن از این مورد'
                      : 'افزودن به این مورد',
                  onSelected: _busy || _loading
                      ? null
                      : (selected) => _mutate(
                          () => selected
                              ? widget.repository.attach(
                                  recordId: widget.recordId!,
                                  tag: tag,
                                  type: widget.type!,
                                )
                              : widget.repository.detach(
                                  recordId: widget.recordId!,
                                  tag: tag,
                                  type: widget.type!,
                                ),
                        ),
                ),
            ],
          )
        else
          for (final tag in _tags)
            ListTile(
              title: Text(tag.displayLabel),
              trailing: Wrap(
                children: [
                  IconButton(
                    tooltip: 'تغییر نام ${tag.displayLabel}',
                    onPressed: _busy ? null : () => _rename(tag),
                    icon: const Icon(Icons.edit_outlined),
                  ),
                  IconButton(
                    tooltip: 'حذف سراسری ${tag.displayLabel}',
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
          decoration: const InputDecoration(labelText: 'برچسب جدید'),
          onSubmitted: (_) => _create(),
        ),
        const SizedBox(height: PlanActSpacing.sm),
        OutlinedButton.icon(
          onPressed: _busy || _loading ? null : _create,
          icon: const Icon(Icons.add),
          label: Text(_manager ? 'ساخت برچسب' : 'ساخت و افزودن برچسب'),
        ),
        if (widget.onManage != null)
          TextButton(
            onPressed: _busy || _loading ? null : widget.onManage,
            child: const Text('مدیریت برچسب‌ها'),
          ),
      ],
    );
    if (!_manager) return content;
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
