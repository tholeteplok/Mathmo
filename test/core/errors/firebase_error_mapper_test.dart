import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mathmo_app/core/errors/firebase_error_mapper.dart';

void main() {
  group('FirebaseErrorMapper Tests', () {
    test('maps unavailable error code to user-friendly message', () {
      final exception = FirebaseException(
        plugin: 'cloud_firestore',
        code: 'unavailable',
        message: 'The service is currently unavailable.',
      );

      final message = FirebaseErrorMapper.map(exception);
      expect(
        message,
        'Layanan database belum aktif di server atau koneksi terputus. Pastikan koneksi internet aktif lalu coba lagi beberapa saat.',
      );
    });

    test('maps permission-denied error code to security message', () {
      final exception = FirebaseException(
        plugin: 'cloud_firestore',
        code: 'permission-denied',
        message: 'Missing or insufficient permissions.',
      );

      final message = FirebaseErrorMapper.map(exception);
      expect(
        message,
        'Akses database ditolak oleh aturan keamanan server. Silakan hubungi admin atau periksa konfigurasi akun.',
      );
    });

    test('maps TimeoutException to timeout message', () {
      final exception = TimeoutException('Timeout');
      final message = FirebaseErrorMapper.map(exception);
      expect(
        message,
        'Koneksi ke server melebihi batas waktu (timeout). Pastikan jaringan internet stabil lalu coba lagi.',
      );
    });

    test('maps generic error containing unavailable string', () {
      final genericError = Exception('Status 14 UNAVAILABLE: backend unreachable');
      final message = FirebaseErrorMapper.map(genericError);
      expect(
        message,
        'Layanan database sedang tidak tersedia atau koneksi terputus. Coba beberapa saat lagi.',
      );
    });

    test('uses defaultMessage as fallback when error is unknown', () {
      final genericError = Exception('unknown internal problem');
      final message = FirebaseErrorMapper.map(
        genericError,
        defaultMessage: 'Gagal memproses data akun',
      );
      expect(message, 'Gagal memproses data akun');
    });

    test('maps PlatformException Developer Error 10 (missing SHA-1) clearly', () {
      final platformError = Exception('com.google.android.gms.common.api.ApiException: 10: ');
      final message = FirebaseErrorMapper.map(platformError);
      expect(
        message,
        contains('SHA-1 fingerprint'),
      );
    });

    test('maps PlatformException Error 12500 clearly', () {
      final platformError = Exception('com.google.android.gms.common.api.ApiException: 12500: ');
      final message = FirebaseErrorMapper.map(platformError);
      expect(
        message,
        contains('12500'),
      );
    });
  });
}
