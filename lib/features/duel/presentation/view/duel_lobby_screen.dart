// lib/features/duel/presentation/view/duel_lobby_screen.dart

import 'package:flutter/material.dart';
import 'package:musilingo/app/core/theme/app_colors.dart';
import 'package:musilingo/app/presentation/widgets/gradient_background.dart';
import 'package:musilingo/app/services/user_session.dart';
import 'package:musilingo/features/duel/data/models/duel_models.dart';
import 'package:musilingo/features/duel/presentation/view/duel_screen.dart';
import 'package:musilingo/features/duel/services/duel_service.dart';
import 'package:provider/provider.dart' as provider;

class DuelLobbyScreen extends StatefulWidget {
  const DuelLobbyScreen({super.key});

  @override
  State<DuelLobbyScreen> createState() => _DuelLobbyScreenState();
}

class _DuelLobbyScreenState extends State<DuelLobbyScreen> {
  late final DuelService _duelService;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _duelService = DuelService();
    _duelService.participantsStream.listen((participants) {
      if (participants.length == 2 && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => DuelScreen(duelId: _duelService.currentDuelId!),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    if (_isSearching) {
      _duelService.cancelSearch();
    }
    _duelService.dispose();
    super.dispose();
  }

  void _startSearch() {
    setState(() {
      _isSearching = true;
    });
    final userId = context.read<UserSession>().currentUser?.id;
    if (userId != null) {
      _duelService.findOrCreateDuel(userId);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Você precisa estar logado para duelar.')),
      );
      setState(() {
        _isSearching = false;
      });
    }
  }

  void _cancelSearch() {
    setState(() {
      _isSearching = false;
    });
    _duelService.cancelSearch();
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Duelo dos Mestres'),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: _isSearching ? _buildSearchingView() : _buildInitialView(),
          ),
        ),
      ),
    );
  }

  Widget _buildInitialView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.shield, size: 120, color: AppColors.accent),
        const SizedBox(height: 24),
        const Text('Desafie um Mestre!',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        const Text(
            'Entre na fila para encontrar um oponente e teste seus conhecimentos em um duelo em tempo real.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: AppColors.textSecondary)),
        const SizedBox(height: 48),
        ElevatedButton(
          onPressed: _startSearch,
          style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding:
                  const EdgeInsets.symmetric(horizontal: 48, vertical: 16)),
          child: const Text('Procurar Duelo', style: TextStyle(fontSize: 18)),
        ),
      ],
    );
  }

  Widget _buildSearchingView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('Procurando Oponente...',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 32),
        const CircularProgressIndicator(color: AppColors.accent),
        const SizedBox(height: 32),
        StreamBuilder<List<DuelParticipant>>(
          stream: _duelService.participantsStream,
          builder: (context, snapshot) {
            final participants = snapshot.data ?? [];
            final currentUserId = context.read<UserSession>().currentUser?.id;
            DuelParticipant? currentUserParticipant;
            DuelParticipant? opponentParticipant;
            if (currentUserId != null) {
              currentUserParticipant = participants
                  .cast<DuelParticipant?>()
                  .firstWhere((p) => p?.userId == currentUserId,
                      orElse: () => null);
              opponentParticipant = participants
                  .cast<DuelParticipant?>()
                  .firstWhere((p) => p?.userId != currentUserId,
                      orElse: () => null);
            }
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildPlayerCard(currentUserParticipant, isCurrentUser: true),
                const Text('VS',
                    style:
                        TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                _buildPlayerCard(opponentParticipant, isCurrentUser: false),
              ],
            );
          },
        ),
        const SizedBox(height: 48),
        TextButton(
          onPressed: _cancelSearch,
          child: const Text('Cancelar Busca',
              style: TextStyle(color: AppColors.primary, fontSize: 16)),
        ),
      ],
    );
  }

  Widget _buildPlayerCard(DuelParticipant? participant,
      {required bool isCurrentUser}) {
    // CORREÇÃO: Removido o acesso a `user.username`, que causava o erro.
    // O nome correto virá do objeto `participant` quando o stream for atualizado.
    final placeholderUsername = isCurrentUser ? 'Você' : 'Aguardando...';
    return Column(
      children: [
        CircleAvatar(
          radius: 40,
          backgroundColor: AppColors.card,
          child: participant == null && !isCurrentUser
              ? const Icon(Icons.person_outline,
                  size: 40, color: AppColors.textSecondary)
              : const Icon(Icons.person, size: 40),
        ),
        const SizedBox(height: 8),
        Text(participant?.username ?? placeholderUsername,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
