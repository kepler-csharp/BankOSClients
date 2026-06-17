import 'package:flutter/material.dart';
import '../core/theme/bank_colors.dart';

/// Fondo con el gradiente sutil de marca + manchas de color difuminadas
/// que recuerdan la nube del logo.
class BrandBackground extends StatelessWidget {
  final Widget child;
  const BrandBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: BankColors.backgroundGradient),
      child: Stack(
        children: [
          Positioned(
            top: -120,
            right: -80,
            child: _blob(BankColors.violet.withValues(alpha: 0.10), 260),
          ),
          Positioned(
            top: -60,
            left: -100,
            child: _blob(BankColors.brightBlue.withValues(alpha: 0.08), 240),
          ),
          Positioned(
            bottom: -140,
            left: -60,
            child: _blob(BankColors.emerald.withValues(alpha: 0.07), 280),
          ),
          child,
        ],
      ),
    );
  }

  Widget _blob(Color color, double size) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color, Colors.transparent]),
        ),
      );
}

/// Texto con el gradiente de marca aplicado (para títulos tipo "BankOs").
class GradientText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final Gradient gradient;
  const GradientText(
    this.text, {
    super.key,
    this.style,
    this.gradient = BankColors.brandGradient,
  });

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) => gradient.createShader(
        Rect.fromLTWH(0, 0, bounds.width, bounds.height),
      ),
      child: Text(text, style: (style ?? const TextStyle()).copyWith(color: Colors.white)),
    );
  }
}

/// Botón primario con el gradiente de marca.
class GradientButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? icon;
  const GradientButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !loading;
    return Opacity(
      opacity: enabled ? 1 : 0.6,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: enabled ? onPressed : null,
          child: Ink(
            decoration: BoxDecoration(
              gradient: BankColors.cardGradient,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: BankColors.violet.withValues(alpha: 0.22),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: loading
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.4, color: Colors.white),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (icon != null) ...[
                          Icon(icon, color: Colors.white, size: 20),
                          const SizedBox(width: 10),
                        ],
                        Text(
                          label,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Tarjeta con borde sutil tipo "glass".
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Gradient? gradient;
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.onTap,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: gradient == null ? BankColors.cardDark : null,
            gradient: gradient,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: BankColors.cardBorder),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// SnackBar helper.
void showSnack(BuildContext context, String message, {bool error = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? BankColors.error : BankColors.cardDark,
        duration: const Duration(seconds: 3),
      ),
    );
}
