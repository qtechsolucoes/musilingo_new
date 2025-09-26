// lib/app/services/sfx_service.dart

import 'package:just_audio/just_audio.dart';

class SfxService {
  // Padrão Singleton para ter uma única instância do serviço
  SfxService._privateConstructor();
  static final SfxService instance = SfxService._privateConstructor();

  final _clickPlayer = AudioPlayer();
  final _lessonCompletePlayer = AudioPlayer();
  final _errorPlayer = AudioPlayer();
  final _correctAnswerPlayer = AudioPlayer();

  Future<void> loadSounds() async {
    // Pré-carrega os sons para uma reprodução mais rápida
    await _clickPlayer.setAsset('assets/audio/click.wav');
    await _lessonCompletePlayer.setAsset('assets/audio/success.mp3');
    await _errorPlayer.setAsset('assets/audio/error.mp3');
    await _correctAnswerPlayer.setAsset('assets/audio/correct.mp3');

    // **** NOVO: Define um volume fixo e mais baixo para o clique ****
    // O valor 0.4 representa 40% do volume máximo. Você pode ajustar se preferir.
    await _clickPlayer.setVolume(0.4);

    await _clickPlayer.load();
    await _lessonCompletePlayer.load();
    await _errorPlayer.load();
    await _correctAnswerPlayer.load();
  }

  void playClick() {
    _clickPlayer.seek(Duration.zero);
    _clickPlayer.play();
  }

  void playLessonComplete() {
    _lessonCompletePlayer.seek(Duration.zero);
    _lessonCompletePlayer.play();
  }

  void playError() {
    _errorPlayer.seek(Duration.zero);
    _errorPlayer.play();
  }

  void playCorrectAnswer() {
    _correctAnswerPlayer.seek(Duration.zero);
    _correctAnswerPlayer.play();
  }

  void dispose() {
    _clickPlayer.dispose();
    _lessonCompletePlayer.dispose();
    _errorPlayer.dispose();
    _correctAnswerPlayer.dispose();
  }
}
