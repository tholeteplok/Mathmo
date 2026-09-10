import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mathmo_app/domain/models/player_profile.dart';
import 'package:mathmo_app/domain/repositories/player_repository.dart';
import 'package:mathmo_app/domain/repositories/repo_result.dart';
import 'package:mathmo_app/presentation/game/providers/game_dependencies_provider.dart';
import 'package:mathmo_app/presentation/profile/widgets/avatar_selection_dialog.dart';

void main() {
  group('AvatarSelectionDialog Widget Tests', () {
    testWidgets('renders dialog title, default initial option, and avatar presets',
        (tester) async {
      final mockRepo = _MockPlayerRepo();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            playerRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: AvatarSelectionDialog(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Pilih Avatar'), findsOneWidget);
      expect(find.text('Inisial Huruf Depan (Default)'), findsOneWidget);

      // Verify preset avatar images are rendered
      expect(find.byType(Image), findsNWidgets(9));
    });
  });
}

class _MockPlayerRepo implements PlayerRepository {
  PlayerProfile _profile = PlayerProfile.initial(playerId: 'test_player');

  @override
  Future<RepoResult<PlayerProfile>> getProfile() async => RepoSuccess(_profile);

  @override
  Future<RepoResult<void>> saveProfile(PlayerProfile profile) async {
    _profile = profile;
    return const RepoSuccess(null);
  }

  @override
  Future<RepoResult<PlayerProfile>> recordDailyActivity(DateTime date) async =>
      RepoSuccess(_profile);

  @override
  Future<RepoResult<PlayerProfile>> updateLevel(int newLevel) async =>
      RepoSuccess(_profile);
}
