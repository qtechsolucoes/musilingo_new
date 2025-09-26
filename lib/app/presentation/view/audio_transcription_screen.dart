// lib/app/presentation/view/audio_transcription_screen.dart

import 'package:flutter/material.dart';
import 'package:musilingo/app/core/theme/app_colors.dart';
import 'package:musilingo/app/presentation/widgets/gradient_background.dart';
import 'package:musilingo/app/presentation/widgets/score_viewer_widget.dart';
// CORREÇÃO: Importa o AIService para que possamos passá-lo para o TranscriptionService
import 'package:musilingo/app/services/ai_service.dart';
import 'package:musilingo/app/services/transcription_service.dart';

// Enum para gerenciar o estado da tela de forma clara e segura.
enum _TranscriptionState { ready, recording, processing, success, error }

class AudioTranscriptionScreen extends StatefulWidget {
  const AudioTranscriptionScreen({super.key});

  @override
  State<AudioTranscriptionScreen> createState() =>
      _AudioTranscriptionScreenState();
}

class _AudioTranscriptionScreenState extends State<AudioTranscriptionScreen> {
  // CORREÇÃO: Inicializa o TranscriptionService passando a dependência do AIService.
  final TranscriptionService _transcriptionService =
      TranscriptionService(AIService());

  _TranscriptionState _state = _TranscriptionState.ready;
  String _musicXml = '';
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _initializeService();
  }

  Future<void> _initializeService() async {
    try {
      await _transcriptionService.initialize();
    } catch (e) {
      if (mounted) {
        setState(() {
          _state = _TranscriptionState.error;
          _errorMessage = 'Erro ao inicializar o gravador: ${e.toString()}';
        });
      }
    }
  }

  @override
  void dispose() {
    _transcriptionService.dispose();
    super.dispose();
  }

  Future<void> _handleMicButtonPressed() async {
    switch (_state) {
      case _TranscriptionState.recording:
        setState(() {
          _state = _TranscriptionState.processing;
        });
        try {
          final musicXml =
              await _transcriptionService.stopRecordingAndTranscribe();
          setState(() {
            _musicXml = musicXml;
            _state = _TranscriptionState.success;
          });
        } catch (e) {
          setState(() {
            _errorMessage = e.toString().replaceFirst('Exception: ', '');
            _state = _TranscriptionState.error;
          });
        }
        break;
      case _TranscriptionState.ready:
      case _TranscriptionState.success:
      case _TranscriptionState.error:
        await _transcriptionService.startRecording();
        setState(() {
          _musicXml = '';
          _errorMessage = '';
          _state = _TranscriptionState.recording;
        });
        break;
      case _TranscriptionState.processing:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Cantar para Partitura'),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: _buildContentForState(),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: _buildActionButtonForState(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContentForState() {
    switch (_state) {
      case _TranscriptionState.processing:
        return const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 20),
            Text('Analisando sua melodia...',
                style: TextStyle(color: Colors.white70)),
          ],
        );
      case _TranscriptionState.success:
        return ScoreViewerWidget(musicXML: _musicXml);
      case _TranscriptionState.error:
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            'Ocorreu um erro:\n$_errorMessage',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.error, fontSize: 16),
          ),
        );
      case _TranscriptionState.recording:
        return const Text(
          'Gravando... 🎤',
          style: TextStyle(color: Colors.white, fontSize: 22),
        );
      case _TranscriptionState.ready:
        return const Text(
          'Toque no microfone para começar a cantar',
          style: TextStyle(color: Colors.white70, fontSize: 18),
        );
    }
  }

  Widget _buildActionButtonForState() {
    IconData icon;
    Color color;
    String? tooltip;

    switch (_state) {
      case _TranscriptionState.ready:
        icon = Icons.mic;
        color = AppColors.accent;
        tooltip = 'Começar a gravar';
        break;
      case _TranscriptionState.recording:
        icon = Icons.stop;
        color = Colors.red;
        tooltip = 'Parar gravação';
        break;
      case _TranscriptionState.processing:
        icon = Icons.hourglass_empty;
        color = Colors.grey;
        tooltip = 'Processando...';
        break;
      case _TranscriptionState.success:
        icon = Icons.replay;
        color = AppColors.accent;
        tooltip = 'Gravar novamente';
        break;
      case _TranscriptionState.error:
        icon = Icons.replay;
        color = AppColors.accent;
        tooltip = 'Tentar novamente';
        break;
    }

    return FloatingActionButton.large(
      onPressed: _state == _TranscriptionState.processing
          ? null
          : _handleMicButtonPressed,
      backgroundColor: color,
      tooltip: tooltip,
      child: Icon(icon, color: Colors.white, size: 36),
    );
  }
}
