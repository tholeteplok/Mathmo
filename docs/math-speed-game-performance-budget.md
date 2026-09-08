# Speed Math Game — Performance Budget

## 1. Target Frame Rate

**60fps sebagai target utama, bukan 120fps.**

Alasan: mayoritas HP Android mid-range di pasar Indonesia (target realistis untuk game edukasi ini) masih ber-refresh rate 60Hz — mengejar 120fps di sini tidak memberi manfaat terlihat ke pemain (device tidak bisa menampilkannya), tapi tetap membakar budget CPU/GPU dan baterai untuk komputasi ekstra yang sia-sia. Kalau nanti ada device 120Hz, Flutter otomatis sync ke refresh rate device selama widget tree ringan — tidak perlu optimasi eksplisit terpisah untuk itu.

**Budget waktu per frame @ 60fps: 16.6ms.** Ini bukan angka longgar — game ini punya timer serendah 2.5–3.5 detik di level tinggi (§2 `math-speed-game-spec.md`), jadi drop frame terasa langsung sebagai "lag" yang secara langsung merugikan pemain di soal yang justru paling ketat waktunya.

## 2. Batasan Widget Rebuild

### 2.1 Pisahkan state yang sering berubah dari state struktural

Ini revisi penting terhadap desain state management sebelumnya: `Active.timeRemainingMs` di sealed class `GameSessionState` (§3 `math-speed-game-state-management.md`) **bukan** driver live untuk progress bar — itu cuma snapshot yang dipakai saat transisi (mis. dibekukan ketika masuk `Paused`). Progress bar yang benar-benar berjalan tiap frame **tidak boleh** lewat `StateNotifier` Riverpod sama sekali.

```dart
// widgets/countdown_progress_bar.dart
class CountdownProgressBar extends StatefulWidget {
  final Duration duration;
  final VoidCallback onTimeout;
  // ...
}

class _CountdownProgressBarState extends State<CountdownProgressBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) widget.onTimeout();
      })
      ..forward();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => CustomPaint(
        painter: ProgressBarPainter(progress: 1 - _controller.value),
      ),
    );
  }
}
```

`AnimationController` berjalan lokal di widget ini, di-drive langsung oleh Flutter's ticker — **tidak** memicu `ref.watch` di widget lain, **tidak** rebuild `GameSessionState` tiap frame. `GameSessionNotifier` hanya dipanggil sekali di ujung: saat `onTimeout` terpanggil (transisi state), atau saat `Paused`/`resumed` (§3.1 state management spec) untuk stop/start controller ini.

### 2.2 Ceiling rebuild

| Elemen | Rebuild rate | Cara jaga |
|---|---|---|
| Progress bar (`CustomPaint`) | ~60x/detik — ini **repaint**, bukan widget rebuild penuh | Isolasi dengan `RepaintBoundary` supaya repaint tidak menyeret parent widget ikut re-layout |
| `GameScreen` (struktur soal, grid jawaban) | Maksimum 1x per transisi state (`ShowQuestion → Active → Feedback → next`) | `ref.watch(gameSessionProvider.select((s) => s.runtimeType))` atau pattern-match sealed class — hindari watch seluruh state kalau cuma butuh tahu "fase apa sekarang" |
| Badge streak/XP di header | Hanya saat nilainya benar-benar berubah | `ref.watch(playerProfileProvider.select((p) => p.streak))` — Riverpod `select` mencegah rebuild kalau field lain di profile berubah tapi streak tidak |
| Kanvas warna per level band | Hanya saat level berubah (bukan tiap frame) | `levelBandThemeProvider` (§5 state management spec) sudah derived dari level, otomatis tidak rebuild di luar itu |

**Aturan umum**: kalau sebuah widget rebuild lebih dari sekali per transisi gameplay yang terlihat mata (bukan animasi kontinu seperti progress bar), itu tanda `ref.watch` terlalu luas cakupannya — ganti dengan `select`.

## 3. Batasan Ukuran Asset

| Kategori | Batas | Alasan |
|---|---|---|
| Total asset bundel (font, JSON config, icon) | < 3MB | HP mid-range sasaran biasanya storage terbatas & unduhan awal app perlu ringan — instalasi besar jadi friksi pertama sebelum pemain sempat mencoba game |
| `level_bands.json` dan config JSON lain | Beberapa KB (sudah sangat kecil secara alami — teks terstruktur) | Tidak jadi masalah, disebut untuk kelengkapan |
| Font (tabular numerals monospace) | 1 file `.ttf`/`.otf`, ~100–300KB, subset ke karakter yang dipakai (digit, operator, huruf UI) kalau ukuran default lebih besar | Font lengkap dengan seluruh Unicode range bisa >1MB tanpa perlu — subsetting memangkas signifikan tanpa kehilangan karakter yang benar-benar dipakai |
| Ikon (flame, bolt, lock, check, dsb.) | SVG/vector, bukan PNG raster | Vector di-render tajam di semua kepadatan layar tanpa perlu multiple asset (`@1x/@2x/@3x`), dan ukurannya jauh lebih kecil untuk bentuk sederhana seperti ikon UI |
| Animasi (kalau ada, mis. transisi level-up) | Hindari Lottie/Rive kompleks untuk MVP; cukup `AnimatedContainer`/`AnimatedScale` bawaan Flutter | Gaya visual chunky/playful yang sudah dipilih (border tebal, offset shadow datar, bukan blur) **sudah murah secara render** — jangan tambahkan animasi berat yang mengorbankan keunggulan performa dari pilihan visual ini |

### Catatan penting: gaya visual chunky yang dipilih justru menguntungkan performa

`box-shadow: 0 4px 0` ala tombol chunky (§4 `math-speed-game-visual-design-spec.md`) itu **shadow offset solid, bukan blur** — di Flutter ini setara `Container` dengan `BoxDecoration` + border, jauh lebih murah dirender dibanding `Material` elevation shadow bawaan (yang pakai blur/`BoxShadow` dengan `blurRadius`) atau efek `BackdropFilter` (blur belakang) yang berat di GPU HP mid-range. Jadi keputusan gaya visual yang sudah disepakati sebelumnya kebetulan selaras dengan performance budget ini — tidak perlu kompromi visual demi performa.

## 4. Ringkasan Angka

| Metrik | Target |
|---|---|
| Frame rate | 60fps stabil (bukan 120fps) |
| Budget waktu per frame | 16.6ms |
| Rebuild `GameScreen` | ≤ 1x per transisi state gameplay |
| Repaint progress bar | ~60x/detik, terisolasi `RepaintBoundary` |
| Total asset bundel | < 3MB |
| Font UI | Ter-subset, < 300KB |
| Efek blur/backdrop filter | Dihindari di jalur gameplay utama |
