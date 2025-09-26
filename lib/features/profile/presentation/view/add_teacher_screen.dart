// lib/features/profile/presentation/view/add_teacher_screen.dart

import 'package:flutter/material.dart';
import 'package:musilingo/app/core/theme/app_colors.dart';
import 'package:musilingo/app/data/models/user_profile_model.dart';
import 'package:musilingo/app/presentation/widgets/gradient_background.dart';
import 'package:musilingo/app/services/teacher_service.dart';
import 'dart:async';

class AddTeacherScreen extends StatefulWidget {
  const AddTeacherScreen({super.key});

  @override
  State<AddTeacherScreen> createState() => _AddTeacherScreenState();
}

class _AddTeacherScreenState extends State<AddTeacherScreen> {
  final _teacherService = TeacherService();
  final _searchController = TextEditingController();

  UserProfile? _currentTeacher;
  List<UserProfile> _searchResults = [];
  bool _isLoading = true;
  bool _isSearching = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _checkIfStudentHasTeacher();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _checkIfStudentHasTeacher() async {
    setState(() => _isLoading = true);
    final teacher = await _teacherService.getCurrentTeacher();
    if (mounted) {
      setState(() {
        _currentTeacher = teacher;
        _isLoading = false;
      });
    }
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _searchTeachers();
    });
  }

  Future<void> _searchTeachers() async {
    final query = _searchController.text.trim();
    if (query.length < 3) {
      setState(() => _searchResults = []);
      return;
    }
    setState(() => _isSearching = true);
    final results = await _teacherService.searchTeachers(query);
    if (mounted) {
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    }
  }

  Future<void> _addTeacher(String teacherId) async {
    final success = await _teacherService.addTeacher(teacherId);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success
              ? 'Professor adicionado com sucesso!'
              : 'Não foi possível adicionar o professor. Tente novamente.'),
          backgroundColor: success ? AppColors.completed : AppColors.error,
        ),
      );
      if (success) {
        _checkIfStudentHasTeacher();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('O Meu Professor'),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.accent))
            : _currentTeacher != null
                ? _buildCurrentTeacherView()
                : _buildSearchView(),
      ),
    );
  }

  Widget _buildCurrentTeacherView() {
    final teacher = _currentTeacher!;

    // --- MODIFICAÇÃO AQUI ---
    // Envolvemos o conteúdo num Center para garantir o alinhamento central.
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          // mainAxisAlignment.center alinha os itens no centro vertical do espaço da Column.
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 50,
              backgroundImage: teacher.avatarUrl != null
                  ? NetworkImage(teacher.avatarUrl!)
                  : null,
              child: teacher.avatarUrl == null
                  ? const Icon(Icons.person, size: 50)
                  : null,
            ),
            const SizedBox(height: 16),
            Text(
              teacher.fullName,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              'Este é o seu professor atual.',
              style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
            ),
            // Adicionamos um Spacer para empurrar o conteúdo para o centro,
            // caso a Column queira ocupar todo o ecrã.
            const Spacer(),
          ],
        ),
      ),
    );
    // --- FIM DA MODIFICAÇÃO ---
  }

  Widget _buildSearchView() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Pesquise pelo nome do professor...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              // ignore: deprecated_member_use
              fillColor: AppColors.card.withOpacity(0.8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (_isSearching)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(color: AppColors.accent),
            ),
          Expanded(
            child: ListView.builder(
              itemCount: _searchResults.length,
              itemBuilder: (context, index) {
                final teacher = _searchResults[index];
                return Card(
                  color: AppColors.card,
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundImage: teacher.avatarUrl != null
                          ? NetworkImage(teacher.avatarUrl!)
                          : null,
                      child: teacher.avatarUrl == null
                          ? const Icon(Icons.person)
                          : null,
                    ),
                    title: Text(teacher.fullName),
                    trailing: ElevatedButton(
                      onPressed: () => _addTeacher(teacher.id),
                      child: const Text('Adicionar'),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
