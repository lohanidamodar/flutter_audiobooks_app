import 'package:google_fonts/google_fonts.dart';
import 'package:material_ui/material_ui.dart';
import 'package:popup_bits_design/popup_bits_design.dart';

import 'google_fonts_text_theme.dart';

class AudiobookTheme {
  static const product = PbProductTheme(
    id: 'audiobooks',
    name: 'Listora',
    accent: Color(0xFFE8A33D),
    accentSoft: Color(0xFFFEF3C7),
    accentInk: Color(0xFF14110E),
  );

  static const archetype = PbArchetype.utility;

  /// Characterful high-contrast serif for book titles and section headers.
  static TextStyle display(
    BuildContext context, {
    double? fontSize,
    FontWeight fontWeight = FontWeight.w600,
    Color? color,
    double? height,
  }) {
    return GoogleFonts.fraunces(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color ?? Theme.of(context).colorScheme.onSurface,
      height: height,
      letterSpacing: -0.2,
    );
  }

  static ThemeData light() => _decorate(PopupBitsTheme.build(
        archetype: archetype,
        product: product,
        brightness: Brightness.light,
      ));

  static ThemeData dark() => _decorate(PopupBitsTheme.build(
        archetype: archetype,
        product: product,
        brightness: Brightness.dark,
      ));

  /// Layer the display serif onto the large type slots; keep popup_bits'
  /// Nunito for everything body/label-sized.
  static ThemeData _decorate(ThemeData base) {
    final fraunces = googleFontsTextTheme(base.textTheme, GoogleFonts.fraunces);
    return base.copyWith(
      textTheme: base.textTheme.copyWith(
        displayLarge: fraunces.displayLarge?.copyWith(letterSpacing: -0.5),
        displayMedium: fraunces.displayMedium?.copyWith(letterSpacing: -0.5),
        displaySmall: fraunces.displaySmall?.copyWith(letterSpacing: -0.4),
        headlineLarge: fraunces.headlineLarge?.copyWith(letterSpacing: -0.4),
        headlineMedium: fraunces.headlineMedium?.copyWith(letterSpacing: -0.3),
        headlineSmall: fraunces.headlineSmall?.copyWith(letterSpacing: -0.3),
        titleLarge: fraunces.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
        ),
      ),
    );
  }
}
