import 'dart:developer' as dev;
import 'package:audioplayers/audioplayers.dart';

/// Service terpusat untuk memutar Background Music (BGM) loop per bioma.
class BgmService {
  BgmService({AudioPlayer? player}) : _player = player ?? AudioPlayer();

  final AudioPlayer _player;
  String? _currentTrack;
  bool _isMuted = false;

  String? get currentTrack => _currentTrack;
  bool get isMuted => _isMuted;

  /// Memutar file musik aset secara loop jika belum memutar track yang sama.
  Future<void> playTrack(String assetPath) async {
    if (_currentTrack == assetPath) {
      await resume();
      return;
    }

    _currentTrack = assetPath;

    try {
      final cleanPath = assetPath.startsWith('assets/')
          ? assetPath.substring(7)
          : assetPath;

      await _player.setReleaseMode(ReleaseMode.loop);
      await _player.setVolume(_isMuted ? 0.0 : 1.0);
      await _player.play(AssetSource(cleanPath));
    } catch (e, st) {
      dev.log('BgmService play error: ', stackTrace: st, name: 'BgmService');
    }
  }

  /// Mengubah status Mute / Unmute audio.
  Future<void> toggleMute() async {
    await setMuted(!_isMuted);
  }

  /// Mengatur status Mute audio secara eksplisit.
  Future<void> setMuted(bool muted) async {
    _isMuted = muted;
    try {
      await _player.setVolume(_isMuted ? 0.0 : 1.0);
    } catch (e) {
      dev.log('BgmService setVolume error: ', name: 'BgmService');
    }
  }

  /// Menghentikan sementara musik (misal saat app ke background).
  Future<void> pause() async {
    try {
      await _player.pause();
    } catch (e) {
      dev.log('BgmService pause error: ', name: 'BgmService');
    }
  }

  /// Melanjutkan musik.
  Future<void> resume() async {
    if (_currentTrack == null) return;
    try {
      await _player.resume();
    } catch (e) {
      dev.log('BgmService resume error: ', name: 'BgmService');
    }
  }

  /// Menghentikan musik.
  Future<void> stop() async {
    _currentTrack = null;
    try {
      await _player.stop();
    } catch (e) {
      dev.log('BgmService stop error: ', name: 'BgmService');
    }
  }

  /// Membersihkan resource audio player.
  void dispose() {
    _player.dispose();
  }
}
