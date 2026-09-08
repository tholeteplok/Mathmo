import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/daily_challenge.dart';
import '../../../domain/repositories/repo_result.dart';
import '../../../domain/services/daily_challenge_service.dart';
import '../../game/providers/game_dependencies_provider.dart';
import '../../game/providers/level_band_theme_provider.dart';
import '../../home/providers/player_profile_provider.dart';

final dailyChallengeServiceProvider = Provider<DailyChallengeService>((ref) {
  return DailyChallengeService(
    questionGenerator: ref.watch(questionGeneratorProvider),
    distractorGenerator: ref.watch(distractorGeneratorProvider),
  );
});

/// Provider untuk memuat Daily Challenge hari ini (tanggal lokal perangkat).
final dailyChallengeProvider = FutureProvider<DailyChallenge>((ref) async {
  final now = DateTime.now();
  final profile = await ref.watch(playerProfileProvider.future);
  final config = await ref.watch(levelBandsConfigProvider.future);

  final band = config.bandForLevel(profile.currentLevel);
  final repo = ref.watch(dailyChallengeRepositoryProvider);

  // Cek cache lokal terlebih dahulu
  final cached = await repo.getCachedChallenge(now, band.id);
  if (cached is RepoSuccess<DailyChallenge?> && cached.value != null) {
    return cached.value!;
  }

  // Jika belum ada di cache, generate deterministik lokal
  final service = ref.watch(dailyChallengeServiceProvider);
  final challenge = service.generateDailyChallenge(date: now, band: band);

  // Simpan ke cache lokal
  await repo.cacheChallenge(challenge);

  return challenge;
});
