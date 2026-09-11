import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mathmo_app/domain/repositories/repo_result.dart';
import 'package:mathmo_app/presentation/leaderboard/widgets/leaderboard_screen.dart';
import 'package:mathmo_app/presentation/profile/providers/account_status_provider.dart';
import 'package:mathmo_app/presentation/profile/widgets/create_account_cta.dart';
import 'package:mathmo_app/presentation/profile/widgets/set_username_dialog.dart';

class MockAccountStatusNotifier extends AccountStatusNotifier {
  MockAccountStatusNotifier(this._initialState, {AccountState? afterSignInState})
      : _afterSignInState = afterSignInState ?? _initialState;

  final AccountState _initialState;
  final AccountState _afterSignInState;

  @override
  AccountState build() => _initialState;

  @override
  Future<RepoResult<String>> signInWithGoogle() async {
    state = AsyncData(_afterSignInState);
    return const RepoSuccess('uid_123');
  }

  @override
  Future<RepoResult<String>> signInAnonymously() async {
    state = AsyncData(_afterSignInState);
    return const RepoSuccess('uid_anon');
  }
}

void main() {
  testWidgets('showWelcomeBackGreeting renders floating SnackBar with username', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showWelcomeBackGreeting(context, 'Budi123'),
              child: const Text('Show Greeting'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Show Greeting'));
    await tester.pumpAndSettle();

    expect(find.text('Selamat datang kembali, petualang Budi123!'), findsOneWidget);
    expect(find.byIcon(Icons.celebration_rounded), findsOneWidget);
  });

  testWidgets('handlePostSignInFlow shows welcome back greeting when user has username', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          accountStatusProvider.overrideWith(
            () => MockAccountStatusNotifier(
              const AccountState(
                status: AccountStatus.linked,
                userId: 'uid_123',
                username: 'JuaraMath',
                hasVerifiedSession: true,
              ),
            ),
          ),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Consumer(
              builder: (context, ref, _) => ElevatedButton(
                onPressed: () => handlePostSignInFlow(context, ref),
                child: const Text('Trigger Flow'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.text('Trigger Flow'));
    await tester.pumpAndSettle();

    expect(find.text('Selamat datang kembali, petualang JuaraMath!'), findsOneWidget);
    expect(find.text('Buat Username'), findsNothing);
  });

  testWidgets('handlePostSignInFlow shows SetUsernameDialog when user has no username', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          accountStatusProvider.overrideWith(
            () => MockAccountStatusNotifier(
              const AccountState(
                status: AccountStatus.linked,
                userId: 'uid_123',
                username: null,
                hasVerifiedSession: true,
              ),
            ),
          ),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Consumer(
              builder: (context, ref, _) => ElevatedButton(
                onPressed: () => handlePostSignInFlow(context, ref),
                child: const Text('Trigger Flow'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.text('Trigger Flow'));
    await tester.pumpAndSettle();

    expect(find.text('Buat Username'), findsOneWidget);
    expect(find.textContaining('Selamat datang kembali'), findsNothing);
  });

  testWidgets('CreateAccountCta shows greeting on Google sign-in if account already has username', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          accountStatusProvider.overrideWith(
            () => MockAccountStatusNotifier(
              const AccountState(status: AccountStatus.guest),
              afterSignInState: const AccountState(
                status: AccountStatus.linked,
                userId: 'uid_123',
                username: 'PetualangHebat',
                hasVerifiedSession: true,
              ),
            ),
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: CreateAccountCta(
              accountState: AccountState(status: AccountStatus.guest),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.text('Masuk dengan Google'));
    await tester.pumpAndSettle();

    expect(find.text('Selamat datang kembali, petualang PetualangHebat!'), findsOneWidget);
    expect(find.text('Buat Username'), findsNothing);
  });

  testWidgets('LeaderboardScreen shows greeting on Google sign-in if account already has username', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          accountStatusProvider.overrideWith(
            () => MockAccountStatusNotifier(
              const AccountState(status: AccountStatus.guest),
              afterSignInState: const AccountState(
                status: AccountStatus.linked,
                userId: 'uid_123',
                username: 'BintangMath',
                hasVerifiedSession: true,
              ),
            ),
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: LeaderboardScreen(),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.text('Masuk dengan Google'));
    await tester.pumpAndSettle();

    expect(find.text('Selamat datang kembali, petualang BintangMath!'), findsOneWidget);
    expect(find.text('Buat Username'), findsNothing);
  });
}
