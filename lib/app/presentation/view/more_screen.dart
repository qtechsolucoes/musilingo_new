// lib/app/presentation/view/more_screen.dart

import 'package:flutter/material.dart';
import 'package:musilingo/features/leagues/presentation/view/leagues_screen.dart';
import 'package:musilingo/features/profile/presentation/view/profile_screen.dart';

// Chave global para o nosso navegador aninhado
final GlobalKey<NavigatorState> moreTabNavigatorKey =
    GlobalKey<NavigatorState>();

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // ignore: deprecated_member_use
    return WillPopScope(
      onWillPop: () async {
        // Se pudermos voltar no navegador aninhado, voltamos.
        if (moreTabNavigatorKey.currentState!.canPop()) {
          moreTabNavigatorKey.currentState!.pop();
          return false; // Impede que a app feche
        }
        // Se não, permite o comportamento padrão (fechar a app)
        return true;
      },
      child: Navigator(
        key: moreTabNavigatorKey,
        initialRoute: '/', // Define a rota inicial
        // Gera as rotas para a navegação interna
        onGenerateRoute: (RouteSettings settings) {
          WidgetBuilder builder;
          switch (settings.name) {
            case '/leagues':
              builder = (BuildContext _) => const LeaguesScreen();
              break;
            case '/profile':
              builder = (BuildContext _) => const ProfileScreen();
              break;
            case '/':
            default:
              builder = (BuildContext _) => const _MoreOptionsList();
          }
          return MaterialPageRoute(builder: builder, settings: settings);
        },
      ),
    );
  }
}

// Widget privado para a tela inicial da aba "Mais", que mostra a lista de opções
class _MoreOptionsList extends StatelessWidget {
  const _MoreOptionsList();

  @override
  Widget build(BuildContext context) {
    // Esta tela não precisa do GradientBackground, pois a MainNavigationScreen já o fornece
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Mais Opções',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 24,
                color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.shield, color: Colors.white),
            title: const Text('Ligas', style: TextStyle(color: Colors.white)),
            trailing: const Icon(Icons.arrow_forward_ios,
                color: Colors.white54, size: 16),
            onTap: () {
              // Navega DENTRO do Navigator aninhado da aba "Mais"
              Navigator.of(context).pushNamed('/leagues');
            },
          ),
          ListTile(
            leading: const Icon(Icons.person, color: Colors.white),
            title: const Text('Perfil', style: TextStyle(color: Colors.white)),
            trailing: const Icon(Icons.arrow_forward_ios,
                color: Colors.white54, size: 16),
            onTap: () {
              // Navega DENTRO do Navigator aninhado da aba "Mais"
              Navigator.of(context).pushNamed('/profile');
            },
          ),
        ],
      ),
    );
  }
}
