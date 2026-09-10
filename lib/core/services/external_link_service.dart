import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

/// Layanan pembuka link eksternal yang terpusat & testable.
///
/// Semua link keluar aplikasi (kontak developer, dsb.) lewat sini agar
/// konsisten: dibuka di aplikasi eksternal, bukan WebView dalam app.
class ExternalLinkService {
  const ExternalLinkService();

  /// Buka [uri] di aplikasi eksternal. Return `false` bila gagal.
  Future<bool> open(Uri uri) {
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

/// Provider [ExternalLinkService] — override dengan fake di widget test.
final externalLinkServiceProvider = Provider<ExternalLinkService>((ref) {
  return const ExternalLinkService();
});
