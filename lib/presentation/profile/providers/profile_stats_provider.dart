import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/mastery_record.dart';
import '../../../domain/models/profile_stats_aggregate.dart';
import '../../../domain/models/session_result.dart';
import '../../../domain/repositories/repo_result.dart';
import '../../../domain/services/profile_stats_service.dart';
import '../../game/providers/game_dependencies_provider.dart';

final profileStatsServiceProvider = Provider<ProfileStatsService>((ref) {
  return const ProfileStatsService();
});

/// Provider untuk menghitung agregat statistik pemain (akurasi rata-rata & fakta dikuasai).
final profileStatsProvider = FutureProvider<ProfileStatsAggregate>((ref) async {
  final sessionRepo = ref.watch(sessionRepositoryProvider);
  final masteryRepo = ref.watch(masteryRepositoryProvider);
  final statsService = ref.watch(profileStatsServiceProvider);

  final sessionsResult = await sessionRepo.getRecentSessions(limit: 100);
  final masteryResult = await masteryRepo.getAll();

  final sessions = switch (sessionsResult) {
    RepoSuccess(:final value) => value,
    RepoFailure() => <SessionResult>[],
  };

  final mastery = switch (masteryResult) {
    RepoSuccess(:final value) => value,
    RepoFailure() => <String, MasteryRecord>{},
  };

  return statsService.computeAggregate(
    recentSessions: sessions,
    masteryBank: mastery,
  );
});
