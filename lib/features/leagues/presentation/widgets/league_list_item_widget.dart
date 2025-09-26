// lib/features/leagues/presentation/widgets/league_list_item_widget.dart

import 'package:flutter/material.dart';
import 'package:musilingo/app/core/theme/app_colors.dart';
import 'package:musilingo/app/data/models/weekly_xp_model.dart';

class LeagueListItemWidget extends StatelessWidget {
  final int rank;
  final WeeklyXp leaderboardEntry;
  final bool isCurrentUser;

  const LeagueListItemWidget({
    super.key,
    required this.rank,
    required this.leaderboardEntry,
    required this.isCurrentUser,
  });

  @override
  Widget build(BuildContext context) {
    final color = isCurrentUser
        ? AppColors.accent.withAlpha((255 * 0.3).round())
        : AppColors.card.withAlpha((255 * 0.5).round());
    final userProfile = leaderboardEntry.profile;
    final xp = leaderboardEntry.xp;

    return Card(
      color: color,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isCurrentUser
            ? const BorderSide(color: AppColors.accent, width: 2)
            : BorderSide.none,
      ),
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Text(
              '$rank',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 16),
            CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.primary,
              backgroundImage: userProfile.avatarUrl != null &&
                      userProfile.avatarUrl!.isNotEmpty
                  ? NetworkImage(userProfile.avatarUrl!)
                  : null,
              child: userProfile.avatarUrl == null ||
                      userProfile.avatarUrl!.isEmpty
                  ? const Icon(Icons.person,
                      color: AppColors.background, size: 24)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                userProfile.fullName,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '$xp XP',
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.accent),
            ),
          ],
        ),
      ),
    );
  }
}
