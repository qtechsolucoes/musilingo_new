// lib/app/models/chat_message_model.dart

import 'package:flutter/material.dart';
import 'package:musilingo/app/models/game_action_model.dart';

enum MessageSender { user, ai }

class ChatMessage {
  final String text;
  final MessageSender sender;
  final List<GameAction> actions;
  final String? musicXml;

  // ✅ --- NOVO CAMPO ADICIONADO --- ✅
  // Guarda a lista de notas (pitch/duration) para ser usada pelo serviço de MIDI.
  final List<Map<String, dynamic>>? scoreNotes;

  // FASE 4.3: Suporte para widgets customizados
  final bool hasCustomWidget;
  final Widget? customWidget;

  ChatMessage({
    required this.text,
    required this.sender,
    this.actions = const [],
    this.musicXml,
    this.scoreNotes, // ✅ Adicionado ao construtor
    this.hasCustomWidget = false,
    this.customWidget,
  });

  // getter para compatibilidade com o service
  String get role => sender == MessageSender.user ? 'user' : 'assistant';

  // getter para compatibilidade com o service
  String get content => text;

  // Construtor para criar mensagem a partir do formato do service (se necessário)
  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      text: map['content'] ?? '',
      sender: (map['role'] == 'user') ? MessageSender.user : MessageSender.ai,
      // Os campos musicXml e scoreNotes são adicionados posteriormente
      // na tela de chat, após o processamento da resposta da IA.
    );
  }
}
