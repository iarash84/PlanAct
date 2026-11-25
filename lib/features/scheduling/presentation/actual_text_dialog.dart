import 'package:flutter/material.dart';
import 'package:planact/app/theme/planact_spacing.dart';
import 'package:planact/core/localization/planact_localizations.dart';

/// Keeps the draft alive until the durable command succeeds or is cancelled.
class ActualTextDialog extends StatefulWidget {
  const ActualTextDialog({
    super.key,
    required this.title,
    required this.onSave,
    this.initialValue = '',
    this.optional = false,
    this.discard = false,
    this.onReload,
  });

  final String title;
  final String initialValue;
  final bool optional;
  final bool discard;
  final Future<void> Function(String? value) onSave;
  final Future<String?> Function()? onReload;

  @override
  State<ActualTextDialog> createState() => _ActualTextDialogState();
}

class _ActualTextDialogState extends State<ActualTextDialog> {
  late final _text = TextEditingController(text: widget.initialValue);
  bool _busy = false;
  bool _failed = false;
  String? _latest;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = planActL10n(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.actualTextConfirmTitle),
        content: SingleChildScrollView(
          child: Text(
            widget.discard
                ? l10n.actualTextDiscardMessage
                : l10n.actualTextConfirmMessage,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.commonSave),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _busy = true);
    try {
      final value = _text.text.trim();
      await widget.onSave(widget.discard || value.isEmpty ? null : value);
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _reload() async {
    setState(() => _busy = true);
    try {
      final latest = await widget.onReload!();
      if (mounted) {
        setState(() {
          _latest = latest ?? '';
          _failed = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = planActL10n(context);
    return PopScope(
      canPop: !_busy,
      child: AlertDialog(
        title: Text(widget.title),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (widget.discard)
                  Text(widget.initialValue)
                else
                  TextField(
                    key: const ValueKey('actual-text-input'),
                    controller: _text,
                    enabled: !_busy,
                    minLines: 3,
                    maxLines: null,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      labelText: widget.optional
                          ? l10n.actualOptionalNote
                          : l10n.actualTextLabel,
                    ),
                  ),
                if (_latest != null) ...[
                  const SizedBox(height: PlanActSpacing.md),
                  Text(l10n.actualTextLatest),
                  Text(_latest!),
                ],
                if (_failed) ...[
                  const SizedBox(height: PlanActSpacing.md),
                  Semantics(
                    liveRegion: true,
                    child: Text(l10n.actualTextSaveError),
                  ),
                  if (widget.onReload != null)
                    TextButton(
                      onPressed: _busy ? null : _reload,
                      child: Text(l10n.actualTextReload),
                    ),
                ],
                if (_busy) const LinearProgressIndicator(),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: _busy ? null : () => Navigator.pop(context, false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed:
                _busy ||
                    (!widget.optional &&
                        !widget.discard &&
                        _text.text.trim().isEmpty)
                ? null
                : _save,
            child: Text(l10n.commonSave),
          ),
        ],
      ),
    );
  }
}
