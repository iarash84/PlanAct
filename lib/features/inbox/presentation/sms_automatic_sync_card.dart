import 'package:flutter/material.dart';
import 'package:planact/app/theme/planact_spacing.dart';
import 'package:planact/core/localization/planact_localizations.dart';
import 'package:planact/features/inbox/presentation/sms_sync_controller.dart';

class SmsAutomaticSyncCard extends StatelessWidget {
  const SmsAutomaticSyncCard({super.key, required this.controller});
  final SmsSyncController controller;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) => Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SwitchListTile(
            title: Text(planActL10n(context).smsAutomaticTitle),
            value: controller.enabled,
            onChanged:
                controller.ready &&
                    !controller.changing &&
                    (controller.enabled || controller.access == true)
                ? controller.setEnabled
                : null,
          ),
          Padding(
            padding: const EdgeInsets.all(PlanActSpacing.md),
            child: Text(planActL10n(context).smsAutomaticDescription),
          ),
          if (controller.busy) const LinearProgressIndicator(),
          if (controller.error != null)
            ListTile(
              title: Semantics(
                liveRegion: true,
                child: Text(controller.error!),
              ),
              trailing: IconButton(
                tooltip: planActL10n(context).commonRetry,
                onPressed: controller.busy
                    ? null
                    : () => controller.refresh(checkAccess: true),
                icon: const Icon(Icons.refresh),
              ),
            ),
        ],
      ),
    ),
  );
}
