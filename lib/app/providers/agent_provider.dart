// lib/app/providers/agent_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musilingo/app/controllers/agent_controller.dart';
import 'package:musilingo/app/services/ai_service.dart';

final aiServiceProvider = Provider<AIService>((ref) => AIService());

final agentControllerProvider = StateNotifierProvider<AgentController, AgentState>((ref) {
  final aiService = ref.watch(aiServiceProvider);
  return AgentController(aiService);
});