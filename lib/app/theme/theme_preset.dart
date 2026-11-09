/// Stable persisted identifiers; display mode is an independent preference.
enum ThemePreset {
  original('original'),
  blue('blue'),
  purple('purple'),
  earth('earth');

  const ThemePreset(this.storageValue);
  final String storageValue;

  static ThemePreset fromStorage(String? value) =>
      ThemePreset.values.firstWhere(
        (preset) => preset.storageValue == value,
        orElse: () => ThemePreset.original,
      );
}
