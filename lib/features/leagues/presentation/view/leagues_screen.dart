// lib/features/leagues/presentation/view/leagues_screen.dart

import 'package:flutter/material.dart';
import 'package:musilingo/app/core/result.dart';
import 'package:musilingo/app/core/theme/app_colors.dart';
import 'package:musilingo/app/data/models/weekly_xp_model.dart';
import 'package:musilingo/app/presentation/widgets/gradient_background.dart';
import 'package:musilingo/app/services/database_service.dart';
import 'package:musilingo/app/services/user_session.dart';
import 'package:musilingo/features/leagues/presentation/widgets/league_list_item_widget.dart';
import 'package:provider/provider.dart' as provider;

class LeaguesScreen extends StatefulWidget {
  const LeaguesScreen({super.key});

  @override
  State<LeaguesScreen> createState() => _LeaguesScreenState();
}

class _LeaguesScreenState extends State<LeaguesScreen> {
  final DatabaseService _databaseService = DatabaseService();
  late Future<List<WeeklyXp>> _leaderboardFuture;

  @override
  void initState() {
    super.initState();
    final userLeague =
        provider.Provider.of<UserSession>(context, listen: false).currentUser?.league ??
            'Bronze';
    _leaderboardFuture = _fetchLeaderboard(userLeague);
  }

  Future<List<WeeklyXp>> _fetchLeaderboard(String userLeague) async {
    final result = await _databaseService.getLeagueLeaderboard(userLeague);
    return switch (result) {
      Success<List<WeeklyXp>>(data: final data) => data,
      Failure<List<WeeklyXp>>(message: final error) => throw Exception(error),
    };
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserSession>().currentUser;
    final userLeague = user?.league ?? 'Bronze';

    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        // ESTA APPBAR GARANTE QUE O BOTÃO "VOLTAR" APAREÇA QUANDO A TELA É NAVEGADA
        appBar: AppBar(
          title: Text('Liga $userLeague',
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: FutureBuilder<List<WeeklyXp>>(
          future: _leaderboardFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                  child: CircularProgressIndicator(color: AppColors.accent));
            }
            if (snapshot.hasError) {
              return Center(
                  child: Text('Erro ao carregar a liga: ${snapshot.error}'));
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('Nenhum jogador na sua liga.'));
            }

            final leaderboard = snapshot.data!;
            final currentUserRanking = leaderboard
                .indexWhere((xpData) => xpData.profile.id == user?.id);

            return ListView.builder(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              itemCount: leaderboard.length,
              itemBuilder: (context, index) {
                final xpData = leaderboard[index];
                return LeagueListItemWidget(
                  rank: index + 1,
                  leaderboardEntry: xpData,
                  isCurrentUser: currentUserRanking == index,
                );
              },
            );
          },
        ),
      ),
    );
  }
}
