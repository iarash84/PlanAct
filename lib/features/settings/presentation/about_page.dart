import 'package:planact/core/localization/planact_localizations.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:planact/app/theme/planact_radius.dart';
import 'package:planact/app/theme/planact_spacing.dart';

import 'app_version_info.dart';

class AboutPage extends StatefulWidget {
  const AboutPage({super.key, this.loadPackageInfo = PackageInfo.fromPlatform});

  final Future<PackageInfo> Function() loadPackageInfo;

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  static bool _licenseRegistered = false;

  @override
  void initState() {
    super.initState();
    if (!_licenseRegistered) {
      LicenseRegistry.addLicense(() async* {
        final text = await rootBundle.loadString('assets/licenses/planact.txt');
        yield LicenseEntryWithLineBreaks(['PlanAct'], text);
        final fontLicense = await rootBundle.loadString(
          'assets/fonts/vazirmatn/OFL.txt',
        );
        yield LicenseEntryWithLineBreaks(['Vazirmatn'], fontLicense);
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
            Card(
              child: Padding(
                padding: const EdgeInsets.all(PlanActSpacing.lg),
                child: AppVersionInfo(loadPackageInfo: widget.loadPackageInfo),
              ),
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
