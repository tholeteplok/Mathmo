import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mathmo_app/data/services/update_service.dart';
import 'package:mathmo_app/presentation/shared/widgets/update_dialog.dart';

void main() {
  const dummyInfo = AppUpdateInfo(
    hasUpdate: true,
    currentVersion: '0.1.0+1',
    latestVersion: 'v0.2.0',
    releaseName: 'iTHUNG v0.2.0',
    releaseNotes: 'Fitur baru dan perbaikan stabilitas.',
    downloadUrl: 'https://example.com/ithung.apk',
    htmlUrl: 'https://github.com/tholeteplok/iTHUNG/releases',
    matchedAbi: 'arm64-v8a',
    downloadSizeBytes: 18 * 1024 * 1024,
    formattedSize: '18.0 MB · Hemat ~65%',
  );

  testWidgets('UpdateNotificationDialog renders version, notes, badges and triggers onUpdate',
      (tester) async {
    var updatePressed = false;
    var laterPressed = false;

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: UpdateNotificationDialog(
              info: dummyInfo,
              onUpdate: () {
                updatePressed = true;
              },
              onLater: () {
                laterPressed = true;
              },
            ),
          ),
        ),
      ),
    );

    // Verify elements
    expect(find.text('Pembaruan Tersedia 🚀'), findsOneWidget);
    expect(find.text('Versi v0.2.0'), findsOneWidget);
    expect(find.text('18.0 MB · Hemat ~65%'), findsOneWidget);
    expect(find.text('arm64-v8a'), findsOneWidget);
    expect(find.text('Fitur baru dan perbaikan stabilitas.'), findsOneWidget);

    // Tap Perbarui Sekarang
    await tester.tap(find.text('Perbarui Sekarang'));
    await tester.pump();
    expect(updatePressed, isTrue);

    // Tap Nanti Saja
    await tester.tap(find.text('Nanti Saja'));
    await tester.pump();
    expect(laterPressed, isTrue);
  });
}
