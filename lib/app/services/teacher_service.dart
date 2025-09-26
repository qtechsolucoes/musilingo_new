// lib/app/services/teacher_service.dart

import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:musilingo/app/data/models/user_profile_model.dart';
import 'package:musilingo/main.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TeacherService {
  Future<String?> getOrGenerateTeacherCode(String userId) async {
    try {
      final profileResponse = await supabase
          .from('profiles')
          .select('teacher_code')
          .eq('id', userId)
          .single();

      final existingCode = profileResponse['teacher_code'];

      if (existingCode != null && (existingCode as String).isNotEmpty) {
        return existingCode;
      } else {
        String newCode = '';
        bool isCodeUnique = false;

        while (!isCodeUnique) {
          newCode = _generateRandomCode(6);
          final checkResponse = await supabase
              .from('profiles')
              .select('id')
              .eq('teacher_code', newCode)
              .limit(1);

          if (checkResponse.isEmpty) {
            isCodeUnique = true;
          }
        }

        final updateResponse = await supabase
            .from('profiles')
            .update({'teacher_code': newCode})
            .eq('id', userId)
            .select('teacher_code')
            .single();

        return updateResponse['teacher_code'];
      }
    } catch (e) {
      debugPrint('Erro ao obter ou gerar código de professor: $e');
      return null;
    }
  }

  Future<UserProfile?> connectToTeacherByCode(String code) async {
    final currentUser = supabase.auth.currentUser;
    if (currentUser == null) {
      throw 'Utilizador não autenticado.';
    }

    try {
      final teacherResponse = await supabase
          .from('profiles')
          .select()
          .eq('teacher_code', code.trim().toUpperCase())
          .eq('role_id', 2)
          .single();

      final teacherId = teacherResponse['id'];

      final existingConnection = await supabase
          .from('teacher_student_relationships')
          .select()
          .eq('student_id', currentUser.id)
          .limit(1);

      if (existingConnection.isNotEmpty) {
        throw 'Você já está conectado a um professor.';
      }

      await supabase.from('teacher_student_relationships').insert({
        'teacher_id': teacherId,
        'student_id': currentUser.id,
      });

      return UserProfile.fromMap(teacherResponse);
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST116') {
        throw 'Código de professor inválido ou não encontrado.';
      }
      debugPrint('Erro do Supabase ao conectar com professor: ${e.message}');
      throw 'Ocorreu um erro ao tentar conectar. Tente novamente.';
    } catch (e) {
      debugPrint('Erro inesperado ao conectar com professor: $e');
      rethrow;
    }
  }

  String _generateRandomCode(int length) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random.secure();
    return List.generate(length, (index) => chars[random.nextInt(chars.length)])
        .join();
  }

  Future<List<UserProfile>> searchTeachers(String query) async {
    if (query.isEmpty) {
      return [];
    }
    try {
      final response = await supabase
          .from('profiles')
          .select()
          .eq('role_id', 2)
          .ilike('full_name', '%$query%')
          .limit(10);

      final teachers = response
          .map<UserProfile>((data) => UserProfile.fromMap(data))
          .toList();
      return teachers;
    } catch (e) {
      debugPrint('Erro ao procurar professores: $e');
      return [];
    }
  }

  Future<bool> addTeacher(String teacherId) async {
    final currentUser = supabase.auth.currentUser;
    if (currentUser == null) {
      return false;
    }
    try {
      await supabase.from('teacher_student_relationships').insert({
        'teacher_id': teacherId,
        'student_id': currentUser.id,
      });
      return true;
    } on PostgrestException catch (e) {
      debugPrint('Erro no Supabase ao adicionar professor: ${e.message}');
      return false;
    } catch (e) {
      debugPrint('Erro inesperado ao adicionar professor: $e');
      return false;
    }
  }

  Future<UserProfile?> getCurrentTeacher() async {
    final currentUser = supabase.auth.currentUser;
    if (currentUser == null) {
      return null;
    }
    try {
      final response = await supabase
          .from('teacher_student_relationships')
          .select('teacher_id')
          .eq('student_id', currentUser.id)
          .single();
      final teacherId = response['teacher_id'];
      final teacherProfileResponse =
          await supabase.from('profiles').select().eq('id', teacherId).single();
      return UserProfile.fromMap(teacherProfileResponse);
    } catch (e) {
      return null;
    }
  }

  Future<List<UserProfile>> getStudents() async {
    final currentUser = supabase.auth.currentUser;
    if (currentUser == null) {
      return [];
    }
    try {
      final relationshipsResponse = await supabase
          .from('teacher_student_relationships')
          .select('student_id')
          .eq('teacher_id', currentUser.id);

      final studentIds = relationshipsResponse
          .map<String>((row) => row['student_id'] as String)
          .toList();

      if (studentIds.isEmpty) {
        return [];
      }

      final studentsResponse =
          await supabase.from('profiles').select().inFilter('id', studentIds);

      final students = studentsResponse
          .map<UserProfile>((data) => UserProfile.fromMap(data))
          .toList();

      return students;
    } catch (e) {
      debugPrint('Erro ao obter a lista de alunos: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getStudentCompletedLessons(
      String studentId) async {
    try {
      final response = await supabase
          .from('completed_lessons')
          .select('completed_at, lessons (title)')
          .eq('user_id', studentId)
          .order('completed_at', ascending: false);

      return response;
    } catch (e) {
      debugPrint('Erro ao buscar lições completas do aluno: $e');
      return [];
    }
  }

  // --- NOVA FUNÇÃO ADICIONADA ---
  /// Remove a relação entre o aluno atual e o seu professor.
  Future<void> disconnectFromTeacher() async {
    final currentUser = supabase.auth.currentUser;
    if (currentUser == null) {
      throw 'Utilizador não autenticado.';
    }
    try {
      await supabase
          .from('teacher_student_relationships')
          .delete()
          .eq('student_id', currentUser.id);
    } catch (e) {
      debugPrint('Erro ao desconectar do professor: $e');
      throw 'Ocorreu um erro ao tentar desconectar. Tente novamente.';
    }
  }
}
