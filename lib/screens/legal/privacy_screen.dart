import 'package:flutter/material.dart';
import '../../core/theme/bank_colors.dart';
import '../../widgets/common.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Política de privacidad')),
      body: BrandBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Image.asset('assets/images/logo-text.png', height: 56),
                ),
                const SizedBox(height: 8),
                const Center(
                  child: Text(
                    'Última actualización: 2025',
                    style:
                        TextStyle(color: BankColors.textMuted, fontSize: 12),
                  ),
                ),
                const SizedBox(height: 24),
                _intro(),
                const SizedBox(height: 16),
                _section(
                  '1. Datos que recopilamos',
                  'Recopilamos los datos necesarios para prestarte el servicio '
                      'bancario: nombre, correo electrónico, banco al que perteneces, '
                      'información de tus cuentas y el historial de transacciones que '
                      'realizas dentro de la aplicación. No solicitamos información '
                      'que no sea estrictamente necesaria.',
                ),
                _section(
                  '2. Cómo usamos tus datos',
                  'Usamos tus datos exclusivamente para autenticarte de forma '
                      'segura, mostrarte tus cuentas y movimientos, procesar tus '
                      'operaciones (depósitos, retiros y transferencias), generar '
                      'certificados que tú solicites y atender tus PQRS. Tus datos '
                      'nunca se venden a terceros.',
                ),
                _section(
                  '3. Seguridad y clave dinámica',
                  'El acceso a tu cuenta está protegido con una clave dinámica de '
                      'un solo uso (OTP) que enviamos a tu correo y que vence a los '
                      '10 minutos. Las operaciones sensibles, como los retiros y la '
                      'generación de certificados, requieren una verificación '
                      'adicional. Tu sesión se almacena de forma cifrada en tu '
                      'dispositivo.',
                ),
                _section(
                  '4. Comunicaciones',
                  'Te enviaremos notificaciones por correo cuando ocurran eventos '
                      'relevantes en tu cuenta: inicio de sesión, cambios en tu perfil, '
                      'movimientos, certificados emitidos y respuestas a tus PQRS. '
                      'Estas comunicaciones son parte del servicio.',
                ),
                _section(
                  '5. Tus derechos',
                  'Tienes derecho a acceder, rectificar y solicitar la eliminación '
                      'de tus datos personales, así como a presentar reclamos a través '
                      'del módulo de PQRS. Atenderemos tus solicitudes conforme a la '
                      'legislación aplicable de protección de datos.',
                ),
                _section(
                  '6. Conservación de datos',
                  'Conservamos tus datos mientras mantengas una relación activa con '
                      'tu banco y durante el tiempo que exijan las obligaciones legales '
                      'y regulatorias del sector financiero.',
                ),
                _section(
                  '7. Contacto',
                  'Para cualquier duda sobre el tratamiento de tus datos, contáctanos '
                      'a través del módulo de PQRS dentro de la aplicación. Tu banco es '
                      'el responsable del tratamiento de tus datos personales.',
                ),
                const SizedBox(height: 24),
                Center(
                  child: Text(
                    '© 2025 BankOs · Una plataforma, todos los bancos.',
                    style: TextStyle(
                        color: BankColors.textMuted, fontSize: 12),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _intro() => GlassCard(
        child: Row(
          children: const [
            Icon(Icons.shield_outlined, color: BankColors.skyBlue, size: 32),
            SizedBox(width: 14),
            Expanded(
              child: Text(
                'Tu privacidad es prioritaria. Aquí te explicamos qué datos '
                'tratamos y cómo los protegemos.',
                style:
                    TextStyle(color: BankColors.textSecondary, fontSize: 13),
              ),
            ),
          ],
        ),
      );

  Widget _section(String title, String body) => Padding(
        padding: const EdgeInsets.only(bottom: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: BankColors.textPrimary)),
            const SizedBox(height: 6),
            Text(body,
                style: const TextStyle(
                    color: BankColors.textSecondary,
                    fontSize: 13,
                    height: 1.5)),
          ],
        ),
      );
}
