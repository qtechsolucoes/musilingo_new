// lib/app/data/models/weekly_xp_model.dart

import 'package:musilingo/app/data/models/user_profile_model.dart';

class WeeklyXp {
  final String userId;
  final int xp;
  final UserProfile profile;

  WeeklyXp({
    required this.userId,
    required this.xp,
    required this.profile,
  });

  factory WeeklyXp.fromMap(Map<String, dynamic> map) {
    return WeeklyXp(
      userId: map['user_id'] as String,
      xp: map['xp'] as int,
      // O campo 'week_start' foi completamente removido, pois não existe na tabela.
      profile: UserProfile.fromMap(map['profiles'] as Map<String, dynamic>),
    );
  }
}
