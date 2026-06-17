import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/bank_colors.dart';
import '../../providers/banking_provider.dart';
import '../../providers/pqrs_provider.dart';
import '../chatbot/chatbot_screen.dart';
import '../pqrs/pqrs_screen.dart';
import '../qr/scan_screen.dart';
import 'dashboard_screen.dart';
import 'profile_screen.dart';

/// Contenedor principal con barra de navegación inferior.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BankingProvider>().loadAll();
      context.read<PqrsProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    const pages = [
      DashboardScreen(),
      PqrsScreen(),
      ChatbotScreen(),
      ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        backgroundColor: BankColors.violet,
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ScanScreen()),
        ),
        child: const Icon(Icons.qr_code_scanner, color: Colors.white),
      ),
      bottomNavigationBar: BottomAppBar(
        color: BankColors.surfaceDark,
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _navItem(0, Icons.dashboard_outlined, Icons.dashboard, 'Inicio'),
            _navItem(1, Icons.support_agent_outlined, Icons.support_agent,
                'PQRS'),
            const SizedBox(width: 40),
            _navItem(2, Icons.smart_toy_outlined, Icons.smart_toy, 'Asistente'),
            _navItem(3, Icons.person_outline, Icons.person, 'Perfil'),
          ],
        ),
      ),
    );
  }

  Widget _navItem(int i, IconData icon, IconData active, String label) {
    final selected = _index == i;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => setState(() => _index = i),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(selected ? active : icon,
                color: selected ? BankColors.skyBlue : BankColors.textMuted,
                size: 24),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(
                    fontSize: 10,
                    color:
                        selected ? BankColors.skyBlue : BankColors.textMuted)),
          ],
        ),
      ),
    );
  }
}
