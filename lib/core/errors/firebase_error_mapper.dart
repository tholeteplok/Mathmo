import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';

/// Utilitas terpusat untuk memetakan error Firebase, jaringan, dan timeout
/// menjadi pesan bahasa Indonesia yang jelas, ramah pengguna, dan informatif.
class FirebaseErrorMapper {
  FirebaseErrorMapper._();

  /// Mengonversi objek [error] menjadi pesan ramah pengguna.
  ///
  /// Jika diberikan [defaultMessage], pesan tersebut akan digabungkan atau dijadikan fallback.
  static String map(Object error, {String? defaultMessage}) {
    if (error is TimeoutException) {
      return 'Koneksi ke server melebihi batas waktu (timeout). Pastikan jaringan internet stabil lalu coba lagi.';
    }

    if (error is PlatformException) {
      final code = error.code.toLowerCase();
      final msg = (error.message ?? '').toLowerCase();
      final details = (error.details?.toString() ?? '').toLowerCase();
      final combined = '$code $msg $details';

      if (combined.contains(': 10') || combined.contains('code: 10') || combined.contains('developer_error')) {
        return 'Konfigurasi autentikasi Google (SHA-1 fingerprint) belum terdaftar di Firebase Console. Harap daftarkan SHA-1 aplikasi Anda.';
      }
      if (combined.contains(': 12500') || combined.contains('code: 12500')) {
        return 'Gagal menghubungkan ke akun Google. Pastikan perangkat memiliki akun Google aktif dan Google Play Services terbarui.';
      }
      if (combined.contains(': 7') || combined.contains('network_error')) {
        return 'Koneksi ke server Google terganggu. Periksa kestabilan jaringan internet Anda.';
      }
      if (combined.contains('sign_in_canceled') || combined.contains('canceled')) {
        return 'Proses masuk dengan Google dibatalkan.';
      }
      if (error.message != null && error.message!.isNotEmpty) {
        return '$prefix: ${error.message}';
      }
    }

    if (error is FirebaseException) {
      switch (error.code) {
        case 'unavailable':
          return 'Layanan database belum aktif di server atau koneksi terputus. Pastikan koneksi internet aktif lalu coba lagi beberapa saat.';
        case 'permission-denied':
          return 'Akses database ditolak oleh aturan keamanan server. Silakan hubungi admin atau periksa konfigurasi akun.';
        case 'deadline-exceeded':
          return 'Waktu permintaan ke database habis. Periksa kestabilan jaringan internet Anda.';
        case 'network-request-failed':
          return 'Gagal terhubung ke jaringan. Harap periksa koneksi internet pada perangkat Anda.';
        case 'unauthenticated':
          return 'Sesi login telah kedaluwarsa. Silakan masuk kembali ke akun Anda.';
        case 'not-found':
          return 'Data yang dicari tidak ditemukan di server.';
        case 'already-exists':
          return 'Data tersebut sudah ada di sistem.';
        case 'resource-exhausted':
          return 'Batas kuota harian server tercapai. Silakan coba kembali nanti.';
        default:
          final cleanedMessage = error.message?.replaceAll(RegExp(r'\[.*?\]'), '').trim();
          if (cleanedMessage != null && cleanedMessage.isNotEmpty) {
            return '$prefix: $cleanedMessage';
          }
      }
    }

    // Pembersihan string error umum jika mengandung kode teknis
    final errStr = error.toString();
    if (errStr.contains('10:') || errStr.contains('ApiException: 10')) {
      return 'Konfigurasi autentikasi Google (SHA-1 fingerprint) belum terdaftar di Firebase Console. Harap daftarkan SHA-1 aplikasi Anda.';
    }

    if (errStr.contains('12500:') || errStr.contains('ApiException: 12500')) {
      return 'Gagal menghubungkan ke akun Google (Error 12500). Periksa akun Google dan Google Play Services pada perangkat.';
    }

    if (errStr.contains('unavailable') || errStr.contains('UNAVAILABLE')) {
      return 'Layanan database sedang tidak tersedia atau koneksi terputus. Coba beberapa saat lagi.';
    }

    if (errStr.contains('network') || errStr.contains('SocketException')) {
      return 'Terjadi gangguan jaringan internet. Periksa koneksi perangkat Anda.';
    }

    if (defaultMessage != null && defaultMessage.isNotEmpty) {
      return defaultMessage;
    }

    return 'Terjadi kendala saat menghubungkan ke server. Silakan coba lagi.';
  }

  static String get prefix => 'Kendala server';
}
