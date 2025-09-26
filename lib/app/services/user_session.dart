// lib/app/services/user_session.dart

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:musilingo/app/core/result.dart';
import 'package:musilingo/app/data/models/user_profile_model.dart';
import 'package:musilingo/app/services/database_service.dart';
import 'package:musilingo/app/services/teacher_service.dart'; // Import necessário
import 'package:musilingo/main.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserSession extends ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();
  final TeacherService _teacherService =
      TeacherService(); // Instância do serviço

  UserProfile? _currentUser;
  UserProfile? _currentTeacher; // Novo campo para guardar o professor
  bool _isLoading = false;

  UserProfile? get currentUser => _currentUser;
  UserProfile? get currentTeacher => _currentTeacher; // Getter para o professor
  bool get isLoading => _isLoading;

  Future<void> initializeSession() async {
    _isLoading = true;
    _currentTeacher = null; // Limpa o professor antigo ao iniciar
    notifyListeners();

    final supabaseUser = Supabase.instance.client.auth.currentUser;
    if (supabaseUser != null) {
      // Carrega o perfil do utilizador atual
      final profileResult = await _databaseService.getProfile(supabaseUser.id);
      switch (profileResult) {
        case Success<UserProfile?>(data: final profile):
          _currentUser = profile;
          if (_currentUser != null) {
            // Se o utilizador for um aluno, tenta carregar o professor
            if (_currentUser!.roleId == 1) {
              _currentTeacher = await _teacherService.getCurrentTeacher();
            }
            await _checkAndUpdateStreak();
          }
        case Failure<UserProfile?>():
          // Error handling for failed profile load
          break;
      }
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> createProfile(User user) async {
    final result = await _databaseService.createProfileOnLogin(user);
    switch (result) {
      case Success<UserProfile>(data: final profile):
        _currentUser = profile;
      case Failure<UserProfile>():
        // Error handling
        break;
    }
    notifyListeners();
  }

  Future<void> _checkAndUpdateStreak() async {
    if (_currentUser == null) return;

    final lastPracticeStr = _currentUser!.lastPracticeDate;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (lastPracticeStr != null && lastPracticeStr.isNotEmpty) {
      final lastPracticeDate = DateTime.parse(lastPracticeStr);
      final lastPracticeDay = DateTime(
          lastPracticeDate.year, lastPracticeDate.month, lastPracticeDate.day);

      final difference = today.difference(lastPracticeDay).inDays;

      if (difference > 1) {
        _currentUser = _currentUser!.copyWith(currentStreak: 0);
        await _databaseService.updateStats(
          userId: _currentUser!.id,
          currentStreak: 0,
        );
      }
    }
    notifyListeners();
  }

  Future<void> recordPractice() async {
    if (_currentUser == null) return;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastPracticeStr = _currentUser!.lastPracticeDate;
    bool streakUpdated = false;

    if (lastPracticeStr != null && lastPracticeStr.isNotEmpty) {
      final lastPracticeDate = DateTime.parse(lastPracticeStr);
      final lastPracticeDay = DateTime(
          lastPracticeDate.year, lastPracticeDate.month, lastPracticeDate.day);

      if (lastPracticeDay.isBefore(today)) {
        final difference = today.difference(lastPracticeDay).inDays;
        if (difference == 1) {
          _currentUser = _currentUser!
              .copyWith(currentStreak: _currentUser!.currentStreak + 1);
        } else {
          _currentUser = _currentUser!.copyWith(currentStreak: 1);
        }
        streakUpdated = true;
      }
    } else {
      _currentUser = _currentUser!.copyWith(currentStreak: 1);
      streakUpdated = true;
    }

    _currentUser =
        _currentUser!.copyWith(lastPracticeDate: now.toIso8601String());

    await _databaseService.updateStats(
      userId: _currentUser!.id,
      lastPracticeDate: _currentUser!.lastPracticeDate,
      currentStreak: streakUpdated ? _currentUser!.currentStreak : null,
    );

    notifyListeners();
  }

  Future<void> answerCorrectly() async {
    if (_currentUser == null) return;

    try {
      await supabase
          .rpc('handle_correct_answer', params: {'p_points_to_add': 10});

      _currentUser = _currentUser!.copyWith(
        points: _currentUser!.points + 10,
        correctAnswers: _currentUser!.correctAnswers + 1,
      );

      notifyListeners();
    } catch (error) {
      debugPrint("Erro ao chamar handle_correct_answer: $error");
    }
  }

  Future<void> answerWrongly() async {
    if (_currentUser == null || _currentUser!.lives <= 0) return;

    try {
      await supabase.rpc('handle_wrong_answer');

      _currentUser = _currentUser!.copyWith(
        lives: _currentUser!.lives - 1,
        wrongAnswers: _currentUser!.wrongAnswers + 1,
      );

      notifyListeners();
    } catch (error) {
      debugPrint("Erro ao chamar handle_wrong_answer: $error");
    }
  }

  Future<void> updateAvatar(File image) async {
    if (_currentUser == null) return;
    _isLoading = true;
    notifyListeners();
    try {
      final result = await _databaseService.uploadAvatar(_currentUser!.id, image);
      switch (result) {
        case Success<String>(data: final avatarUrl):
          _currentUser = _currentUser!.copyWith(avatarUrl: avatarUrl);
        case Failure<String>(errorMessage: final error):
          debugPrint("Erro ao atualizar avatar: $error");
      }
    } catch (e) {
      debugPrint("Erro ao atualizar avatar: $e");
    }
    _isLoading = false;
    notifyListeners();
  }

  void clearSession() {
    _currentUser = null;
    _currentTeacher = null; // Limpa o professor ao sair
    notifyListeners();
  }
}
