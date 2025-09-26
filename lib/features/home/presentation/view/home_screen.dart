import 'package:flutter/material.dart';
import 'package:musilingo/app/core/theme/app_colors.dart';
import 'package:musilingo/app/core/result.dart';
import 'package:musilingo/app/data/models/lesson_model.dart';
import 'package:musilingo/app/data/models/module_model.dart';
import 'package:musilingo/app/services/database_service.dart';
import 'package:musilingo/app/services/user_session.dart';
import 'package:musilingo/features/home/presentation/widgets/world_widget.dart';
import 'package:musilingo/main.dart';
import 'package:provider/provider.dart' as provider;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DatabaseService _databaseService = DatabaseService();
  late Future<Map<String, dynamic>> _homeDataFuture;

  @override
  void initState() {
    super.initState();
    _homeDataFuture = _fetchHomeData();
  }

  Future<Map<String, dynamic>> _fetchHomeData() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) throw 'Utilizador não autenticado.';
      final modulesResult = await _databaseService.getModulesAndLessons();
      final completedLessonIdsResult =
          await _databaseService.getCompletedLessonIds(userId);

      final modules = switch (modulesResult) {
        Success<List<Module>>(data: final data) => data,
        Failure<List<Module>>(errorMessage: final error) =>
          throw 'Erro ao buscar módulos: $error',
      };

      final completedLessonIds = switch (completedLessonIdsResult) {
        Success<Set<int>>(data: final data) => data,
        Failure<Set<int>>(errorMessage: final error) =>
          throw 'Erro ao buscar lições completadas: $error',
      };

      final allLessons = modules.expand((module) => module.lessons).toList();
      return {
        'modules': modules,
        'completedLessonIds': completedLessonIds,
        'allLessons': allLessons,
      };
    } catch (error, stackTrace) {
      debugPrint("Erro detalhado ao buscar dados: $error");
      debugPrint("Stack Trace: $stackTrace");
      rethrow;
    }
  }

  void _refreshData() {
    setState(() {
      _homeDataFuture = _fetchHomeData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final userSession = context.watch<UserSession>();
    final user = userSession.currentUser;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        // --- CORREÇÃO DO TÍTULO ---
        // O título foi atualizado para 'Jornada Musical' para refletir a intenção.
        title: const Text('Jornada Musical',
            style: TextStyle(fontWeight: FontWeight.bold)),
        // --- FIM DA CORREÇÃO ---
        actions: [
          Row(children: [
            const Icon(Icons.local_fire_department, color: Colors.orangeAccent),
            const SizedBox(width: 4),
            Text(user?.currentStreak.toString() ?? '0',
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(width: 16),
          ]),
          Row(children: [
            const Icon(Icons.favorite, color: AppColors.primary),
            const SizedBox(width: 4),
            Text(user?.lives.toString() ?? '0',
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(width: 16),
          ]),
          Row(children: [
            const Icon(Icons.music_note, color: AppColors.accent),
            const SizedBox(width: 4),
            Text(user?.points.toString() ?? '0',
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(width: 16),
          ]),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final userSession = context.read<UserSession>();
              await supabase.auth.signOut();
              userSession.clearSession();
              // O AuthWrapper vai detectar automaticamente que não há usuário
            },
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _homeDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Container(
                color: AppColors.background,
                child: const Center(
                    child: CircularProgressIndicator(color: AppColors.accent)));
          }

          if (snapshot.hasError) {
            return Container(
                color: AppColors.background,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Não foi possível carregar o conteúdo.\n\nErro: ${snapshot.error}',
                      style: const TextStyle(color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Container(
                color: AppColors.background,
                child:
                    const Center(child: Text('Nenhum conteúdo encontrado.')));
          }

          final data = snapshot.data!;
          final modules = data['modules'] as List<Module>;
          final completedLessonIds = data['completedLessonIds'] as Set<int>;
          final allLessons = data['allLessons'] as List<Lesson>;

          int initialModuleIndex = 0;
          if (modules.isNotEmpty && allLessons.isNotEmpty) {
            // Encontra a primeira lição que AINDA NÃO foi completada
            final nextLesson = allLessons.firstWhere(
              (lesson) => !completedLessonIds.contains(lesson.id),
              // Se todas estiverem completas, vai para a última lição do último módulo
              orElse: () => allLessons.last,
            );

            // Encontra o índice do módulo que contém esta próxima lição
            final moduleIndex = modules.indexWhere((module) =>
                module.lessons.any((lesson) => lesson.id == nextLesson.id));

            if (moduleIndex != -1) {
              initialModuleIndex = moduleIndex;
            }
          }

          final pageController =
              PageController(initialPage: initialModuleIndex);

          return PageView.builder(
            controller: pageController,
            physics: const BouncingScrollPhysics(),
            itemCount: modules.length,
            itemBuilder: (context, index) {
              final module = modules[index];
              return WorldWidget(
                module: module,
                allLessons: allLessons,
                completedLessonIds: completedLessonIds,
                isFirstModule: index == 0,
                isLastModule: index == modules.length - 1,
                pageController: pageController,
                onLessonCompleted: _refreshData,
              );
            },
          );
        },
      ),
    );
  }
}
