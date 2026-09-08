import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/level_band_theme.dart';
import '../../../domain/models/level_band_config.dart';
import '../../home/providers/player_profile_provider.dart';

/// Provider konfigurasi Level Bands yang dimuat SEKALI dari `assets/level_bands.json`.
final levelBandsConfigProvider = FutureProvider<LevelBandsConfig>((ref) async {
  return loadLevelBandsConfig();
});

/// Provider tema dinamis level band saat ini.
///
/// Diturunkan secara reaktif dari [levelBandsConfigProvider] dan level pemain di [playerProfileProvider].
final levelBandThemeProvider = Provider<AsyncValue<LevelBandTheme>>((ref) {
  final playerProfile = ref.watch(playerProfileProvider).valueOrNull;
  final currentLevel = playerProfile?.currentLevel ?? 1;

  final configAsync = ref.watch(levelBandsConfigProvider);
  return configAsync.whenData(
    (config) => resolveLevelBandTheme(config, currentLevel),
  );
});
