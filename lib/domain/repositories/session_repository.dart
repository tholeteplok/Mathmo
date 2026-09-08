import '../models/session_result.dart';
import 'repo_result.dart';

/// Abstraksi penyimpanan riwayat sesi permainan (append-only log).
abstract interface class SessionRepository {
  /// Menyimpan ringkasan sesi yang baru saja selesai.
  Future<RepoResult<void>> saveSession(SessionResult result);

  /// Mengambil daftar sesi terbaru untuk halaman statistik / riwayat.
  Future<RepoResult<List<SessionResult>>> getRecentSessions({int limit = 20});
}
