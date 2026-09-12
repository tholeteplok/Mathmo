import 'package:hive_ce/hive.dart';
import 'package:uuid/uuid.dart';

import '../../domain/models/player_profile.dart';
import '../../domain/repositories/player_repository.dart';
import '../../domain/repositories/repo_result.dart';

/// Implementasi persistensi [PlayerRepository] menggunakan Hive CE.
class HivePlayerRepository implements PlayerRepository {
  HivePlayerRepository([Box<Map>? box]) : _box = box;

  static const String boxName = 'player_profile';
  static const String profileKey = 'current_profile';
  Box<Map>? _box;

  Future<Box<Map>> _getBox() async {
    if (_box != null && _box!.isOpen) return _box!;
    _box = await Hive.openBox<Map>(boxName);
    return _box!;
  }

  @override
  Future<RepoResult<PlayerProfile>> getProfile() async {
    try {
      final box = await _getBox();
      final raw = box.get(profileKey);
      if (raw == null) {
        // Inisialisasi profil pemain baru jika belum ada
        final defaultProfile = PlayerProfile(
          playerId: 'p_${const Uuid().v4().substring(0, 8)}',
          currentLevel: 1,
          totalXp: 0,
          streak: const StreakState(
            currentStreak: 0,
            freezeTokens: 1,
            lastPlayedDate: null,
          ),
          confidenceScore: 0,
          createdAt: DateTime.now(),
        );
        await saveProfile(defaultProfile);
        return RepoSuccess(defaultProfile);
      }

      final map = Map<String, dynamic>.from(raw);
      final profile = PlayerProfile.fromJson(map);
      return RepoSuccess(profile);
    } catch (e) {
      return RepoFailure('Gagal memuat profil pemain', e);
    }
  }

  @override
  Future<RepoResult<void>> saveProfile(PlayerProfile profile) async {
    try {
      final box = await _getBox();
      await box.put(profileKey, profile.toJson());
      return const RepoSuccess(null);
    } catch (e) {
      return RepoFailure('Gagal menyimpan profil pemain', e);
    }
  }

  @override
  Future<RepoResult<void>> updateLevel(int newLevel) async {
    try {
      final currentRes = await getProfile();
      if (currentRes is RepoFailure<PlayerProfile>) {
        return RepoFailure(currentRes.reason, currentRes.exception);
      }
      final current = (currentRes as RepoSuccess<PlayerProfile>).value;
      final updated = current.copyWith(currentLevel: newLevel);
      return saveProfile(updated);
    } catch (e) {
      return RepoFailure('Gagal memperbarui level pemain', e);
    }
  }

  @override
  Future<RepoResult<PlayerProfile>> recordDailyActivity(
    DateTime playedDate,
  ) async {
    try {
      final currentRes = await getProfile();
      if (currentRes is RepoFailure<PlayerProfile>) {
        return RepoFailure(currentRes.reason, currentRes.exception);
      }
      final current = (currentRes as RepoSuccess<PlayerProfile>).value;
      final updatedStreak = current.streak.recordActivity(playedDate);
      final updatedProfile = current.copyWith(streak: updatedStreak);
      await saveProfile(updatedProfile);
      return RepoSuccess(updatedProfile);
    } catch (e) {
      return RepoFailure('Gagal memperbarui streak aktivitas harian', e);
    }
  }

  @override
  Future<RepoResult<PlayerProfile>> resetProfile() async {
    try {
      final defaultProfile = PlayerProfile(
        playerId: 'p_${const Uuid().v4().substring(0, 8)}',
        currentLevel: 1,
        totalXp: 0,
        streak: const StreakState(
          currentStreak: 0,
          freezeTokens: 1,
          lastPlayedDate: null,
        ),
        confidenceScore: 0,
        createdAt: DateTime.now(),
      );
      await saveProfile(defaultProfile);
      return RepoSuccess(defaultProfile);
    } catch (e) {
      return RepoFailure('Gagal mereset profil pemain', e);
    }
  }
}
