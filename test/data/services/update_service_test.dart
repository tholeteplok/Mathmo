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
}
