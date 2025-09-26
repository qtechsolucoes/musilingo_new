// lib/app/presentation/view/chat_screen.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musilingo/app/controllers/agent_controller.dart';
import 'package:musilingo/app/models/chat_message_model.dart';
import 'package:musilingo/app/models/game_action_model.dart';
import 'package:musilingo/app/services/gamification_service.dart';
import 'package:musilingo/app/presentation/widgets/gradient_background.dart';
import 'package:musilingo/app/core/theme/app_colors.dart';
import 'package:musilingo/app/services/score_translator_service.dart';
import 'package:musilingo/app/presentation/widgets/score_viewer_widget.dart';
import 'package:musilingo/app/services/unified_midi_service.dart';
import 'package:musilingo/app/presentation/widgets/score_fullscreen_modal.dart';
import 'package:musilingo/app/core/service_registry.dart';
import 'package:musilingo/widgets/animated_score_widget.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _promptController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final GamificationService _gamificationService = ServiceRegistry.get<GamificationService>();
  final ScoreTranslatorService _scoreTranslator = ScoreTranslatorService();
  final UnifiedMidiService _midiService = ServiceRegistry.get<UnifiedMidiService>();

  final List<ChatMessage> _messages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _messages.add(
      ChatMessage(
        text:
            'Olá! Eu sou a Cecília, sua assistente de IA especializada em música. Como posso ajudar você hoje? 🎵',
        sender: MessageSender.ai,
      ),
    );
  }

  @override
  void dispose() {
    _promptController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _promptController.text.trim();
    if (text.isEmpty || _isLoading) return;

    final userMessage = ChatMessage(text: text, sender: MessageSender.user);

    setState(() {
      _messages.add(userMessage);
      _isLoading = true;
    });
    _promptController.clear();
    _scrollToBottom();

    try {
      // FASE 4.3: Detectar comando de criação de partitura
      if (_isScoreCreationCommand(text)) {
        await _handleScoreCreation(text);
        return;
      }

      final agentNotifier = ref.read(agentControllerProvider.notifier);
      final fullResponseText = await agentNotifier.startChat(List.of(_messages));

      String messageText = fullResponseText;
      String? musicXml;
      List<Map<String, dynamic>>? scoreNotes;

      const jsonStartMarker = '```json';
      const jsonEndMarker = '```';
      final jsonStartIndex = fullResponseText.indexOf(jsonStartMarker);

      if (jsonStartIndex != -1) {
        final jsonEndIndex = fullResponseText.indexOf(
            jsonEndMarker, jsonStartIndex + jsonStartMarker.length);

        if (jsonEndIndex != -1) {
          messageText = fullResponseText.substring(0, jsonStartIndex).trim();
          final jsonString = fullResponseText
              .substring(jsonStartIndex + jsonStartMarker.length, jsonEndIndex)
              .trim();

          try {
            final scoreData = jsonDecode(jsonString);
            if (scoreData['score'] != null) {
              musicXml =
                  _scoreTranslator.convertJsonToMusicXml(scoreData['score']);
              scoreNotes = List<Map<String, dynamic>>.from(
                  scoreData['score']['notes'] ?? []);
            }
          } catch (e) {/* silent fail */}
        }
      }

      final agentResponse = agentNotifier.processFullResponse(messageText);

      setState(() {
        _messages.add(ChatMessage(
          text: agentResponse.message,
          sender: MessageSender.ai,
          actions: agentResponse.actions,
          musicXml: musicXml,
          scoreNotes: scoreNotes,
        ));
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add(ChatMessage(
            text:
                "Desculpe, ocorreu um erro. Verifique sua conexão e tente novamente.",
            sender: MessageSender.ai,
          ));
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _scrollToBottom();
      }
    }
  }

  // FASE 4.3: Métodos para comando de criação de partitura
  bool _isScoreCreationCommand(String text) {
    final lowerText = text.toLowerCase();
    final scoreKeywords = [
      'crie uma partitura',
      'criar partitura',
      'gere uma partitura',
      'gerar partitura',
      'faça uma partitura',
      'fazer partitura',
      'compose uma música',
      'compor música',
      'escreva uma partitura',
      'escrever partitura'
    ];

    return scoreKeywords.any((keyword) => lowerText.contains(keyword));
  }

  Future<void> _handleScoreCreation(String prompt) async {
    try {
      // Adicionar mensagem de confirmação do comando
      final confirmMessage = ChatMessage(
        text: '🎵 Entendi! Vou criar uma partitura para você. Acompanhe o processo:',
        sender: MessageSender.ai,
      );

      setState(() {
        _messages.add(confirmMessage);
        _isLoading = false; // Não queremos mostrar o loading padrão
      });
      _scrollToBottom();

      // Adicionar o widget de partitura animada
      final scoreWidget = ChatMessage(
        text: '',
        sender: MessageSender.ai,
        hasCustomWidget: true,
        customWidget: AnimatedScoreWidget(
          prompt: prompt,
          height: 300,
          onCompleted: () {
            // Partitura criada com sucesso
            final successMessage = ChatMessage(
              text: '✨ Partitura criada com sucesso! Você pode visualizar, tocar ou baixar a partitura acima.',
              sender: MessageSender.ai,
            );

            setState(() {
              _messages.add(successMessage);
            });
            _scrollToBottom();

            // Gamificação: dar pontos pela criação de partitura
            _gamificationService.addPoints(50, reason: 'Criação de partitura via IA');
          },
          onError: (error) {
            // Erro na criação
            final errorMessage = ChatMessage(
              text: '❌ Ocorreu um erro ao criar a partitura: $error. Tente novamente com um comando mais específico.',
              sender: MessageSender.ai,
            );

            setState(() {
              _messages.add(errorMessage);
            });
            _scrollToBottom();
          },
        ),
      );

      setState(() {
        _messages.add(scoreWidget);
        _isLoading = false;
      });
      _scrollToBottom();

    } catch (e) {
      final errorMessage = ChatMessage(
        text: '❌ Erro inesperado ao processar comando de criação de partitura: $e',
        sender: MessageSender.ai,
      );

      setState(() {
        _messages.add(errorMessage);
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  void _handleGameAction(GameAction action) {
    String message = 'Ação recebida!';
    Color backgroundColor = AppColors.completed;

    if (action is AddPointsAction) {
      _gamificationService.addPoints(action.points, reason: action.reason);
      message = 'Você ganhou ${action.points} pontos por: ${action.reason}';
      backgroundColor = AppColors.accent;
    } else if (action is ShowChallengeAction) {
      message = 'Desafio sobre "${action.topic}" iniciado!';
    } else if (action is StartPracticeAction) {
      message =
          'Iniciando prática de "${action.topic}" (dificuldade ${action.difficulty}).';
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message, style: const TextStyle(color: Colors.white)),
          backgroundColor: backgroundColor,
        ),
      );
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Chat com Cecília'),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(8.0),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final message = _messages[index];
                    final isUser = message.sender == MessageSender.user;

                    return isUser
                        ? _buildUserMessage(message)
                        : _buildCeciliaMessage(message);
                  },
                ),
              ),
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: LinearProgressIndicator(color: AppColors.accent),
                ),
              _buildTextInputArea(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCeciliaMessage(ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.card,
            backgroundImage: AssetImage('assets/images/cecilia_chat.png'),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message.text,
                        style:
                            const TextStyle(color: Colors.white, fontSize: 16),
                      ),
                      if (message.actions.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: message.actions
                              .map((action) => _buildActionButton(action))
                              .toList(),
                        )
                      ]
                    ],
                  ),
                ),
                // FASE 4.3: Widget customizado (partitura animada)
                if (message.hasCustomWidget && message.customWidget != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12.0),
                    child: message.customWidget!,
                  ),
                // Widget de partitura tradicional
                if (message.musicXml != null && message.musicXml!.isNotEmpty)
                  _buildScoreWidget(message),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreWidget(ChatMessage message) {
    // Chave única para este widget de partitura específico
    final scoreViewerKey = GlobalKey<ScoreViewerWidgetState>();

    return Padding(
      padding: const EdgeInsets.only(top: 12.0),
      child: Column(
        children: [
          // A Partitura Rolável com Indicador
          SizedBox(
            height: 150,
            child: Stack(
              alignment: Alignment.centerRight,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Container(
                      width: 600,
                      color: Colors.transparent,
                      child: ScoreViewerWidget(
                        key: scoreViewerKey,
                        musicXML: message.musicXml!,
                      ),
                    ),
                  ),
                ),
                // Indicador de "arraste para o lado"
                IgnorePointer(
                  child: Container(
                    width: 50,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          // ignore: deprecated_member_use
                          AppColors.background.withOpacity(0.0),
                          // ignore: deprecated_member_use
                          AppColors.background.withOpacity(0.8),
                        ],
                      ),
                    ),
                    child: Icon(
                      Icons.arrow_forward_ios,
                      // ignore: deprecated_member_use
                      color: Colors.white.withOpacity(0.5),
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Botões de Ação
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Botão Play
              TextButton.icon(
                icon: const Icon(Icons.play_arrow, size: 20),
                label: const Text('Tocar'),
                style: TextButton.styleFrom(foregroundColor: AppColors.accent),
                onPressed: () async {
                  if (message.scoreNotes != null) {
                    await _midiService.playNoteSequence(
                      notes: message.scoreNotes!,
                      tempo: 120, // Tempo padrão
                      onNotePlayed: (noteIndex) {
                        scoreViewerKey.currentState
                            ?.colorNote(noteIndex, '#FFDD00');
                      },
                      onPlaybackComplete: () {
                        scoreViewerKey.currentState?.clearAllNoteColors();
                      },
                    );
                  }
                },
              ),
              const SizedBox(width: 8),
              // Botão Tela Cheia
              TextButton.icon(
                icon: const Icon(Icons.fullscreen, size: 20),
                label: const Text('Expandir'),
                style: TextButton.styleFrom(foregroundColor: AppColors.accent),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ScoreFullscreenModal(
                        musicXml: message.musicXml!,
                        scoreNotes: message.scoreNotes!,
                        midiService: _midiService,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  // O resto dos widgets permanecem os mesmos
  Widget _buildUserMessage(ChatMessage message) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(16.0),
        ),
        child: Text(
          message.text,
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
      ),
    );
  }

  Widget _buildActionButton(GameAction action) {
    String label = 'Ação';
    IconData icon = Icons.play_arrow;

    if (action is ShowChallengeAction) {
      label = 'Aceitar Desafio';
      icon = Icons.gamepad_outlined;
    } else if (action is AddPointsAction) {
      label = '+${action.points} XP';
      icon = Icons.star_border;
    } else if (action is StartPracticeAction) {
      label = 'Praticar Agora';
      icon = Icons.music_note_outlined;
    }

    return ActionChip(
      backgroundColor: AppColors.accent.withAlpha(77),
      labelStyle: const TextStyle(color: Colors.white),
      avatar: Icon(icon, size: 16, color: Colors.white),
      label: Text(label),
      onPressed: () => _handleGameAction(action),
    );
  }

  Widget _buildTextInputArea() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _promptController,
              decoration: InputDecoration(
                hintText: 'Pergunte sobre música...',
                hintStyle: const TextStyle(color: AppColors.textSecondary),
                filled: true,
                fillColor: AppColors.card.withAlpha(204),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25.0),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20.0),
              ),
              style: const TextStyle(color: Colors.white),
              onSubmitted: _isLoading ? null : (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            icon: const Icon(Icons.send),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
            ),
            onPressed: _isLoading ? null : _sendMessage,
          ),
        ],
      ),
    );
  }
}
