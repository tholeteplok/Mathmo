import 'package:flutter_test/flutter_test.dart';
import 'package:mathmo_app/data/services/update_service.dart';

void main() {
  late UpdateService service;

  setUp(() {
    service = UpdateService();
  });

  group('UpdateService Version Comparison & Odometer Logic', () {
    test('standard patch increment is detected as newer', () {
      expect(service.isNewerVersion('0.1.1', '0.1.0'), isTrue);
      expect(service.isNewerVersion('0.1.9', '0.1.8'), isTrue);
    });

    test('odometer rollover from 9 to 0 with minor carry is detected as newer', () {
      expect(service.isNewerVersion('0.2.0', '0.1.9'), isTrue);
      expect(service.isNewerVersion('v0.2.0', 'v0.1.9'), isTrue);
    });

    test('odometer double rollover from 0.9.9 to 1.0.0 is detected as newer', () {
      expect(service.isNewerVersion('1.0.0', '0.9.9'), isTrue);
    });

    test('odometer leftmost digit rollover beyond 9 (9.9.9 -> 10.0.0)', () {
      expect(service.isNewerVersion('10.0.0', '9.9.9'), isTrue);
    });

    test('same version is not newer', () {
      expect(service.isNewerVersion('0.1.0', '0.1.0'), isFalse);
      expect(service.isNewerVersion('v0.1.0', '0.1.0'), isFalse);
    });

    test('older version is not newer', () {
      expect(service.isNewerVersion('0.1.8', '0.1.9'), isFalse);
      expect(service.isNewerVersion('0.1.0', '0.2.0'), isFalse);
    });

    test('build number increment is detected as newer if semver matches', () {
      expect(service.isNewerVersion('0.1.0+5', '0.1.0+4'), isTrue);
      expect(service.isNewerVersion('0.1.0+4', '0.1.0+5'), isFalse);
    });
  });

  group('UpdateService Smart ABI Matching & Size Formatting', () {
    test('matches arm64-v8a asset when supported', () {
      final assets = [
        {'name': 'iTHUNG-v0.2.0-universal.apk', 'browser_download_url': 'url_uni'},
        {'name': 'iTHUNG-v0.2.0-arm64-v8a.apk', 'browser_download_url': 'url_arm64'},
        {'name': 'iTHUNG-v0.2.0-armeabi-v7a.apk', 'browser_download_url': 'url_armv7'},
      ];

      final matched = service.matchBestApkAsset(
        assets: assets,
        supportedAbis: ['arm64-v8a', 'armeabi-v7a'],
      );

      expect(matched, isNotNull);
      expect(matched!['matchedAbi'], equals('arm64-v8a'));
      expect((matched['asset'] as Map)['browser_download_url'], equals('url_arm64'));
    });

    test('falls back to universal asset when device ABI is not split', () {
      final assets = [
        {'name': 'iTHUNG-v0.2.0-armeabi-v7a.apk', 'browser_download_url': 'url_armv7'},
        {'name': 'iTHUNG-v0.2.0-universal.apk', 'browser_download_url': 'url_uni'},
      ];

      final matched = service.matchBestApkAsset(
        assets: assets,
        supportedAbis: ['x86_64'],
      );

      expect(matched, isNotNull);
      expect(matched!['matchedAbi'], equals('universal'));
      expect((matched['asset'] as Map)['browser_download_url'], equals('url_uni'));
    });

    test('formatApkSize displays MB and savings badge', () {
      const bytes18Mb = 18 * 1024 * 1024;
      const bytes55Mb = 55 * 1024 * 1024;

      expect(service.formatApkSize(bytes18Mb), contains('Hemat ~65%'));
      expect(service.formatApkSize(bytes55Mb), contains('55.0 MB'));
    });
  });

  group('UpdateService Friendly Release Notes Parsing', () {
    test('parses categorized notes with tags into ReleaseNoteItems', () {
      const raw = '''
- [FIX] Perbaikan autentikasi Google Sign-In
- [FEAT] Level baru Fresh Sprout Meadow
- [PERF] Gameplay 60fps lebih mulus
- [UI] Nomor versi lebih bersih
- [GENERAL] Pemeliharaan kode berkala
''';

      final items = service.parseReleaseNotes(raw);
      expect(items.length, equals(5));

      expect(items[0].category, equals(ReleaseCategory.fix));
      expect(items[0].categoryLabel, equals('Perbaikan Penting'));
      expect(items[0].text, contains('Perbaikan autentikasi Google Sign-In'));

      expect(items[1].category, equals(ReleaseCategory.feat));
      expect(items[1].categoryLabel, equals('Fitur Baru'));

      expect(items[2].category, equals(ReleaseCategory.perf));
      expect(items[2].categoryLabel, equals('Peningkatan Performa'));

      expect(items[3].category, equals(ReleaseCategory.ui));
      expect(items[3].categoryLabel, equals('Penyempurnaan Tampilan'));

      expect(items[4].category, equals(ReleaseCategory.general));
    });

    test('strips raw changelog urls and headers, uses friendly fallback if empty', () {
      const raw = '**Full Changelog**: https://github.com/tholeteplok/iTHUNG/compare/v0.4.0...v0.4.1';

      final items = service.parseReleaseNotes(raw);
      expect(items, isNotEmpty);
      // Ensures no url is present
      for (final item in items) {
        expect(item.text.contains('http'), isFalse);
        expect(item.text.contains('Full Changelog'), isFalse);
      }
      expect(items.any((i) => i.category == ReleaseCategory.perf), isTrue);
      expect(items.any((i) => i.category == ReleaseCategory.fix), isTrue);
      expect(items.any((i) => i.category == ReleaseCategory.ui), isTrue);
    });

    test('parses conventional commit prefixes correctly', () {
      const raw = '''
fix(auth): resolve sha1 credential issue
feat(game): add new sound effect
perf: improve frame rendering speed
style(ui): align badge padding
''';

      final items = service.parseReleaseNotes(raw);
      expect(items.length, equals(4));
      expect(items[0].category, equals(ReleaseCategory.fix));
      expect(items[1].category, equals(ReleaseCategory.feat));
      expect(items[2].category, equals(ReleaseCategory.perf));
      expect(items[3].category, equals(ReleaseCategory.ui));
    });
  });

  group('UpdateService Resumable & Error Sanitization Tests', () {
    test('sanitizes Connection closed and HttpException into friendly progress message', () {
      const rawError =
          'HttpException: Connection closed while receiving data, uri = https://release-assets.githubusercontent.com/...?sp=r&sv=2018&sig=xyz123';
      const downloadedBytes = 8 * 1024 * 1024; // 8.0 MB
      const totalBytes = 29 * 1024 * 1024; // 29.0 MB

      final message = service.sanitizeErrorMessage(rawError, downloadedBytes, totalBytes);

      expect(message, contains('Koneksi terputus saat mengunduh'));
      expect(message, contains('8.0 MB tersimpan'));
      expect(message, contains('29.0 MB'));
      expect(message, isNot(contains('sp=r')));
      expect(message, isNot(contains('sig=')));
      expect(message, isNot(contains('https://')));
    });

    test('sanitizes long query string URLs from arbitrary exceptions', () {
      const raw = 'Exception: Server error at https://example.com/asset?token=secret123&expire=999';
      final message = service.sanitizeErrorMessage(raw, 0, null);

      expect(message, isNot(contains('token=secret123')));
      expect(message, contains('Server error at https://example.com/asset'));
    });
  });
}
