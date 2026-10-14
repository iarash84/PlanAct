import 'package:planact/core/localization/planact_localizations.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:planact/app/theme/planact_radius.dart';
import 'package:planact/app/theme/planact_spacing.dart';
import 'package:planact/core/localization/persian_numbers.dart';

class AboutPage extends StatefulWidget {
  const AboutPage({super.key, this.loadPackageInfo = PackageInfo.fromPlatform});

  final Future<PackageInfo> Function() loadPackageInfo;

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  static bool _licenseRegistered = false;
  late Future<PackageInfo> _packageInfo;

  @override
  void initState() {
    super.initState();
    _packageInfo = widget.loadPackageInfo();
    if (!_licenseRegistered) {
      LicenseRegistry.addLicense(() async* {
        final text = await rootBundle.loadString('assets/licenses/planact.txt');
        yield LicenseEntryWithLineBreaks(['PlanAct'], text);
      });
      _licenseRegistered = true;
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(planActL10n(context).settingsAboutApp)),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: PlanActSpacing.contentWidth,
        ),
        child: ListView(
          padding: const EdgeInsets.all(PlanActSpacing.page),
          children: [
            Center(
              child: ClipRRect(
                borderRadius: PlanActRadius.card,
                child: Image.asset(
                  'assets/icons/app_icon.png',
                  width: 96,
                  height: 96,
                  semanticLabel: planActL10n(context)
                      .aboutPageBuildSemanticLabel,
                ),
              ),
            ),
            const SizedBox(height: PlanActSpacing.lg),
            Text(
              planActL10n(context).appName,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: PlanActSpacing.sm),
            Text(
              planActL10n(context).aboutPageBuildChildren,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: PlanActSpacing.xl),
            _AboutSection(
              title: planActL10n(context).aboutPageBuildTitle,
              text: planActL10n(context).aboutPageBuildText,
            ),
            _AboutSection(
              title: planActL10n(context).aboutPageBuildTitle2,
              text: planActL10n(context).aboutPageBuildText2,
            ),
            _AboutSection(
              title: planActL10n(context).aboutPageBuildTitle3,
              text: planActL10n(context).aboutPageBuildText3,
            ),
            _AboutSection(
              title: planActL10n(context).backupSettingsCardBuildTitle,
              text: planActL10n(context).aboutPageBuildText4,
            ),
            _AboutSection(
              title: planActL10n(context).aboutPageBuildTitle4,
              text: planActL10n(context).aboutPageBuildText5,
            ),
            FutureBuilder<PackageInfo>(
              future: _packageInfo,
              builder: (context, snapshot) {
                final info = snapshot.data;
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(PlanActSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          planActL10n(context).aboutPageBuildChildren2,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: PlanActSpacing.sm),
                        if (snapshot.hasError) ...[
                          Semantics(
                            liveRegion: true,
                            child: Text(
                              planActL10n(context).aboutPageBuildChildren3,
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () => setState(() {
                              _packageInfo = widget.loadPackageInfo();
                            }),
                            icon: const Icon(Icons.refresh),
                            label: Text(planActL10n(context).commonRetry),
                          ),
                        ] else if (info == null)
                          Text(planActL10n(context).aboutPageBuildChildren4)
                        else
                          Text(
                            planActL10n(context).aboutPageBuildChildren5(
                              (PersianNumbers.format(info.version)).toString(),
                              (info.buildNumber.isEmpty
                                      ? planActL10n(context).commonUnknown
                                      : PersianNumbers.format(info.buildNumber))
                                  .toString(),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: PlanActSpacing.xl),
            _AboutSection(
              title: planActL10n(context).aboutPageBuildTitle5,
              text: planActL10n(context).aboutPageBuildText6,
            ),
            OutlinedButton.icon(
              onPressed: () => showLicensePage(
                context: context,
                applicationName: planActL10n(context).appName,
              ),
              icon: const Icon(Icons.description_outlined),
              label: Text(planActL10n(context).aboutPageBuildLabel),
            ),
          ],
        ),
      ),
    ),
  );
}

class _AboutSection extends StatelessWidget {
  const _AboutSection({required this.title, required this.text});
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: PlanActSpacing.xl),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: PlanActSpacing.sm),
        Text(text),
      ],
    ),
  );
}
