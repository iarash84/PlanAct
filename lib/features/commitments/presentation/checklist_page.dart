import 'package:flutter/material.dart';
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/core/localization/persian_numbers.dart';
import 'package:planact/core/localization/planact_localizations.dart';
import 'package:planact/core/presentation/planact_state_message.dart';
import 'package:planact/core/presentation/undo_feedback.dart';
import 'package:planact/app/theme/planact_spacing.dart';
import 'package:planact/features/commitments/application/checklist_repository.dart';
import 'package:planact/features/commitments/domain/commitment_checklist.dart';

class ChecklistPage extends StatefulWidget {
  const ChecklistPage({
    super.key,
    required this.repository,
    required this.commitmentId,
    required this.title,
  });
  final ChecklistRepository repository;
  final StableId commitmentId;
  final String title;

  @override
  State<ChecklistPage> createState() => _ChecklistPageState();
}

class _ChecklistPageState extends State<ChecklistPage> {
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
    final revision = ++_readRevision;
    setState(() => _loading = true);
    try {
      final snapshot = await widget.repository.load(widget.commitmentId);
      if (!mounted || revision != _readRevision) return;
      setState(() {
        _snapshot = snapshot;
        _readFailed = false;
        _writeFailed = false;
      });
    } catch (_) {
      if (mounted && revision == _readRevision) {
        setState(() => _readFailed = true);
      }
    } finally {
      if (mounted && revision == _readRevision) {
        setState(() => _loading = false);
      }
    }
  }

  Future<bool> _save(CommitmentChecklist next) async {
    if (_busy || _loading || _readFailed || _writeFailed) return false;
    setState(() => _busy = true);
    try {
      await SaveChecklist(widget.repository)(
        next,
        expectedRevision: _snapshot!.list.revision,
      );
    } catch (_) {
      if (mounted) setState(() => _writeFailed = true);
      return false;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
    // A committed write stays successful if the subsequent read fails.
    if (mounted) await _load();
    return true;
  }

  Future<void> _edit([ChecklistItem? item]) async {
    final controller = TextEditingController(text: item?.title ?? '');
    bool saving = false;
    bool failed = false;
    bool empty = false;
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
    final active = items.where((i) => !i.removed).toList();
    final editable =
        snapshot?.editable == true &&
        !_busy &&
        !_loading &&
        !_readFailed &&
        !_writeFailed;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.checklistTitle)),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: PlanActSpacing.contentWidth,
          ),
          child: ListView(
            padding: const EdgeInsets.all(PlanActSpacing.lg),
            children: [
              Text(widget.title, style: Theme.of(context).textTheme.titleLarge),
              Text(l10n.checklistScope),
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
                      active.where((i) => i.checked).length,
                    ),
                    PersianNumbers.format(active.length),
                  ),
                ),
                if (active.isEmpty) Text(l10n.checklistEmpty),
                for (final item in active)
                  Row(
                    children: [
                      Expanded(
                        child: CheckboxListTile(
                          key: ValueKey('checklist-item-${item.id.value}'),
                          value: item.checked,
                          onChanged: !editable
                              ? null
                              : (value) => _save(
                                  snapshot.list.change(item.id, checked: value),
                                ),
                          title: Text(
                            item.title,
                            style: TextStyle(
                              decoration: item.checked
                                  ? TextDecoration.lineThrough
                                  : null,
                              color: item.checked
                                  ? Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant
                                  : null,
                            ),
                          ),
                          controlAffinity: ListTileControlAffinity.leading,
                        ),
                      ),
                      PopupMenuButton<String>(
                        enabled: editable,
                        tooltip: l10n.checklistActions,
                        onSelected: (action) async {
                          if (action == 'edit') {
                            await _edit(item);
                          } else if (await confirmRecordedAction(
                                context,
                                l10n.checklistRemoveConfirm,
                              ) &&
                              mounted) {
                            await _save(
                              snapshot.list.change(item.id, removed: true),
                            );
                          }
                        },
                        itemBuilder: (_) => [
                          PopupMenuItem(
                            value: 'edit',
                            child: Text(l10n.checklistEdit),
                          ),
                          PopupMenuItem(
                            value: 'remove',
                            child: Text(l10n.checklistRemove),
                          ),
                        ],
                      ),
                    ],
                  ),
                FilledButton.icon(
                  key: const ValueKey('checklist-add'),
                  onPressed: editable ? () => _edit() : null,
                  icon: const Icon(Icons.add),
                  label: Text(l10n.checklistAdd),
                ),
                if (items.any((i) => i.removed))
                  ExpansionTile(
                    title: Text(l10n.checklistRemoved),
                    children: [
                      for (final item in items.where((i) => i.removed))
                        ListTile(
                          title: Text(item.title),
                          trailing: IconButton(
                            tooltip: l10n.checklistRestore,
                            onPressed: !editable
                                ? null
                                : () => _save(
                                    snapshot.list.change(
                                      item.id,
                                      removed: false,
                                    ),
                                  ),
                            icon: const Icon(Icons.restore),
                          ),
                        ),
                    ],
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
