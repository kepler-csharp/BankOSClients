import 'package:flutter/material.dart';

/// Paleta de marca BankOs (modo claro), derivada de los logos provistos.
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

  // Fondos (claros)
  static const Color black = Color(0xFFF6F7FB);       // antes fondo principal
  static const Color surfaceDark = Color(0xFFFFFFFF);  // superficies / inputs
  static const Color cardDark = Color(0xFFFFFFFF);     // tarjetas
  static const Color cardBorder = Color(0xFFE2E5EF);   // bordes sutiles

  // Texto (sobre claro)
  static const Color textPrimary = Color(0xFF14141C);
  static const Color textSecondary = Color(0xFF5A5A70);
  static const Color textMuted = Color(0xFF9092A6);

  // Semánticos
  static const Color success = Color(0xFF00A865);
  static const Color error = Color(0xFFE03050);
  static const Color warning = Color(0xFFC97E00);

  /// Gradiente principal de marca (el de la "O" del logo). Se mantiene vivo
  /// porque es identidad de marca, no fondo.
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

  /// Gradiente sutil para fondos de pantalla (suave sobre base clara).
  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [Color(0xFFF6F7FB), Color(0xFFEEF1F9), Color(0xFFF6F7FB)],
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
