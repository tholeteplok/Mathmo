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
  });

  final AccountStatus status;
  final String? userId;
  final String? username;

  bool get isGuest => status == AccountStatus.guest;
  bool get hasUsername => username != null && username!.trim().length >= 4;

  AccountState copyWith({
    AccountStatus? status,
    String? userId,
    String? username,
  }) {
    return AccountState(
      status: status ?? this.status,
      userId: userId ?? this.userId,
      username: username ?? this.username,
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
      return AccountState(
        status: AccountStatus.guest,
        username: localProfile?.username,
      );
    }

    final uid = authRepo.currentUserId;
    final cloudUsername = authRepo.currentUsername;
    final effectiveUsername = cloudUsername ?? localProfile?.username;

    return AccountState(
      status: authRepo.isAnonymous ? AccountStatus.anonymous : AccountStatus.linked,
      userId: uid,
      username: effectiveUsername,
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
        ),
      );
    } else {
      state = AsyncData(
        AccountState(
          status: AccountStatus.guest,
          username: ref.read(playerProfileProvider).valueOrNull?.username,
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
        ),
      );
    } else {
      state = AsyncData(
        AccountState(
          status: AccountStatus.guest,
          username: ref.read(playerProfileProvider).valueOrNull?.username,
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
