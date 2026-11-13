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

  /// The brand amber (#E8A33D) is only 2:1 against the light surface, so on
  /// the light theme `primary` — used for text links and section labels as
  /// well as filled buttons — is a deeper amber that clears WCAG AA (4.5:1)
  /// with white `onPrimary`. The dark theme keeps the brand amber.
  static const lightPrimary = Color(0xFF8F5B00);
  static const _lightPrimary = lightPrimary;

  static ThemeData light() {
    final base = PopupBitsTheme.build(
      archetype: archetype,
      product: product,
      brightness: Brightness.light,
    );
    final focused = base.inputDecorationTheme.focusedBorder;
    return _decorate(
      base.copyWith(
        colorScheme: base.colorScheme.copyWith(
          primary: _lightPrimary,
          onPrimary: const Color(0xFFFFFFFF),
          // The default light error red is 3.5:1 on the surface.
          error: const Color(0xFFB3261E),
        ),
        // PopupBitsTheme hard-codes these two to the brand amber (~2:1 on the
        // light surface); point them at the AA-safe primary.
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: _lightPrimary),
        ),
        inputDecorationTheme: base.inputDecorationTheme.copyWith(
          focusedBorder: focused is OutlineInputBorder
              ? focused.copyWith(
                  borderSide: BorderSide(color: _lightPrimary, width: 2),
                )
              : focused,
        ),
      ),
    );
  }

  static ThemeData dark() {
    final base = PopupBitsTheme.build(
      archetype: archetype,
      product: product,
      brightness: Brightness.dark,
    );
    return _decorate(
      base.copyWith(
        // The generated onPrimary is white, which is 2.2:1 on the amber.
        colorScheme: base.colorScheme.copyWith(onPrimary: product.accentInk),
      ),
    );
  }

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
