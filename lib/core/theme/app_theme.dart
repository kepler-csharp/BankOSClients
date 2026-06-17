import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'bank_colors.dart';

/// Tema claro de BankOs. Se apoya en Google Fonts (Poppins) para títulos
/// y en la paleta de marca para todos los componentes.
class AppTheme {
  AppTheme._();

  static ThemeData get light {
    final base = ThemeData.light(useMaterial3: true);

    final textTheme = GoogleFonts.poppinsTextTheme(base.textTheme).apply(
      bodyColor: BankColors.textPrimary,
      displayColor: BankColors.textPrimary,
    );

    return base.copyWith(
      scaffoldBackgroundColor: BankColors.black,
      textTheme: textTheme,

      colorScheme: const ColorScheme.light(
        primary: BankColors.brightBlue,
        secondary: BankColors.magenta,
        tertiary: BankColors.green,
        surface: BankColors.cardDark,
        error: BankColors.error,
        onPrimary: Colors.white,
        onSurface: BankColors.textPrimary,
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: BankColors.textPrimary,
        ),
        iconTheme: const IconThemeData(color: BankColors.textPrimary),
      ),

      // ✅ FIX: CardTheme → CardThemeData (Material 3)
      cardTheme: CardThemeData(
        color: BankColors.cardDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: BankColors.cardBorder),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: BankColors.surfaceDark,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        hintStyle: const TextStyle(color: BankColors.textMuted),
        labelStyle: const TextStyle(color: BankColors.textSecondary),
        prefixIconColor: BankColors.textSecondary,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: BankColors.cardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: BankColors.cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: BankColors.brightBlue, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: BankColors.error),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: BankColors.brightBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16),
          textStyle: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: BankColors.skyBlue,
        ),
      ),

      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: BankColors.cardDark,
        contentTextStyle: TextStyle(color: BankColors.textPrimary),
      ),

      dividerTheme: const DividerThemeData(
        color: BankColors.cardBorder,
      ),

      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: BankColors.surfaceDark,
        selectedItemColor: BankColors.skyBlue,
        unselectedItemColor: BankColors.textMuted,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}