import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_config.dart';
import '../../core/theme/bank_colors.dart';
import '../../data/services/chatbot_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/banking_provider.dart';

class _Msg {
  final String role; // 'user' | 'assistant'
  final String content;
  _Msg(this.role, this.content);
}

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});
  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final _service = ChatbotService();
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final List<_Msg> _messages = [];
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _messages.add(_Msg('assistant',
        '¡Hola! Soy tu asistente de BankOs. Puedo ayudarte con tus saldos, '
        'movimientos, transferencias, retiros, QR, certificados y PQRS. '
        '¿En qué te ayudo?'));
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty || _sending) return;
    final auth = context.read<AuthProvider>();
    final banking = context.read<BankingProvider>();

    setState(() {
      _messages.add(_Msg('user', text));
      _sending = true;
      _input.clear();
    });
    _scrollToBottom();

    // Construir historial (limitado a los últimos turnos para el contexto).
    final history = _messages
        .where((m) => m.role == 'user' || m.role == 'assistant')
        .map((m) => {'role': m.role, 'content': m.content})
        .toList();

    final reply = await _service.ask(
      history: history,
      userName: auth.user?.name ?? 'Cliente',
      email: auth.user?.email ?? '',
      bank: auth.tenantName ?? '',
      accounts: banking.accounts,
      recent: banking.transactions,
    );

    if (!mounted) return;
    setState(() {
      _messages.add(_Msg('assistant', reply));
      _sending = false;
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(gradient: BankColors.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              _header(),
              Expanded(
                child: ListView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  itemCount: _messages.length + (_sending ? 1 : 0),
                  itemBuilder: (_, i) {
                    if (i == _messages.length && _sending) {
                      return _typingBubble();
                    }
                    return _bubble(_messages[i]);
                  },
                ),
              ),
              _composer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: BankColors.cardBorder)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: BankColors.cardGradient,
            ),
            child: const Icon(Icons.smart_toy, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Asistente BankOs',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600)),
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: BankColors.green,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    AppConfig.hasOpenAi ? 'En línea' : 'Modo básico',
                    style: const TextStyle(
                        color: BankColors.textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _bubble(_Msg m) {
    final isUser = m.role == 'user';
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.78),
        decoration: BoxDecoration(
          gradient: isUser ? BankColors.cardGradient : null,
          color: isUser ? null : BankColors.cardDark,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isUser ? 18 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 18),
          ),
          border: isUser
              ? null
              : Border.all(color: BankColors.cardBorder),
        ),
        child: Text(
          m.content,
          style: TextStyle(
            color: isUser ? Colors.white : BankColors.textPrimary,
            fontSize: 14,
            height: 1.4,
          ),
        ),
      ),
    );
  }

  Widget _typingBubble() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: BankColors.cardDark,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: BankColors.cardBorder),
        ),
        child: const SizedBox(
          width: 40,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _Dot(), _Dot(delay: 200), _Dot(delay: 400),
            ],
          ),
        ),
      ),
    );
  }

  Widget _composer() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: const BoxDecoration(
        color: BankColors.surfaceDark,
        border: Border(top: BorderSide(color: BankColors.cardBorder)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _input,
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _send(),
              decoration: InputDecoration(
                hintText: 'Escribe tu pregunta...',
                fillColor: BankColors.cardDark,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: BankColors.cardBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: BankColors.cardBorder),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: _send,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  gradient: BankColors.cardGradient,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.send, color: Colors.white, size: 22),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Dot extends StatefulWidget {
  final int delay;
  const _Dot({this.delay = 0});
  @override
  State<_Dot> createState() => _DotState();
}

class _DotState extends State<_Dot> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _c.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween(begin: 0.3, end: 1.0).animate(_c),
      child: Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          color: BankColors.skyBlue,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
