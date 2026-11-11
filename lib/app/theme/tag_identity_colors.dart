import 'package:flutter/material.dart';
import 'package:planact/features/classification/domain/tag.dart';

/// Rebuildable identity, independent of list order, theme preset and runtime hash.
/// A name change deliberately derives the identity of the new normalized name.
abstract final class TagIdentityColors {
  static ({Color foreground, Color container}) forLabel(
    String label,
    Brightness brightness,
  ) {
    var hash = 0x811c9dc5;
    for (final rune in normalizeTagKey(label).runes) {
      hash = ((hash ^ rune) * 0x01000193) & 0xffffffff;
    }
    final hue = (hash & 0xffffff) * 360 / 0x1000000;
    final saturation = .48 + ((hash >> 24) & 0xff) / 255 * .24;
    final dark = brightness == Brightness.dark;
    return (
      foreground: HSLColor.fromAHSL(
        1,
        hue,
        saturation,
        dark ? .82 : .25,
      ).toColor(),
      container: HSLColor.fromAHSL(
        1,
        hue,
        saturation,
        dark ? .14 : .94,
      ).toColor(),
    );
  }
}
