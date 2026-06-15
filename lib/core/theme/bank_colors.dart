import 'package:flutter/material.dart';

/// Paleta de marca BankOs, extraída directamente de los logos provistos.
/// El gradiente de la "O" recorre: azul profundo → azul brillante →
/// morado → cian-verde. Todo el tema de la app se construye sobre esto.
class BankColors {
  BankColors._();

  // Azules (la "Bank")
  static const Color deepBlue = Color(0xFF000060);
  static const Color royalBlue = Color(0xFF001878);
  static const Color brightBlue = Color(0xFF0078F0);
  static const Color skyBlue = Color(0xFF0090F0);

  // Morados (transición de la "O")
  static const Color violet = Color(0xFF7800F0);
  static const Color purple = Color(0xFF9000F0);
  static const Color magenta = Color(0xFFA800F0);

  // Cian / verdes (la "s")
  static const Color teal = Color(0xFF00A8A8);
  static const Color emerald = Color(0xFF00A890);
  static const Color green = Color(0xFF00C078);

  // Fondos
  static const Color black = Color(0xFF050507);
  static const Color surfaceDark = Color(0xFF101018);
  static const Color cardDark = Color(0xFF16161F);
  static const Color cardBorder = Color(0xFF24243A);

  // Texto
  static const Color textPrimary = Color(0xFFF4F4FA);
  static const Color textSecondary = Color(0xFF9C9CB4);
  static const Color textMuted = Color(0xFF6A6A82);

  // Semánticos
  static const Color success = Color(0xFF00C078);
  static const Color error = Color(0xFFFF4D6A);
  static const Color warning = Color(0xFFFFB020);

  /// Gradiente principal de marca (el de la "O" del logo).
  static const LinearGradient brandGradient = LinearGradient(
    colors: [brightBlue, violet, magenta, emerald, green],
    stops: [0.0, 0.35, 0.5, 0.8, 1.0],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  /// Gradiente para tarjetas de cuentas y botones primarios.
  static const LinearGradient cardGradient = LinearGradient(
    colors: [royalBlue, violet, emerald],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Gradiente sutil para fondos de pantalla.
  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [black, Color(0xFF0A0A14), black],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  /// Devuelve un color de acento según la moneda (para variar las tarjetas).
  static Color forCurrency(String currency) {
    switch (currency.toUpperCase()) {
      case 'USD':
        return green;
      case 'EUR':
        return violet;
      case 'GBP':
        return teal;
      case 'COP':
      default:
        return brightBlue;
    }
  }
}
