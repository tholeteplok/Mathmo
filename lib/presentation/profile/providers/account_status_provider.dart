import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/repositories/repo_result.dart';
import '../../game/providers/game_dependencies_provider.dart';
import '../../home/providers/player_profile_provider.dart';

/// Status akun pemain.
enum AccountStatus {
  /// Bermain offline secara lokal tanpa akun Firebase.
  guest,

  /// Masuk dengan akun anonim Firebase.
  anonymous,

  /// Terhubung dengan akun permanen (mis. Google).
  linked,
}

/// Data state untuk akun pemain aktif.
class AccountState {
  const AccountState({
    required this.status,
    this.userId,
    this.username,
    this.hasVerifiedSession = false,
  });

  final AccountStatus status;
  final String? userId;
  final String? username;

  /// True hanya jika ada sesi Firebase Auth aktif (bukan sekadar cache lokal).
  ///
  /// Bedakan dari [username] yang bisa berasal dari Hive lokal walau sesi cloud
  /// sudah hilang (reinstall, token dicabut, dsb.).
  final bool hasVerifiedSession;

  bool get isGuest => status == AccountStatus.guest;
  bool get hasUsername => username != null && username!.trim().length >= 4;

  /// True hanya jika aman untuk mengirim data ke Firestore.
  ///
  /// Dipakai di semua titik submission cloud (daily challenge, sync total_score)
  /// agar tidak mengandalkan cek `username != null` yang bisa misleading saat
  /// sesi Firebase sudah hilang tapi cache Hive masih ada.
  bool get canSubmitToCloud => hasVerifiedSession && hasUsername;

  AccountState copyWith({
    AccountStatus? status,
    String? userId,
    String? username,
    bool? hasVerifiedSession,
  }) {
    return AccountState(
      status: status ?? this.status,
      userId: userId ?? this.userId,
      username: username ?? this.username,
      hasVerifiedSession: hasVerifiedSession ?? this.hasVerifiedSession,
    );
  }
}

final accountStatusProvider =
    AsyncNotifierProvider<AccountStatusNotifier, AccountState>(
      AccountStatusNotifier.new,
    );

class AccountStatusNotifier extends AsyncNotifier<AccountState> {
  @override
  FutureOr<AccountState> build() async {
    final authRepo = ref.watch(authRepositoryProvider);

    // Dapatkan username dari profil lokal jika ada
    final localProfile = ref.watch(playerProfileProvider).valueOrNull;

    if (!authRepo.isLoggedIn) {
      // Tidak ada sesi Firebase — username lokal boleh ditampilkan di UI
      // tapi TIDAK boleh dipakai untuk submission cloud.
      return AccountState(
        status: AccountStatus.guest,
        username: localProfile?.username,
        hasVerifiedSession: false,
      );
    }

    final uid = authRepo.currentUserId;
    final cloudUsername = authRepo.currentUsername;
    final effectiveUsername = cloudUsername ?? localProfile?.username;

    return AccountState(
      status: authRepo.isAnonymous ? AccountStatus.anonymous : AccountStatus.linked,
      userId: uid,
      username: effectiveUsername,
      hasVerifiedSession: true,
    );
  }

  /// Masuk secara anonim ke Firebase.
  Future<RepoResult<String>> signInAnonymously() async {
    state = const AsyncLoading();
    final authRepo = ref.read(authRepositoryProvider);
    final result = await authRepo.signInAnonymously();

    if (result is RepoSuccess<String>) {
      final localProfile = ref.read(playerProfileProvider).valueOrNull;
      final effectiveUsername = authRepo.currentUsername ?? localProfile?.username;

      state = AsyncData(
        AccountState(
          status: AccountStatus.anonymous,
          userId: result.value,
          username: effectiveUsername,
          hasVerifiedSession: true,
        ),
      );
    } else {
      state = AsyncData(
        AccountState(
          status: AccountStatus.guest,
          username: ref.read(playerProfileProvider).valueOrNull?.username,
          hasVerifiedSession: false,
        ),
      );
    }

    return result;
  }

  /// Masuk dengan Google.
  Future<RepoResult<String>> signInWithGoogle() async {
    state = const AsyncLoading();
    final authRepo = ref.read(authRepositoryProvider);
    final result = await authRepo.signInWithGoogle();

    if (result is RepoSuccess<String>) {
      final localProfile = ref.read(playerProfileProvider).valueOrNull;
      final effectiveUsername = authRepo.currentUsername ?? localProfile?.username;

      state = AsyncData(
        AccountState(
          status: AccountStatus.linked,
          userId: result.value,
          username: effectiveUsername,
          hasVerifiedSession: true,
        ),
      );
    } else {
      state = AsyncData(
        AccountState(
          status: AccountStatus.guest,
          username: ref.read(playerProfileProvider).valueOrNull?.username,
          hasVerifiedSession: false,
        ),
      );
    }

    return result;
  }

  /// Keluar dari akun.
  Future<RepoResult<void>> signOut() async {
    final authRepo = ref.read(authRepositoryProvider);
    final result = await authRepo.signOut();

    state = AsyncData(
      AccountState(
        status: AccountStatus.guest,
        username: ref.read(playerProfileProvider).valueOrNull?.username,
        hasVerifiedSession: false,
      ),
    );

    return result;
  }

  /// Menetapkan username (minimal 4 karakter).
  Future<RepoResult<void>> setUsername(String username) async {
    final clean = username.trim();
    if (clean.length < 4) {
      return const RepoFailure('Username minimal 4 karakter');
    }

    final authRepo = ref.read(authRepositoryProvider);
    final result = await authRepo.setUsername(clean);

    if (result is RepoSuccess<void>) {
      final current = state.valueOrNull ?? const AccountState(status: AccountStatus.guest);
      state = AsyncData(current.copyWith(username: clean));

      // Simpan juga ke player profile lokal
      final profile = ref.read(playerProfileProvider).valueOrNull;
      if (profile != null) {
        final updated = profile.copyWith(username: clean);
        final playerRepo = ref.read(playerRepositoryProvider);
        await playerRepo.saveProfile(updated);
        ref.read(playerProfileProvider.notifier).state = AsyncData(updated);
      }
    }

    return result;
  }
}
