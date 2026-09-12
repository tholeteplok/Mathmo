import '../models/player_profile.dart';
import 'repo_result.dart';

/// Abstraksi penyimpanan data profil pemain (level, streak, XP, token).
abstract interface class PlayerRepository {
  /// Mengambil profil pemain yang sedang aktif.
  /// Jika belum ada, menginisialisasi profil baru default.
  Future<RepoResult<PlayerProfile>> getProfile();

  /// Menyimpan perubahan data profil pemain.
  Future<RepoResult<void>> saveProfile(PlayerProfile profile);

  /// Helper untuk memperbarui level pemain.
  Future<RepoResult<void>> updateLevel(int newLevel);

  /// Helper untuk mencatat aktivitas harian dan memperbarui streak.
  Future<RepoResult<PlayerProfile>> recordDailyActivity(DateTime playedDate);

  /// Mereset profil pemain ke kondisi awal default (mis. saat sign out).
  Future<RepoResult<PlayerProfile>> resetProfile();
}
