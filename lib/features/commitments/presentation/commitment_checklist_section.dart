import 'package:flutter/material.dart';
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/core/localization/persian_numbers.dart';
import 'package:planact/core/localization/planact_localizations.dart';
import 'package:planact/core/presentation/planact_state_message.dart';
import 'package:planact/core/presentation/undo_feedback.dart';
import 'package:planact/features/commitments/application/checklist_repository.dart';
import 'package:planact/features/commitments/domain/commitment_checklist.dart';

/// Inline, commitment-owned checklist editor used by Details and the full
/// checklist route. Item changes are explicit durable commands; checking an
/// item never changes the commitment lifecycle.
class CommitmentChecklistSection extends StatefulWidget {
  const CommitmentChecklistSection({
    super.key,
    required this.repository,
    required this.commitmentId,
    this.onChanged,
    this.showScope = true,
  });

  final ChecklistRepository repository;
  final StableId commitmentId;
  final Future<void> Function()? onChanged;
  final bool showScope;

  @override
  State<CommitmentChecklistSection> createState() =>
      _CommitmentChecklistSectionState();
}

class _CommitmentChecklistSectionState
    extends State<CommitmentChecklistSection> {
  ChecklistSnapshot? _snapshot;
  bool _loading = true;
  bool _busy = false;
  bool _readFailed = false;
  bool _writeFailed = false;
  int _readRevision = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final request = ++_readRevision;
    if (mounted) setState(() => _loading = true);
    try {
      final snapshot = await widget.repository.load(widget.commitmentId);
      if (!mounted || request != _readRevision) return;
      setState(() {
        _snapshot = snapshot;
        _readFailed = false;
        _writeFailed = false;
      });
    } catch (_) {
      if (mounted && request == _readRevision) {
        setState(() => _readFailed = true);
      }
    } finally {
      if (mounted && request == _readRevision) {
        setState(() => _loading = false);
      }
    }
  }

  Future<bool> _save(CommitmentChecklist next) async {
    final snapshot = _snapshot;
    if (_busy || _loading || _readFailed || _writeFailed || snapshot == null) {
      return false;
    }
    setState(() => _busy = true);
    var committed = false;
    try {
      await SaveChecklist(widget.repository)(
        next,
        expectedRevision: snapshot.list.revision,
      );
      committed = true;
    } catch (_) {
      if (mounted) setState(() => _writeFailed = true);
      return false;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
    if (committed && mounted) {
      try {
        await widget.onChanged?.call();
      } catch (_) {
        // The checklist write is already durable; reload it independently.
      }
      await _load();
    }
    return true;
  }

  Future<void> _edit([ChecklistItem? item]) async {
    final controller = TextEditingController(text: item?.title ?? '');
    var saving = false;
    var failed = false;
    var empty = false;
    final list = _snapshot!.list;
    final route = DialogRoute<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          final l10n = planActL10n(context);
          return PopScope(
            canPop: !saving,
            child: AlertDialog(
              scrollable: true,
              title: Text(
                item == null ? l10n.checklistAdd : l10n.checklistEdit,
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    key: const ValueKey('checklist-item-title'),
                    controller: controller,
                    autofocus: true,
                    enabled: !saving,
                    decoration: InputDecoration(
                      labelText: l10n.checklistItemTitle,
                      errorText: empty ? l10n.checklistEmptyTitle : null,
                    ),
                  ),
                  if (failed) Text(l10n.checklistSaveError),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: saving ? null : () => Navigator.pop(dialogContext),
                  child: Text(l10n.commonCancel),
                ),
                FilledButton(
                  key: const ValueKey('checklist-item-save'),
                  onPressed: saving || failed
                      ? null
                      : () async {
                          if (controller.text.trim().isEmpty) {
                            setDialogState(() => empty = true);
                            return;
                          }
                          setDialogState(() => saving = true);
                          final next = item == null
                              ? list.add(controller.text)
                              : list.change(item.id, title: controller.text);
                          final saved = await _save(next);
                          if (!dialogContext.mounted) return;
                          if (saved) {
                            Navigator.pop(dialogContext);
                          } else {
                            setDialogState(() {
                              saving = false;
                              failed = true;
                            });
                          }
                        },
                  child: Text(l10n.commonSave),
                ),
              ],
            ),
          );
        },
      ),
    );
    await Navigator.of(context).push(route);
    await route.completed;
    controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = planActL10n(context);
    final snapshot = _snapshot;
    final items = snapshot?.list.items ?? const <ChecklistItem>[];
    final active = items.where((item) => !item.removed).toList();
    final orderedActive = [
      ...active.where((item) => !item.checked),
      ...active.where((item) => item.checked),
    ];
    final editable =
        snapshot?.editable == true &&
        !_busy &&
        !_loading &&
        !_readFailed &&
        !_writeFailed;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.checklistTitle,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        if (widget.showScope) Text(l10n.checklistScope),
        if (_loading || _busy) const LinearProgressIndicator(),
        if (_readFailed || _writeFailed)
          PlanActStateMessage(
            isError: true,
            message: _writeFailed
                ? l10n.checklistSaveError
                : l10n.checklistReadError,
            action: TextButton(
              onPressed: _busy || _loading ? null : _load,
              child: Text(l10n.commonRetry),
            ),
          ),
        if (snapshot != null) ...[
          if (!snapshot.editable) Text(l10n.checklistReadOnly),
          Text(
            l10n.checklistProgress(
              PersianNumbers.format(
                active.where((item) => item.checked).length,
              ),
              PersianNumbers.format(active.length),
            ),
          ),
          if (active.isEmpty) Text(l10n.checklistEmpty),
          for (final item in orderedActive) _itemRow(item, editable),
          FilledButton.icon(
            key: const ValueKey('checklist-add'),
            onPressed: editable ? () => _edit() : null,
            icon: const Icon(Icons.add),
            label: Text(l10n.checklistAdd),
          ),
          if (items.any((item) => item.removed))
            ExpansionTile(
              title: Text(l10n.checklistRemoved),
              children: [
                for (final item in items.where((item) => item.removed))
                  ListTile(
                    title: Text(item.title),
                    trailing: IconButton(
                      tooltip: l10n.checklistRestore,
                      onPressed: !editable
                          ? null
                          : () => _save(
                              snapshot.list.change(item.id, removed: false),
                            ),
                      icon: const Icon(Icons.restore),
                    ),
                  ),
              ],
            ),
        ],
      ],
    );
  }

  Widget _itemRow(ChecklistItem item, bool editable) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(
        child: CheckboxListTile(
          key: ValueKey('checklist-item-${item.id.value}'),
          value: item.checked,
          onChanged: !editable
              ? null
              : (value) =>
                    _save(_snapshot!.list.change(item.id, checked: value)),
          title: Text(
            item.title,
            style: TextStyle(
              decoration: item.checked ? TextDecoration.lineThrough : null,
              color: item.checked
                  ? Theme.of(context).colorScheme.onSurfaceVariant
                  : null,
            ),
          ),
          controlAffinity: ListTileControlAffinity.leading,
        ),
      ),
      PopupMenuButton<String>(
        enabled: editable,
        tooltip: planActL10n(context).checklistActions,
        onSelected: (action) async {
          if (action == 'edit') {
            await _edit(item);
          } else if (await confirmRecordedAction(
                context,
                planActL10n(context).checklistRemoveConfirm,
              ) &&
              mounted) {
            await _save(_snapshot!.list.change(item.id, removed: true));
          }
        },
        itemBuilder: (_) => [
          PopupMenuItem(
            value: 'edit',
            child: Text(planActL10n(context).checklistEdit),
          ),
          PopupMenuItem(
            value: 'remove',
            child: Text(planActL10n(context).checklistRemove),
          ),
        ],
      ),
    ],
  );
}
