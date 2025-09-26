// lib/features/duel/presentation/view/duel_screen.dart

import 'package:flutter/material.dart';
import 'package:musilingo/app/core/theme/app_colors.dart';
import 'package:musilingo/app/presentation/widgets/gradient_background.dart';
import 'package:musilingo/app/services/user_session.dart';
import 'package:musilingo/features/duel/data/models/duel_models.dart';
import 'package:musilingo/features/duel/services/duel_service.dart';
import 'package:provider/provider.dart' as provider;

class DuelScreen extends StatefulWidget {
  final String duelId;
  const DuelScreen({super.key, required this.duelId});

  @override
  State<DuelScreen> createState() => _DuelScreenState();
}

class _DuelScreenState extends State<DuelScreen> {
  late final DuelService _duelService;
  int _currentQuestionIndex = 0;

  @override
  void initState() {
    super.initState();
    _duelService = DuelService();
    _duelService.listenToDuelUpdates(widget.duelId);

    _duelService.questionsStream.listen((questions) {
      if (questions.isNotEmpty && mounted) {
        final nextQuestionIndex =
            questions.indexWhere((q) => q.answeredByUserId == null);
        final newIndex =
            nextQuestionIndex == -1 ? questions.length : nextQuestionIndex;
        if (newIndex != _currentQuestionIndex) {
          setState(() {
            _currentQuestionIndex = newIndex;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _duelService.dispose();
    super.dispose();
  }

  void _handleAnswer(String answer, DuelQuestion question) {
    final userId = context.read<UserSession>().currentUser?.id;
    if (userId != null) {
      _duelService.submitAnswer(question.id, answer, userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = context.watch<UserSession>().currentUser?.id;
    if (userId == null) {
      return const Center(child: Text("Erro: Usuário não encontrado."));
    }

    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Duelo em Andamento'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          automaticallyImplyLeading: false,
        ),
        body: StreamBuilder<List<DuelParticipant>>(
          stream: _duelService.participantsStream,
          builder: (context, participantsSnapshot) {
            if (!participantsSnapshot.hasData ||
                participantsSnapshot.data!.length < 2) {
              return const Center(child: CircularProgressIndicator());
            }
            final participants = participantsSnapshot.data!;
            final currentUser =
                participants.firstWhere((p) => p.userId == userId);
            final opponent = participants.firstWhere((p) => p.userId != userId);

            return Column(
              children: [
                _buildScoreHeader(currentUser, opponent),
                Expanded(
                  child: StreamBuilder<List<DuelQuestion>>(
                    stream: _duelService.questionsStream,
                    builder: (context, questionsSnapshot) {
                      if (!questionsSnapshot.hasData ||
                          questionsSnapshot.data!.isEmpty) {
                        return const Center(
                            child: Text('Aguardando perguntas...'));
                      }
                      final questions = questionsSnapshot.data!;
                      if (_currentQuestionIndex >= questions.length) {
                        return _buildDuelFinishedView(currentUser, opponent);
                      }
                      final currentQuestion = questions[_currentQuestionIndex];
                      return _buildQuestionView(currentQuestion);
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildScoreHeader(
      DuelParticipant currentUser, DuelParticipant opponent) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildPlayerInfo(currentUser),
          const Text('VS',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          _buildPlayerInfo(opponent),
        ],
      ),
    );
  }

  Widget _buildPlayerInfo(DuelParticipant participant) {
    return Column(
      children: [
        const CircleAvatar(
          radius: 30,
          backgroundColor: AppColors.card,
        ),
        const SizedBox(height: 8),
        Text(participant.username ?? 'Jogador',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        Text('${participant.score} pts',
            style: const TextStyle(
                color: AppColors.accent, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildQuestionView(DuelQuestion question) {
    final bool isAnswered = question.answeredByUserId != null;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            question.questionText,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 40),
          ...question.options.map((option) {
            Color buttonColor = AppColors.primary;
            if (isAnswered) {
              if (option == question.correctAnswer) {
                buttonColor = AppColors.completed;
              } else {
                buttonColor = AppColors.error;
              }
            }

            // CORREÇÃO: Adicionado 'const' para otimização de performance.
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: ElevatedButton(
                onPressed:
                    isAnswered ? null : () => _handleAnswer(option, question),
                style: ElevatedButton.styleFrom(
                  backgroundColor: buttonColor,
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: Text(option, style: const TextStyle(fontSize: 18)),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildDuelFinishedView(
      DuelParticipant currentUser, DuelParticipant opponent) {
    final bool isWinner = currentUser.score > opponent.score;
    final String title = isWinner ? 'Você Venceu!' : 'Você Perdeu!';
    final IconData icon =
        isWinner ? Icons.emoji_events : Icons.sentiment_dissatisfied;
    final Color color = isWinner ? AppColors.accent : AppColors.error;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 100, color: color),
          const SizedBox(height: 24),
          Text(title,
              style: TextStyle(
                  fontSize: 32, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 48),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Voltar aos Desafios'),
          )
        ],
      ),
    );
  }
}
