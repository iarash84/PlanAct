import 'package:flutter/widgets.dart';
import 'package:planact/features/calendar/domain/holiday_provider.dart';

/// Root-scoped read seam, including pushed routes and modal date pickers.
/// Resolves fresh validated package state when a picker is opened.
class HolidayProviderScope extends InheritedWidget {
  const HolidayProviderScope({
    super.key,
    required this.readProvider,
    required super.child,
  });

  final IranianHolidayProvider Function() readProvider;

  static IranianHolidayProvider of(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<HolidayProviderScope>()
          ?.readProvider() ??
      const IranianHolidayProvider();

  @override
  bool updateShouldNotify(HolidayProviderScope oldWidget) =>
      readProvider != oldWidget.readProvider;
}
