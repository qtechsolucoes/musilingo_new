// lib/app/presentation/view/main_navigation_screen.dart

import 'package:flutter/material.dart';
import 'package:musilingo/app/core/theme/app_colors.dart';
import 'package:musilingo/app/presentation/widgets/gradient_background.dart';
import 'package:musilingo/features/duel/presentation/view/duel_lobby_screen.dart';
import 'package:musilingo/features/home/presentation/view/home_screen.dart';
import 'package:musilingo/features/practice/presentation/view/practice_screen.dart';
import 'package:musilingo/app/presentation/view/ai_hub_screen.dart';
import 'package:musilingo/app/presentation/view/more_screen.dart';

// --- NOVA IMPORTAÇÃO ---
import 'package:musilingo/features/connections/presentation/view/connections_hub_screen.dart';
// --- FIM DA NOVA IMPORTAÇÃO ---

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;

  // --- MODIFICAÇÃO AQUI ---
  // A lista de páginas foi atualizada para incluir a nova tela de Conexões.
  final List<Widget> _pages = [
    const HomeScreen(),
    const AiHubScreen(),
    const PracticeScreen(),
    const DuelLobbyScreen(),
    const ConnectionsHubScreen(), // O 5º item agora aponta para o novo Hub.
    const MoreScreen(),
  ];
  // --- FIM DA MODIFICAÇÃO ---

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: IndexedStack(
          index: _selectedIndex,
          children: _pages,
        ),
        bottomNavigationBar: BottomNavigationBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: AppColors.accent,
          unselectedItemColor: Colors.white,
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Aprender'),
            BottomNavigationBarItem(
                icon: Icon(Icons.auto_awesome), label: 'CecilIA'),
            BottomNavigationBarItem(
                icon: Icon(Icons.music_note), label: 'Praticar'),
            BottomNavigationBarItem(icon: Icon(Icons.shield), label: 'Ligas'),
            // --- MODIFICAÇÃO AQUI ---
            // Ícone e rótulo atualizados para "Conexões".
            BottomNavigationBarItem(
                icon: Icon(Icons.connect_without_contact), label: 'Conexões'),
            // --- FIM DA MODIFICAÇÃO ---
            BottomNavigationBarItem(
                icon: Icon(Icons.more_horiz), label: 'Mais'),
          ],
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
        ),
      ),
    );
  }
}
