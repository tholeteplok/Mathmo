/// Model untuk profil pemain dan status streak bermain harian.
///
/// File ini adalah Pure Dart dan tidak bergantung pada Flutter atau Riverpod.
library;

import 'dart:math' as math;

/// Status streak (keaktifan bermain harian) pemain beserta jaring pengaman token.
///
/// Berdasarkan Core Gameplay Spec §8.3:
/// - [freezeTokens]: "Asuransi" otomatis yang terpakai jika absen 1 hari.
///   Didapatkan secara bertahap dari konsistensi bermain (mis. +1 token tiap 7 hari streak).
/// - [lastPlayedDate]: Tanggal kalender terakhir kali pemain menyelesaikan sesi permainan.
/// - [longestStreak]: Rekor streak tertinggi yang pernah dicapai pemain sepanjang masa.
class StreakState {
  const StreakState({
    required this.currentStreak,
    required this.freezeTokens,
    this.longestStreak = 0,
    this.lastPlayedDate,
  });

  /// Jumlah hari berturut-turut pemain aktif bermain.
  final int currentStreak;

  /// Jumlah freeze token asuransi yang dimiliki pemain saat ini.
  final int freezeTokens;

  /// Rekor streak tertinggi sepanjang masa.
  final int longestStreak;

  /// Tanggal kalender terakhir aktivitas bermain dicatat.
  final DateTime? lastPlayedDate;

  /// Nilai awal untuk pemain baru.
  static const StreakState initial = StreakState(
    currentStreak: 0,
    freezeTokens: 1, // Diberi 1 token awal sebagai penyambut
    longestStreak: 0,
    lastPlayedDate: null,
  );

  /// Menangani kondisi ketika pemain absen / melewati hari bermain.
  ///
  /// Jika memiliki [freezeTokens], 1 token dikonsumsi dan streak bertahan.
  /// Jika tidak ada token tersisa, streak di-reset menjadi 0.
  StreakState onDayMissed() {
    if (freezeTokens > 0) {
      return copyWith(freezeTokens: freezeTokens - 1);
    }
    return copyWith(currentStreak: 0);
  }

  /// Mencatat aktivitas bermain pada tanggal [today].
  ///
  /// Secara otomatis memperbarui streak, menangani jeda hari dengan freeze token,
  /// dan memberikan bonus token setiap kelipatan 7 hari berturut-turut.
  StreakState recordActivity(DateTime today) {
    final todayDate = DateTime.utc(today.year, today.month, today.day);

    if (lastPlayedDate == null) {
      return StreakState(
        currentStreak: 1,
        freezeTokens: freezeTokens,
        longestStreak: math.max(longestStreak, 1),
        lastPlayedDate: todayDate,
      );
    }

    final lastDate = DateTime.utc(
      lastPlayedDate!.year,
      lastPlayedDate!.month,
      lastPlayedDate!.day,
    );

    final diffInDays = todayDate.difference(lastDate).inDays;

    // Sudah pernah main hari ini
    if (diffInDays <= 0) {
      return this;
    }

    // Bermain di hari berikutnya tepat (streak berlanjut)
    if (diffInDays == 1) {
      final nextStreak = currentStreak + 1;
      // Bonus 1 freeze token setiap 7 hari streak berturut-turut (§8.3)
      final bonusToken = (nextStreak % 7 == 0) ? 1 : 0;
      return StreakState(
        currentStreak: nextStreak,
        freezeTokens: freezeTokens + bonusToken,
        longestStreak: math.max(longestStreak, nextStreak),
        lastPlayedDate: todayDate,
      );
    }

    // Absen lebih dari 1 hari: evaluasi perlindungan token
    final missedDays = diffInDays - 1;
    if (freezeTokens >= missedDays) {
      // Semua hari absen tertutup token
      final nextStreak = currentStreak + 1;
      final remainingTokens = freezeTokens - missedDays;
      final bonusToken = (nextStreak % 7 == 0) ? 1 : 0;
      return StreakState(
        currentStreak: nextStreak,
        freezeTokens: remainingTokens + bonusToken,
        longestStreak: math.max(longestStreak, nextStreak),
        lastPlayedDate: todayDate,
      );
    } else {
      // Token tidak mencukupi, streak terputus dan reset ke 1
      return StreakState(
        currentStreak: 1,
        freezeTokens: 0,
        longestStreak: math.max(longestStreak, 1),
        lastPlayedDate: todayDate,
      );
    }
  }

  /// Format tanggal YYYY-MM-DD untuk JSON.
  String? get formattedLastPlayedDate {
    if (lastPlayedDate == null) return null;
    final y = lastPlayedDate!.year.toString().padLeft(4, '0');
    final m = lastPlayedDate!.month.toString().padLeft(2, '0');
    final d = lastPlayedDate!.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  /// Membuat [StreakState] dari Map JSON.
  factory StreakState.fromJson(Map<String, dynamic> json) {
    DateTime? parsedDate;
    final rawDate = json['last_played_date'] ?? json['lastPlayedDate'];
    if (rawDate != null) {
      parsedDate = DateTime.parse(rawDate as String);
    }

    final curStreak =
        ((json['current_streak'] ?? json['currentStreak'] ?? 0) as num).toInt();
    final longest = ((json['longest_streak'] ??
            json['longestStreak'] ??
            curStreak) as num)
        .toInt();

    return StreakState(
      currentStreak: curStreak,
      freezeTokens:
          ((json['freeze_tokens'] ?? json['freezeTokens'] ?? 0) as num).toInt(),
      longestStreak: longest,
      lastPlayedDate: parsedDate,
    );
  }

  /// Serialisasi ke Map JSON.
  Map<String, dynamic> toJson() {
    return {
      'current_streak': currentStreak,
      'freeze_tokens': freezeTokens,
      'longest_streak': longestStreak,
      'last_played_date': formattedLastPlayedDate,
    };
  }

  /// Membuat salinan objek dengan field yang dimodifikasi.
  StreakState copyWith({
    int? currentStreak,
    int? freezeTokens,
    int? longestStreak,
    DateTime? lastPlayedDate,
  }) {
    return StreakState(
      currentStreak: currentStreak ?? this.currentStreak,
      freezeTokens: freezeTokens ?? this.freezeTokens,
      longestStreak: longestStreak ?? this.longestStreak,
      lastPlayedDate: lastPlayedDate ?? this.lastPlayedDate,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StreakState &&
          runtimeType == other.runtimeType &&
          currentStreak == other.currentStreak &&
          freezeTokens == other.freezeTokens &&
          longestStreak == other.longestStreak &&
          lastPlayedDate == other.lastPlayedDate;

  @override
  int get hashCode =>
      Object.hash(currentStreak, freezeTokens, longestStreak, lastPlayedDate);

  @override
  String toString() =>
      'StreakState(streak: $currentStreak, longest: $longestStreak, tokens: $freezeTokens, '
      'lastPlayed: $formattedLastPlayedDate)';
}

/// Data model profil pemain utama (PlayerProfile).
///
/// Menyimpan informasi level saat ini, total XP akumulatif, status streak,
/// dan skor kepercayaan (DDA Layer 1) yang dipersistensikan.
class PlayerProfile {
  const PlayerProfile({
    required this.playerId,
    this.username,
    this.avatarId,
    required this.currentLevel,
    required this.totalXp,
    this.totalScore = 0,
    required this.streak,
    required this.confidenceScore,
    required this.createdAt,
  });

  /// ID unik pemain (mis. 'p_mika01').
  final String playerId;

  /// Username pemain untuk leaderboard (minimal 4 karakter, non-email).
  final String? username;

  /// ID preset avatar pemain (mis. 'avatar_0' .. 'avatar_8', atau null jika inisial).
  final String? avatarId;

  /// Level permainan pemain saat ini.
  final int currentLevel;

  /// Akumulasi total XP yang sudah diperoleh sepanjang masa.
  final int totalXp;

  /// Akumulasi total skor terbaik dari replay level sepanjang masa.
  final int totalScore;

  /// Status streak bermain harian dan token perlindungan.
  final StreakState streak;

  /// Skor kepercayaan diri (DDA Layer 1) yang tersisa.
  /// Rentang dinamis: -2 sampai +2 (mempengaruhi timer leniency).
  final int confidenceScore;

  /// Waktu akun pemain pertama kali dibuat.
  final DateTime createdAt;

  /// Membuat profil default baru untuk pemain baru.
  factory PlayerProfile.initial({
    required String playerId,
    String? username,
    String? avatarId,
    DateTime? createdAt,
  }) {
    return PlayerProfile(
      playerId: playerId,
      username: username,
      avatarId: avatarId,
      currentLevel: 1,
      totalXp: 0,
      totalScore: 0,
      streak: StreakState.initial,
      confidenceScore: 0,
      createdAt: createdAt ?? DateTime.now().toUtc(),
    );
  }

  /// Membuat [PlayerProfile] dari Map JSON.
  factory PlayerProfile.fromJson(Map<String, dynamic> json) {
    final streakRaw = json['streak'];
    final streakObj = streakRaw != null && streakRaw is Map
        ? StreakState.fromJson(Map<String, dynamic>.from(streakRaw))
        : StreakState.initial;

    return PlayerProfile(
      playerId: (json['player_id'] ?? json['playerId']) as String,
      username: json['username'] as String?,
      avatarId: (json['avatar_id'] ?? json['avatarId']) as String?,
      currentLevel:
          ((json['current_level'] ?? json['currentLevel'] ?? 1) as num).toInt(),
      totalXp: ((json['total_xp'] ?? json['totalXp'] ?? 0) as num).toInt(),
      totalScore:
          ((json['total_score'] ?? json['totalScore'] ?? 0) as num).toInt(),
      streak: streakObj,
      confidenceScore:
          ((json['confidence_score'] ?? json['confidenceScore'] ?? 0) as num)
              .toInt(),
      createdAt: DateTime.parse(
        (json['created_at'] ?? json['createdAt']) as String,
      ),
    );
  }

  /// Serialisasi ke Map JSON yang kompatibel dengan spesifikasi.
  Map<String, dynamic> toJson() {
    return {
      'player_id': playerId,
      'username': username,
      'avatar_id': avatarId,
      'current_level': currentLevel,
      'total_xp': totalXp,
      'total_score': totalScore,
      'streak': streak.toJson(),
      'confidence_score': confidenceScore,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Membuat salinan objek dengan field yang dimodifikasi.
  PlayerProfile copyWith({
    String? playerId,
    String? username,
    String? avatarId,
    bool clearAvatar = false,
    int? currentLevel,
    int? totalXp,
    int? totalScore,
    StreakState? streak,
    int? confidenceScore,
    DateTime? createdAt,
  }) {
    return PlayerProfile(
      playerId: playerId ?? this.playerId,
      username: username ?? this.username,
      avatarId: clearAvatar ? null : (avatarId ?? this.avatarId),
      currentLevel: currentLevel ?? this.currentLevel,
      totalXp: totalXp ?? this.totalXp,
      totalScore: totalScore ?? this.totalScore,
      streak: streak ?? this.streak,
      confidenceScore: confidenceScore ?? this.confidenceScore,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlayerProfile &&
          runtimeType == other.runtimeType &&
          playerId == other.playerId &&
          username == other.username &&
          avatarId == other.avatarId &&
          currentLevel == other.currentLevel &&
          totalXp == other.totalXp &&
          totalScore == other.totalScore &&
          streak == other.streak &&
          confidenceScore == other.confidenceScore &&
          createdAt == other.createdAt;

  @override
  int get hashCode => Object.hash(
    playerId,
    username,
    avatarId,
    currentLevel,
    totalXp,
    totalScore,
    streak,
    confidenceScore,
    createdAt,
  );

  @override
  String toString() =>
      'PlayerProfile(id: $playerId, user: $username, avatar: $avatarId, lvl: $currentLevel, xp: $totalXp, score: $totalScore, '
      'streak: ${streak.currentStreak}, conf: $confidenceScore)';
}
