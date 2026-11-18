import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:planact/app/theme/planact_spacing.dart';
import 'package:planact/core/localization/persian_numbers.dart';
import 'package:planact/core/localization/planact_localizations.dart';

/// Read-only installation metadata; rebuilding the parent does not reload it.
class AppVersionInfo extends StatefulWidget {
  const AppVersionInfo({
    super.key,
    this.loadPackageInfo = PackageInfo.fromPlatform,
  });

  final Future<PackageInfo> Function() loadPackageInfo;

  @override
  State<AppVersionInfo> createState() => _AppVersionInfoState();
}

class _AppVersionInfoState extends State<AppVersionInfo> {
  late Future<PackageInfo> _info;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _info = Future.sync(widget.loadPackageInfo);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = planActL10n(context);
    return FutureBuilder<PackageInfo>(
      future: _info,
      builder: (context, snapshot) {
        final info = snapshot.data;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.aboutPageBuildChildren2,
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: PlanActSpacing.xs),
            if (snapshot.hasError) ...[
              Semantics(
                liveRegion: true,
                child: Text(l10n.aboutPageBuildChildren3),
              ),
              TextButton.icon(
                onPressed: () => setState(_load),
                icon: const Icon(Icons.refresh),
                label: Text(l10n.commonRetry),
              ),
            ] else
              Text(
                info == null
                    ? l10n.aboutPageBuildChildren4
                    : l10n.aboutPageBuildChildren5(
                        PersianNumbers.format(info.version),
                        info.buildNumber.isEmpty
                            ? l10n.commonUnknown
                            : PersianNumbers.format(info.buildNumber),
                      ),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        );
      },
    );
  }
}
