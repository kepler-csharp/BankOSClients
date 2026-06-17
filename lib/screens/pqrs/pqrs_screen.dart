import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/bank_colors.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/models.dart';
import '../../providers/pqrs_provider.dart';
import '../../widgets/common.dart';

class PqrsScreen extends StatelessWidget {
  const PqrsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final pqrs = context.watch<PqrsProvider>();
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 70),
        child: FloatingActionButton.extended(
          backgroundColor: BankColors.brightBlue,
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text('Nueva PQRS',
              style: TextStyle(color: Colors.white)),
          onPressed: () => _openCreateSheet(context),
        ),
      ),
      body: BrandBackground(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 16, 20, 4),
                child: Text('PQRS',
                    style:
                        TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Text(
                  'Peticiones, quejas, reclamos y sugerencias. El banco te responderá por correo.',
                  style:
                      TextStyle(color: BankColors.textSecondary, fontSize: 13),
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  color: BankColors.skyBlue,
                  backgroundColor: BankColors.cardDark,
                  onRefresh: () => pqrs.load(),
                  child: pqrs.loading
                      ? const Center(child: CircularProgressIndicator())
                      : pqrs.items.isEmpty
                          ? _empty()
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 140),
                              itemCount: pqrs.items.length,
                              itemBuilder: (_, i) => _card(pqrs.items[i]),
                            ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _empty() => ListView(
        children: const [
          SizedBox(height: 120),
          Icon(Icons.forum_outlined, size: 56, color: BankColors.textMuted),
          SizedBox(height: 12),
          Center(
            child: Text('Aún no has creado ninguna PQRS.',
                style: TextStyle(color: BankColors.textMuted)),
          ),
        ],
      );

  Widget _card(PqrsModel p) {
    final typeColor = switch (p.type) {
      'queja' => BankColors.warning,
      'reclamo' => BankColors.error,
      'sugerencia' => BankColors.emerald,
      _ => BankColors.brightBlue,
    };
    final resolved = p.status == 'resuelto' || p.adminResponse != null;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: BankColors.cardDark,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: BankColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: typeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  p.type.toUpperCase(),
                  style: TextStyle(
                      color: typeColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold),
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: resolved
                      ? BankColors.green.withValues(alpha: 0.15)
                      : BankColors.warning.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  resolved ? 'Resuelto' : 'Pendiente',
                  style: TextStyle(
                    color: resolved ? BankColors.green : BankColors.warning,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(p.subject,
              style: const TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 15)),
          const SizedBox(height: 6),
          Text(p.message,
              style: const TextStyle(
                  color: BankColors.textSecondary, fontSize: 13)),
          if (p.createdAt != null) ...[
            const SizedBox(height: 8),
            Text(Formatters.date(p.createdAt),
                style:
                    const TextStyle(color: BankColors.textMuted, fontSize: 11)),
          ],
          if (p.adminResponse != null && p.adminResponse!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: BankColors.surfaceDark,
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: BankColors.green.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.support_agent,
                          size: 16, color: BankColors.green),
                      SizedBox(width: 6),
                      Text('Respuesta del banco',
                          style: TextStyle(
                              color: BankColors.green,
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(p.adminResponse!,
                      style: const TextStyle(
                          color: BankColors.textPrimary, fontSize: 13)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _openCreateSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _CreatePqrsSheet(),
    );
  }
}

class _CreatePqrsSheet extends StatefulWidget {
  const _CreatePqrsSheet();
  @override
  State<_CreatePqrsSheet> createState() => _CreatePqrsSheetState();
}

class _CreatePqrsSheetState extends State<_CreatePqrsSheet> {
  final _form = GlobalKey<FormState>();
  final _subject = TextEditingController();
  final _message = TextEditingController();
  String _type = 'pregunta';
  bool _busy = false;

  final _types = const {
    'pregunta': 'Pregunta',
    'queja': 'Queja',
    'reclamo': 'Reclamo',
    'sugerencia': 'Sugerencia',
  };

  @override
  void dispose() {
    _subject.dispose();
    _message.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    final pqrs = context.read<PqrsProvider>();
    final ok = await pqrs.create(
      type: _type,
      subject: _subject.text.trim(),
      message: _message.text.trim(),
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) {
      Navigator.pop(context);
      showSnack(context,
          'PQRS enviada. Te notificaremos por correo cuando haya respuesta.');
    } else {
      showSnack(context, pqrs.error ?? 'No se pudo enviar.', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(20, 16, 20, bottom + 20),
      decoration: const BoxDecoration(
        color: BankColors.surfaceDark,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(top: BorderSide(color: BankColors.cardBorder)),
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: BankColors.cardBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text('Nueva PQRS',
                  style:
                      TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              const Text('Tipo',
                  style: TextStyle(
                      color: BankColors.textSecondary, fontSize: 13)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _types.entries.map((e) {
                  final selected = _type == e.key;
                  return ChoiceChip(
                    label: Text(e.value),
                    selected: selected,
                    onSelected: (_) => setState(() => _type = e.key),
                    backgroundColor: BankColors.cardDark,
                    selectedColor: BankColors.brightBlue,
                    labelStyle: TextStyle(
                        color:
                            selected ? Colors.white : BankColors.textSecondary),
                    side: BorderSide(
                        color: selected
                            ? Colors.transparent
                            : BankColors.cardBorder),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _subject,
                decoration: const InputDecoration(
                  labelText: 'Asunto',
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (v) =>
                    (v == null || v.trim().length < 3) ? 'Requerido' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _message,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Mensaje',
                  alignLabelWithHint: true,
                ),
                validator: (v) => (v == null || v.trim().length < 10)
                    ? 'Describe tu solicitud (mín. 10 caracteres)'
                    : null,
              ),
              const SizedBox(height: 20),
              GradientButton(
                label: 'Enviar PQRS',
                icon: Icons.send,
                loading: _busy,
                onPressed: _busy ? null : _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
