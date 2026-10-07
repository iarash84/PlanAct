import 'package:flutter/material.dart';
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/features/commitments/domain/commitment_color.dart';

/// Identity only: these colors never communicate outcome or urgency.
abstract final class CommitmentIdentityPalette {
  static CommitmentColor fallback(StableId id) {
    // FNV-1a over stable ID code units; no process-dependent String.hashCode.
    var hash = 2166136261;
    for (final unit in id.value.codeUnits) {
      hash = ((hash ^ unit) * 16777619) & 0xffffffff;
    }
    return CommitmentColor.values[hash % CommitmentColor.values.length];
  }

  static CommitmentColor resolve(CommitmentColor? color, StableId id) =>
      color ?? fallback(id);

  static Color background(CommitmentColor color, Brightness brightness) {
    final dark = brightness == Brightness.dark;
    return switch (color) {
      CommitmentColor.teal => Color(dark ? 0xff80cbc4 : 0xff176b67),
      CommitmentColor.blue => Color(dark ? 0xff90caf9 : 0xff205d96),
      CommitmentColor.indigo => Color(dark ? 0xffb6bdf3 : 0xff454f91),
      CommitmentColor.violet => Color(dark ? 0xffd0b4ed : 0xff71488f),
      CommitmentColor.rose => Color(dark ? 0xffedb4c7 : 0xff914b66),
      CommitmentColor.amber => Color(dark ? 0xffebcc90 : 0xff785b21),
      CommitmentColor.olive => Color(dark ? 0xffc3d39b : 0xff566a31),
      CommitmentColor.cyan => Color(dark ? 0xff91d6e3 : 0xff246878),
    };
  }

  static Color foreground(CommitmentColor color, Brightness brightness) =>
      brightness == Brightness.dark ? const Color(0xff101a1e) : Colors.white;

  static String label(CommitmentColor color) => switch (color) {
    CommitmentColor.teal => 'سبزآبی',
    CommitmentColor.blue => 'آبی',
    CommitmentColor.indigo => 'نیلی',
    CommitmentColor.violet => 'بنفش',
    CommitmentColor.rose => 'صورتی',
    CommitmentColor.amber => 'کهربایی',
    CommitmentColor.olive => 'زیتونی',
    CommitmentColor.cyan => 'فیروزه‌ای',
  };
}
