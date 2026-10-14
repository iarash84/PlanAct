import 'package:flutter/material.dart';
import 'package:planact/core/localization/planact_localizations.dart';

Future<bool> confirmRecordedAction(
  BuildContext context,
  String message,
) async =>
    await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(planActL10n(context).undoConfirmTitle),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(planActL10n(context).commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(planActL10n(context).financePageConfirmedActions),
          ),
        ],
      ),
    ) ??
    false;

void showRecordedActionFeedback(
  BuildContext context,
  String message, {
  VoidCallback? onUndo,
}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        action: onUndo == null
            ? null
            : SnackBarAction(
                label: planActL10n(context).undoAction,
                onPressed: onUndo,
              ),
      ),
    );
}
