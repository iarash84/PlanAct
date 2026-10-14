import 'package:planact/core/localization/planact_localizations.dart';
import 'package:planact/core/localization/persian_copy.g.dart';
import 'package:flutter/material.dart';
import 'package:planact/app/theme/planact_spacing.dart';
import 'package:planact/core/localization/persian_numbers.dart';
import 'package:planact/features/calendar/application/holiday_package_service.dart';
import 'package:planact/features/calendar/domain/holiday_data_package.dart';

class HolidayPackageSettingsCard extends StatefulWidget {
  const HolidayPackageSettingsCard({
    super.key,
    required this.service,
    required this.onInstalled,
  });
  final HolidayPackageService service;
  final VoidCallback onInstalled;
  @override
  State<HolidayPackageSettingsCard> createState() =>
      _HolidayPackageSettingsCardState();
}

class _HolidayPackageSettingsCardState
    extends State<HolidayPackageSettingsCard> {
  bool _busy = false;
  String? _message;

  Future<void> _import() async {
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final package = await widget.service.prepare();
      if (!mounted || package == null) return;
      final first = widget.service.needsPublisherApproval(package);
      final approved = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text(
            PersianCopy.holidayPackageSettingsCardApprovedTitle,
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  PersianCopy.holidayPackageSettingsCardApprovedChildren(
                    (PersianNumbers.format(package.year)).toString(),
                    (PersianNumbers.format(package.revision)).toString(),
                  ),
                ),
                Text(
                  PersianCopy.holidayPackageSettingsCardApprovedChildren2(
                    (package.source).toString(),
                  ),
                ),
                const Text(
                  PersianCopy.holidayPackageSettingsCardApprovedChildren3,
                ),
                SelectableText(
                  package.fingerprint,
                  textDirection: TextDirection.ltr,
                ),
                Text(
                  first
                      ? PersianCopy.holidayPackageSettingsCardApprovedChildren4
                      : PersianCopy.holidayPackageSettingsCardApprovedChildren5,
                ),
                const Text(
                  PersianCopy.holidayPackageSettingsCardApprovedChildren6,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text(PersianCopy.commonCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(
                first
                    ? PersianCopy.holidayPackageSettingsCardApprovedActions
                    : PersianCopy.holidayPackageSettingsCardApprovedActions2,
              ),
            ),
          ],
        ),
      );
      if (!mounted || approved != true) return;
      await widget.service.install(
        package,
        publisherApproved: approved == true,
      );
      if (!mounted) return;
      setState(
        () => _message = PersianCopy.holidayPackageSettingsCardImportMessage,
      );
      widget.onInstalled();
    } on HolidayPackageException catch (error) {
      if (mounted) setState(() => _message = error.message);
    } catch (_) {
      if (mounted) {
        setState(
          () => _message = PersianCopy.holidayPackageSettingsCardImportMessage2,
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Card(
    child: Column(
      children: [
        ListTile(
          leading: const Icon(Icons.event_available_outlined),
          title: Text(
            planActL10n(context).holidayPackageSettingsCardBuildTitle,
          ),
          subtitle: Text(
            widget.service.packages.isEmpty
                ? planActL10n(context).holidayPackageSettingsCardBuildSubtitle
                : planActL10n(context).holidayPackageSettingsCardBuildSubtitle2(
                    (widget.service.packages
                            .map((p) => PersianNumbers.format(p.year))
                            .join(planActL10n(context).commonListSeparator))
                        .toString(),
                  ),
          ),
        ),
        if (widget.service.loadError != null)
          Padding(
            padding: const EdgeInsets.all(PlanActSpacing.lg),
            child: Text(widget.service.loadError!),
          ),
        if (_message != null)
          Padding(
            padding: const EdgeInsets.all(PlanActSpacing.lg),
            child: Text(_message!, semanticsLabel: _message),
          ),
        Padding(
          padding: const EdgeInsets.all(PlanActSpacing.lg),
          child: FilledButton.tonalIcon(
            onPressed: _busy ? null : _import,
            icon: _busy
                ? CircularProgressIndicator(
                    semanticsLabel: planActL10n(context)
                        .holidayPackageSettingsCardBuildSemanticsLabel,
                  )
                : const Icon(Icons.file_open_outlined),
            label: Text(
              _busy
                  ? planActL10n(context).holidayPackageSettingsCardBuildLabel
                  : planActL10n(context).holidayPackageSettingsCardBuildLabel2,
            ),
          ),
        ),
      ],
    ),
  );
}
