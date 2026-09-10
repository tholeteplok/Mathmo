/// Model agregat statistik pemain untuk ProfileScreen (§1.4).
///
/// File ini adalah Pure Dart dan tidak bergantung pada Flutter atau Riverpod.
library;

class ProfileStatsAggregate {
  const ProfileStatsAggregate({
    required this.averageAccuracy,
    required this.factsMastered,
  });

  /// Akurasi rata-rata (0.0 sampai 1.0) dari sesi baru-baru ini.
  final double averageAccuracy;

  /// Jumlah fakta aritmatika yang sudah dikuasai penuh (Leitner Box == 5).
  final int factsMastered;

  /// Persentase akurasi format string (mis. "85%").
  String get formattedAccuracy => '${(averageAccuracy * 100).round()}%';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProfileStatsAggregate &&
          runtimeType == other.runtimeType &&
          averageAccuracy == other.averageAccuracy &&
          factsMastered == other.factsMastered;

  @override
  int get hashCode => Object.hash(averageAccuracy, factsMastered);

  @override
  String toString() =>
      'ProfileStatsAggregate(accuracy: $formattedAccuracy, mastered: $factsMastered)';
}
