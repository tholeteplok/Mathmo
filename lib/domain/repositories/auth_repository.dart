import 'repo_result.dart';

/// Kontrak repositori untuk autentikasi dan identitas pemain online.
abstract class AuthRepository {
  /// Stream perubahan ID user aktif (null jika logout / guest).
  Stream<String?> get authStateChanges;

  /// ID pemain yang sedang login di Firebase Auth (null jika guest).
  String? get currentUserId;

  /// Username pemain yang terdaftar di cloud (null jika belum membuat username).
  String? get currentUsername;

  /// Menandai apakah pemain saat ini login sebagai akun anonim.
  bool get isAnonymous;

  /// Menandai apakah pemain sudah terautentikasi (anonim atau Google).
  bool get isLoggedIn;

  /// Masuk secara anonim ke Firebase Auth.
  Future<RepoResult<String>> signInAnonymously();

  /// Masuk menggunakan akun Google.
  Future<RepoResult<String>> signInWithGoogle();

  /// Keluar dari sesi akun saat ini (kembali ke mode tamu lokal).
  Future<RepoResult<void>> signOut();

  /// Menetapkan username unik pemain (minimal 4 karakter).
  Future<RepoResult<void>> setUsername(String username);

  /// Mengecek apakah suatu username masih tersedia (belum dipakai pemain lain).
  Future<RepoResult<bool>> isUsernameAvailable(String username);
}
