import '../models/mastery_record.dart';
import '../models/profile_stats_aggregate.dart';
import '../models/session_result.dart';

/// Layanan agregasi statistik profil pemain (§1.4).
///
/// Murni pure Dart (tidak bergantung pada Flutter / Riverpod).
class ProfileStatsService {
  const ProfileStatsService();

  /// Menghitung akurasi rata-rata dari riwayat sesi dan jumlah fakta yang telah
  /// dikuasai penuh (Leitner box == 5).
  ProfileStatsAggregate computeAggregate({
    required List<SessionResult> recentSessions,
    required Map<String, MasteryRecord> masteryBank,
  }) {
    final avgAccuracy = recentSessions.isEmpty
        ? 0.0
        : recentSessions.map((s) => s.accuracy).reduce((a, b) => a + b) /
            recentSessions.length;

    final masteredCount = masteryBank.values.where((r) => r.box == 5).length;

    return ProfileStatsAggregate(
      averageAccuracy: avgAccuracy,
      factsMastered: masteredCount,
    );
  }
}
