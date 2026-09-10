import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../core/errors/firebase_error_mapper.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/repo_result.dart';

/// Implementasi [AuthRepository] menggunakan Firebase Authentication & Cloud Firestore.
class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    GoogleSignIn? googleSignIn,
  }) : _auth = auth,
       _firestore = firestore,
       _googleSignIn = googleSignIn;

  FirebaseAuth? _auth;
  FirebaseFirestore? _firestore;
  GoogleSignIn? _googleSignIn;

  /// Web Client ID dari Firebase project 'teplok-games' untuk pertukaran token kredensial.
  static const String defaultServerClientId =
      '378719226002-4af4bt6hmbf8dlr51p18tu0r3hkl5vid.apps.googleusercontent.com';

  String? _cachedUsername;

  FirebaseAuth get auth => _auth ??= FirebaseAuth.instance;
  FirebaseFirestore get firestore => _firestore ??= FirebaseFirestore.instance;
  GoogleSignIn get googleSignIn =>
      _googleSignIn ??= GoogleSignIn(serverClientId: defaultServerClientId);

  @override
  Stream<String?> get authStateChanges {
    try {
      return auth.authStateChanges().map((user) {
        if (user == null) {
          _cachedUsername = null;
          return null;
        }
        return user.uid;
      });
    } catch (_) {
      return Stream.value(null);
    }
  }

  @override
  String? get currentUserId {
    try {
      return auth.currentUser?.uid;
    } catch (_) {
      return null;
    }
  }

  @override
  String? get currentUsername => _cachedUsername;

  @override
  bool get isAnonymous {
    try {
      return auth.currentUser?.isAnonymous ?? false;
    } catch (_) {
      return false;
    }
  }

  @override
  bool get isLoggedIn {
    try {
      return auth.currentUser != null;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<RepoResult<String>> signInAnonymously() async {
    try {
      final credential = await auth.signInAnonymously();
      final uid = credential.user?.uid;
      if (uid == null) {
        return const RepoFailure('Gagal mendapatkan ID pengguna anonim');
      }
      await _loadUsernameForUid(uid);
      return RepoSuccess(uid);
    } catch (e) {
      return RepoFailure(
        FirebaseErrorMapper.map(e, defaultMessage: 'Gagal masuk secara anonim'),
        e,
      );
    }
  }

  @override
  Future<RepoResult<String>> signInWithGoogle() async {
    try {
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        return const RepoFailure('Login Google dibatalkan');
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final currentUser = auth.currentUser;
      UserCredential userCredential;
      if (currentUser != null && currentUser.isAnonymous) {
        try {
          userCredential = await currentUser.linkWithCredential(credential);
        } on FirebaseAuthException catch (e) {
          if (e.code == 'credential-already-in-use') {
            // Akun Google sudah terdaftar di UID lain, sign in langsung ke akun tersebut
            userCredential = await auth.signInWithCredential(credential);
          } else {
            rethrow;
          }
        }
      } else {
        userCredential = await auth.signInWithCredential(credential);
      }

      final uid = userCredential.user?.uid;
      if (uid == null) {
        return const RepoFailure('Gagal mengautentikasi pengguna dengan Firebase');
      }

      await _loadUsernameForUid(uid);
      return RepoSuccess(uid);
    } catch (e) {
      return RepoFailure(
        FirebaseErrorMapper.map(e, defaultMessage: 'Gagal masuk dengan Google'),
        e,
      );
    }
  }

  @override
  Future<RepoResult<void>> signOut() async {
    try {
      await auth.signOut();
      try {
        await googleSignIn.signOut();
      } catch (_) {}
      _cachedUsername = null;
      return const RepoSuccess(null);
    } catch (e) {
      return RepoFailure('Gagal keluar dari akun: $e', e);
    }
  }

  @override
  Future<RepoResult<bool>> isUsernameAvailable(String username) async {
    final clean = username.trim().toLowerCase();
    if (clean.length < 4) {
      return const RepoSuccess(false);
    }

    try {
      final doc = await firestore
          .collection('usernames')
          .doc(clean)
          .get()
          .timeout(const Duration(seconds: 10));
      return RepoSuccess(!doc.exists);
    } catch (e) {
      return RepoFailure(
        FirebaseErrorMapper.map(
          e,
          defaultMessage: 'Gagal memeriksa ketersediaan username',
        ),
        e,
      );
    }
  }

  @override
  Future<RepoResult<void>> setUsername(String username) async {
    final clean = username.trim();
    if (clean.length < 4) {
      return const RepoFailure('Username harus minimal 4 karakter');
    }

    final uid = currentUserId;
    if (uid == null) {
      return const RepoFailure('Pemain belum terotentikasi');
    }

    final cleanKey = clean.toLowerCase();

    try {
      final usernameDoc = firestore.collection('usernames').doc(cleanKey);
      final userDoc = firestore.collection('profiles').doc(uid);

      // Cek apakah username sudah dipakai
      final existingDoc = await usernameDoc.get().timeout(const Duration(seconds: 10));
      if (existingDoc.exists && existingDoc.data()?['uid'] != uid) {
        return const RepoFailure('Username sudah digunakan pemain lain');
      }

      final batch = firestore.batch();
      batch.set(usernameDoc, {'uid': uid, 'username': clean});
      batch.set(userDoc, {'username': clean, 'updated_at': FieldValue.serverTimestamp()}, SetOptions(merge: true));
      await batch.commit().timeout(const Duration(seconds: 10));

      _cachedUsername = clean;
      return const RepoSuccess(null);
    } catch (e) {
      return RepoFailure(
        FirebaseErrorMapper.map(
          e,
          defaultMessage: 'Gagal menyimpan username',
        ),
        e,
      );
    }
  }

  Future<void> _loadUsernameForUid(String uid) async {
    try {
      final doc = await firestore.collection('profiles').doc(uid).get();
      if (doc.exists) {
        _cachedUsername = doc.data()?['username'] as String?;
      }
    } catch (_) {
      // Graceful offline fallback
    }
  }
}
