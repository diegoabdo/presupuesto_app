import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Concepto visual: "libro mayor / plano de construcción".
/// Un azul tinta como base (formal, de confianza), un fondo gris-azulado
/// pálido en vez del típico crema, y dos acentos con significado propio:
/// bronce para ahorro/progreso positivo, óxido para descuentos y alertas.
/// Las cifras grandes usan una serif (como en un estado de cuenta impreso);
/// el resto de la interfaz usa una sans geométrica.
class AppColors {
  AppColors._();

  static const ink = Color(0xFF1B2A4A);
  static const paper = Color(0xFFEEF1F5);
  static const surface = Color(0xFFFFFFFF);
  static const slate = Color(0xFF5B6472);
  static const line = Color(0xFFD8DCE3);
  static const brass = Color(0xFFB98A2E);
  static const rust = Color(0xFFA1503A);
  static const sage = Color(0xFF5C7A5E);
}

class AppTheme {
  AppTheme._();

  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.paper,
      colorScheme: const ColorScheme.light(
        primary: AppColors.ink,
        onPrimary: Colors.white,
        secondary: AppColors.brass,
        onSecondary: Colors.white,
        surface: AppColors.surface,
        onSurface: AppColors.ink,
        error: AppColors.rust,
      ),
    );

    final displayFont = GoogleFonts.sourceSerif4TextTheme(base.textTheme);
    final uiFont = GoogleFonts.manropeTextTheme(base.textTheme);

    return base.copyWith(
      textTheme: uiFont.copyWith(
        displayLarge: displayFont.displayLarge?.copyWith(
          color: AppColors.ink,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.5,
        ),
        displayMedium: displayFont.displayMedium?.copyWith(
          color: AppColors.ink,
          fontWeight: FontWeight.w600,
        ),
        headlineMedium: displayFont.headlineMedium?.copyWith(
          color: AppColors.ink,
          fontWeight: FontWeight.w600,
        ),
        titleLarge: uiFont.titleLarge?.copyWith(
          color: AppColors.ink,
          fontWeight: FontWeight.w700,
        ),
        bodyLarge: uiFont.bodyLarge?.copyWith(color: AppColors.ink),
        bodyMedium: uiFont.bodyMedium?.copyWith(color: AppColors.slate),
        labelLarge: uiFont.labelLarge?.copyWith(color: AppColors.ink),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.paper,
        foregroundColor: AppColors.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: const BorderSide(color: AppColors.line, width: 1),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.ink.withOpacity(0.08),
        labelTextStyle: WidgetStateProperty.all(
          uiFont.labelSmall?.copyWith(color: AppColors.ink),
        ),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.line, thickness: 1),
    );
  }
}
