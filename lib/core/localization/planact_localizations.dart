import 'package:flutter/widgets.dart';
import 'package:planact/l10n/generated/app_localizations.dart';
import 'package:planact/l10n/generated/app_localizations_fa.dart';

export 'package:planact/l10n/generated/app_localizations.dart';

final AppLocalizations _persian = AppLocalizationsFa();

/// Reads the route's resources. Isolated widgets without the application
/// delegate retain the existing documented Persian default.
/// No mutable global locale or persistent user data is introduced.
AppLocalizations planActL10n(BuildContext context) =>
    AppLocalizations.of(context) ?? _persian;
