// lib/app/services/transcription_service.dart

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:musilingo/app/core/result.dart';
import 'package:musilingo/app/services/ai_service.dart';

class TranscriptionService {
  final AIService _aiService;
  FlutterSoundRecorder? _recorder;
  bool _isInitialized = false;
  String? _filePath;

  TranscriptionService(this._aiService);

  Future<void> initialize() async {
    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      throw Exception('Permissão de microfone negada');
    }

    _recorder = FlutterSoundRecorder();
    await _recorder!.openRecorder();
    _isInitialized = true;
  }

  Future<void> dispose() async {
    try {
      if (_recorder != null && _recorder!.isRecording) {
        await _recorder!.stopRecorder();
      }
      if (_recorder != null) {
        await _recorder!.closeRecorder();
      }
      _recorder = null;

      // Limpar arquivos temporários
      if (_filePath != null && File(_filePath!).existsSync()) {
        await File(_filePath!).delete();
        _filePath = null;
      }

      _isInitialized = false;
    } catch (e) {
      debugPrint('Erro ao fazer dispose do TranscriptionService: $e');
    }
  }

  Future<void> startRecording() async {
    if (!_isInitialized) throw Exception('Serviço não inicializado.');
    final tempDir = await getTemporaryDirectory();
    _filePath = '${tempDir.path}/audio.wav';
    await _recorder!.startRecorder(toFile: _filePath, codec: Codec.pcm16WAV);
  }

  Future<String> stopRecordingAndTranscribe() async {
    if (!_isInitialized) throw Exception('Serviço não inicializado.');
    await _recorder!.stopRecorder();
    if (_filePath == null || !File(_filePath!).existsSync()) {
      throw Exception('Nenhum áudio gravado.');
    }

    // CORREÇÃO: Crie um objeto File a partir do caminho (_filePath) antes de enviá-lo.
    final file = File(_filePath!);
    final result = await _aiService.transcribeAudio(file);
    return switch (result) {
      Success<String>(data: final data) => data,
      Failure<String>(errorMessage: final error) => throw Exception('Erro na transcrição: $error'),
    };
  }
}
