import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/bgm_service.dart';

/// Provider instance singleton BgmService.
final bgmServiceProvider = Provider<BgmService>((ref) {
  final service = BgmService();
  ref.onDispose(() {
    service.dispose();
  });
  return service;
});

/// StateNotifier untuk memantau dan mengubah status Mute audio.
class BgmMuteNotifier extends StateNotifier<bool> {
  BgmMuteNotifier(this._service) : super(_service.isMuted);

  final BgmService _service;

  Future<void> toggle() async {
    final next = !state;
    state = next;
    await _service.setMuted(next);
  }

  Future<void> setMuted(bool muted) async {
    state = muted;
    await _service.setMuted(muted);
  }
}

final bgmMuteProvider = StateNotifierProvider<BgmMuteNotifier, bool>((ref) {
  final service = ref.watch(bgmServiceProvider);
  return BgmMuteNotifier(service);
});
