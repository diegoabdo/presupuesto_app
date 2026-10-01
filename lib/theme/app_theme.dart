import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Concepto visual: "libro mayor / plano de construcción".
/// Un azul tinta como base (formal, de confianza), un fondo gris-azulado
/// pálido en vez del típico crema, y dos acentos con significado propio:
/// bronce para capital/progreso positivo, óxido para descuentos y alertas.
/// Las cifras grandes usan una serif (como en un estado de cuenta impreso);
/// el resto de la interfaz usa una sans cómoda y redondeada.
///
/// Los valores son mutables a propósito (no `const`): [AppTheme.syncWithBrightness]
/// los reasigna según el brillo activo cada vez que cambia el tema, así el
/// resto de la app sigue usando `AppColors.ink` tal cual en vez de tener que
/// leer el Theme en cada widget.
class AppColors {
  AppColors._();

  static Color ink = _light.ink;
  static Color paper = _light.paper;
  static Color surface = _light.surface;
  static Color slate = _light.slate;
  static Color line = _light.line;
  static Color brass = _light.brass;
  static Color rust = _light.rust;
  static Color sage = _light.sage;

  static const _light = _Palette(
    ink: Color(0xFF1B2A4A),
    paper: Color(0xFFEEF1F5),
    surface: Color(0xFFFFFFFF),
    slate: Color(0xFF5B6472),
    line: Color(0xFFD8DCE3),
    brass: Color(0xFFB98A2E),
    rust: Color(0xFFA1503A),
    sage: Color(0xFF5C7A5E),
  );

  static const _dark = _Palette(
    ink: Color(0xFFE7EBF3),
    paper: Color(0xFF12161F),
    surface: Color(0xFF1B2029),
    slate: Color(0xFF9AA3B2),
    line: Color(0xFF2C3240),
    brass: Color(0xFFD8AD5C),
    rust: Color(0xFFDD7E63),
    sage: Color(0xFF80A882),
  );

  static void syncWithBrightness(Brightness brightness) {
    final p = brightness == Brightness.dark ? _dark : _light;
    ink = p.ink;
    paper = p.paper;
    surface = p.surface;
    slate = p.slate;
    line = p.line;
    brass = p.brass;
    rust = p.rust;
    sage = p.sage;
  }
}

class _Palette {
  final Color ink, paper, surface, slate, line, brass, rust, sage;
  const _Palette({
    required this.ink,
    required this.paper,
    required this.surface,
    required this.slate,
    required this.line,
    required this.brass,
    required this.rust,
    required this.sage,
  });
}

/// Radios de borde compartidos para que todos los cuadros/tarjetas se
/// sientan igual de redondeados en toda la app.
class AppRadii {
  AppRadii._();
  static const card = 20.0;
  static const control = 16.0;
  static const bar = 6.0;
}

class AppTheme {
  AppTheme._();

  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final palette = isDark ? AppColors._dark : AppColors._light;

    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: palette.paper,
      colorScheme: (isDark ? const ColorScheme.dark() : const ColorScheme.light()).copyWith(
        primary: palette.ink,
        onPrimary: isDark ? palette.paper : Colors.white,
        secondary: palette.brass,
        onSecondary: isDark ? palette.paper : Colors.white,
        surface: palette.surface,
        onSurface: palette.ink,
        error: palette.rust,
      ),
      // Transición suave (fundido + leve desplazamiento) en vez del zoom
      // brusco por defecto, para que la navegación se sienta más fluida.
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.macOS: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.linux: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.windows: FadeForwardsPageTransitionsBuilder(),
        },
      ),
    );

    final displayFont = GoogleFonts.newsreaderTextTheme(base.textTheme);
    final uiFont = GoogleFonts.plusJakartaSansTextTheme(base.textTheme);

    return base.copyWith(
      textTheme: uiFont.copyWith(
        displayLarge: displayFont.displayLarge?.copyWith(
          color: palette.ink,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.5,
        ),
        displayMedium: displayFont.displayMedium?.copyWith(
          color: palette.ink,
          fontWeight: FontWeight.w600,
        ),
        headlineMedium: displayFont.headlineMedium?.copyWith(
          color: palette.ink,
          fontWeight: FontWeight.w600,
        ),
        titleLarge: uiFont.titleLarge?.copyWith(
          color: palette.ink,
          fontWeight: FontWeight.w700,
        ),
        bodyLarge: uiFont.bodyLarge?.copyWith(color: palette.ink),
        bodyMedium: uiFont.bodyMedium?.copyWith(color: palette.slate),
        labelLarge: uiFont.labelLarge?.copyWith(color: palette.ink),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: palette.paper,
        foregroundColor: palette.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: palette.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.card),
          side: BorderSide(color: palette.line, width: 1),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: palette.surface,
        indicatorColor: palette.ink.withValues(alpha: 0.08),
        labelTextStyle: WidgetStateProperty.all(
          uiFont.labelSmall?.copyWith(color: palette.ink),
        ),
      ),
      dividerTheme: DividerThemeData(color: palette.line, thickness: 1),
    );
  }
}
