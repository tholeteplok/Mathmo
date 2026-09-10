/// Kontak developer terpusat — single source of truth untuk link kontak.
///
/// Dipakai oleh kartu "Hubungi Developer" di Settings. Tidak ada hardcode
/// URL/handle di widget; semua berasal dari konstanta ini.
abstract final class DeveloperContact {
  /// Handle Telegram developer.
  static const String telegramHandle = '@tholeteplok';

  /// Link Telegram developer (dibuka di aplikasi eksternal).
  static final Uri telegramUrl = Uri.parse('https://t.me/tholeteplok');

  /// Nomor WhatsApp tampilan (format lokal ramah baca).
  static const String whatsappDisplay = '+62 857-0225-1526';

  /// Link WhatsApp developer (dibuka di aplikasi eksternal).
  static final Uri whatsappUrl = Uri.parse('https://wa.me/6285702251526');
}
