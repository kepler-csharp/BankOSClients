import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/models.dart';
import 'mail_service.dart';

/// Genera un certificado bancario en PDF (en memoria) y lo "envía" al correo.
/// El PDF se crea al vuelo; se guarda solo de forma temporal para poder
/// compartirlo/imprimirlo, tal como un adjunto de correo.
class CertificateService {
  CertificateService._();
  static final CertificateService instance = CertificateService._();

  Future<File> generate({
    required Account account,
    required String holderName,
    required String holderEmail,
    required String bankName,
  }) async {
    final doc = pw.Document();
    final now = DateTime.now();
    final ref =
        'BKS-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-${account.accountNumber}';

    // Logo (si está disponible en assets).
    pw.MemoryImage? logo;
    try {
      final bytes = await rootBundle.load('assets/images/logo.png');
      logo = pw.MemoryImage(bytes.buffer.asUint8List());
    } catch (_) {}

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  if (logo != null) pw.Image(logo, width: 70, height: 70),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('BankOs',
                          style: pw.TextStyle(
                              fontSize: 26,
                              fontWeight: pw.FontWeight.bold,
                              color: const PdfColor.fromInt(0xFF001878))),
                      pw.Text('Una plataforma. Todos los bancos.',
                          style: const pw.TextStyle(
                              fontSize: 9,
                              color: PdfColor.fromInt(0xFF7800F0))),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 8),
              pw.Divider(color: const PdfColor.fromInt(0xFF9000F0), thickness: 2),
              pw.SizedBox(height: 24),
              pw.Center(
                child: pw.Text('CERTIFICADO BANCARIO',
                    style: pw.TextStyle(
                        fontSize: 20, fontWeight: pw.FontWeight.bold)),
              ),
              pw.SizedBox(height: 4),
              pw.Center(
                child: pw.Text(bankName,
                    style: const pw.TextStyle(
                        fontSize: 12, color: PdfColor.fromInt(0xFF555555))),
              ),
              pw.SizedBox(height: 28),
              pw.Text(
                'El presente documento certifica que el titular identificado '
                'a continuación mantiene la siguiente cuenta en nuestra entidad:',
                style: const pw.TextStyle(fontSize: 12, lineSpacing: 3),
              ),
              pw.SizedBox(height: 20),
              _row('Titular', holderName),
              _row('Correo', holderEmail),
              _row('Banco', bankName),
              _row('Número de cuenta', account.accountNumber),
              _row('Moneda', account.currency),
              _row('Estado',
                  account.isActive ? 'ACTIVA' : account.status.toUpperCase()),
              _row('Saldo certificado',
                  '${account.currency} ${account.balance.toStringAsFixed(2)}'),
              pw.SizedBox(height: 28),
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: const PdfColor.fromInt(0xFFF2F0FF),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Referencia: $ref',
                        style: pw.TextStyle(
                            fontSize: 10, fontWeight: pw.FontWeight.bold)),
                    pw.Text(
                        'Expedido el: ${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year} '
                        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
                        style: const pw.TextStyle(fontSize: 10)),
                  ],
                ),
              ),
              pw.Spacer(),
              pw.Divider(color: const PdfColor.fromInt(0xFFCCCCCC)),
              pw.Text(
                'Documento generado electrónicamente por BankOs. Su validez '
                'puede verificarse con la referencia indicada. Este certificado '
                'no requiere firma autógrafa.',
                style: const pw.TextStyle(
                    fontSize: 8, color: PdfColor.fromInt(0xFF888888)),
              ),
            ],
          );
        },
      ),
    );

    final bytes = await doc.save();
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/certificado_${account.accountNumber}.pdf');
    await file.writeAsBytes(bytes);

    // "Envío" por correo (simulado).
    await MailService.instance.sendCertificate(
      to: holderEmail,
      userName: holderName,
      accountNumber: account.accountNumber,
      filePath: file.path,
    );

    return file;
  }

  static pw.Widget _row(String label, String value) => pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 5),
        child: pw.Row(
          children: [
            pw.SizedBox(
              width: 150,
              child: pw.Text('$label:',
                  style: pw.TextStyle(
                      fontSize: 12, fontWeight: pw.FontWeight.bold)),
            ),
            pw.Expanded(
                child: pw.Text(value, style: const pw.TextStyle(fontSize: 12))),
          ],
        ),
      );

  /// Abre el diálogo nativo para compartir/guardar/imprimir el PDF
  /// (equivale a "descargar" el certificado en el dispositivo).
  Future<void> shareOrPrint(File file) async {
    final bytes = await file.readAsBytes();
    await Printing.sharePdf(
        bytes: bytes, filename: file.uri.pathSegments.last);
  }
}
