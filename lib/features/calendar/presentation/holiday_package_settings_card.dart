import 'package:planact/core/localization/planact_localizations.dart';
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
    final l10n = planActL10n(context);
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
          title: Text(l10n.holidayPackageSettingsCardApprovedTitle),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.holidayPackageSettingsCardApprovedChildren(
                    (PersianNumbers.format(package.year)).toString(),
                    (PersianNumbers.format(package.revision)).toString(),
                  ),
                ),
                Text(
                  l10n.holidayPackageSettingsCardApprovedChildren2(
                    (package.source).toString(),
                  ),
                ),
                Text(l10n.holidayPackageSettingsCardApprovedChildren3),
                SelectableText(
                  package.fingerprint,
                  textDirection: TextDirection.ltr,
                ),
                Text(
                  first
                      ? l10n.holidayPackageSettingsCardApprovedChildren4
                      : l10n.holidayPackageSettingsCardApprovedChildren5,
                ),
                Text(l10n.holidayPackageSettingsCardApprovedChildren6),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.commonCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(
                first
                    ? l10n.holidayPackageSettingsCardApprovedActions
                    : l10n.holidayPackageSettingsCardApprovedActions2,
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
      setState(() => _message = l10n.holidayPackageSettingsCardImportMessage);
      widget.onInstalled();
    } on HolidayPackageException catch (error) {
      if (mounted) setState(() => _message = error.message);
    } catch (_) {
      if (mounted) {
        setState(
          () => _message = l10n.holidayPackageSettingsCardImportMessage2,
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
            planActL10n(context).holidayPackageSettingsCardBuildSubtitle,
          ),
        ),
        ExpansionTile(
          title: Text(planActL10n(context).holidayDataCoverageTitle),
          subtitle: Text(
            planActL10n(context).holidayDataCoveredYears(
              widget.service.calendars
                  .map((data) => PersianNumbers.format(data.year))
                  .join(planActL10n(context).commonListSeparator),
            ),
          ),
          children: [
            for (final data in widget.service.calendars)
              ListTile(
                title: Text(
                  planActL10n(context).holidayDataYearOrigin(
                    PersianNumbers.format(data.year),
                    data.imported
                        ? planActL10n(context).holidayDataOriginImported
                        : planActL10n(context).holidayDataOriginBundled,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      planActL10n(context).holidayDataRevision(
                        PersianNumbers.format(data.revision),
                      ),
                    ),
                    Text(data.source, textDirection: TextDirection.ltr),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(PlanActSpacing.lg),
              child: Text(planActL10n(context).holidayDataMissingCoverage),
            ),
          ],
        ),
        if (widget.service.loadError != null)
          Padding(
            padding: const EdgeInsets.all(PlanActSpacing.lg),
            child: Text(widget.service.loadError!),
          ),
        if (_message != null)
          Padding(
            padding: const EdgeInsets.all(PlanActSpacing.lg),
            child: Semantics(liveRegion: true, child: Text(_message!)),
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
