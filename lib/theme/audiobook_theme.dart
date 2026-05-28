import 'package:flutter/material.dart';
import 'package:popup_bits_design/popup_bits_design.dart';

class AudiobookTheme {
  static const product = PbProductTheme(
    id: 'audiobooks',
    name: 'Audiobooks',
    accent: Color(0xFFD97706),
    accentSoft: Color(0xFFFEF3C7),
    accentInk: Color(0xFF1C1917),
  );

  static const archetype = PbArchetype.utility;

  static ThemeData light() => PopupBitsTheme.build(
        archetype: archetype,
        product: product,
        brightness: Brightness.light,
      );

  static ThemeData dark() => PopupBitsTheme.build(
        archetype: archetype,
        product: product,
        brightness: Brightness.dark,
      );
}
