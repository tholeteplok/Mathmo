/// Model untuk pilihan pengalih (Distractor) berbasis kesalahan kognitif nyata.
///
/// File ini adalah Pure Dart dan tidak bergantung pada Flutter atau Riverpod.
library;

/// Taksonomi tipe kesalahan prosedural/kognitif yang menjadi dasar pembuatan opsi pengecoh.
///
/// Distraktor berkualitas bukan angka acak, melainkan hasil miskonsepsi nyata
/// agar tantangan terasa adil dan dapat dicatat di Mistake Bank.
enum ErrorType {
  /// Penjumlahan: Lupa carry-over (jumlah per kolom tanpa carry).
  lupaCarry('lupa_carry', 'Lupa Carry-Over'),

  /// Penjumlahan/Pengurangan: Hasil benar meleset 10 (±10).
  offBy10('off_by_10', 'Meleset 10 (Off-by-10)'),

  /// Pengurangan: Lupa borrow (kurangi per kolom dengan nilai absolut).
  lupaBorrow('lupa_borrow', 'Lupa Borrow'),

  /// Pengurangan/Pembagian: Operan tertukar arah (b - a alih-alih a - b, atau b ÷ a).
  tertukarArah('tertukar_arah', 'Tertukar Arah Operan'),

  /// Perkalian: Salah mengganti operasi menjadi penjumlahan (a + b bukan a × b).
  swapToMultiplyOrAdd(
    'operation_swap_add',
    'Salah Operasi (Tambah alih-alih Kali)',
  ),

  /// Perkalian: Menggunakan fakta tabel tetangga (a × (b ± 1)).
  adjacentFactTable('adjacent_fact_table', 'Fakta Tabel Tetangga'),

  /// Perkalian: Hanya mengalikan satu digit (digit puluhan diabaikan).
  onlyMultiplyOneDigit('only_multiply_one_digit', 'Hanya Kalikan Satu Digit'),

  /// Pembagian: Kesalahan pembulatan nilai sisa bagi.
  remainderWrongRounding(
    'remainder_wrong_rounding',
    'Salah Bulatkan Sisa Bagi',
  ),

  /// Kesalahan lain di luar taksonomi utama (mis. near-miss acak saat kekurangan distraktor).
  other('other', 'Lainnya');

  const ErrorType(this.wireName, this.description);

  /// Nama representasi saat diserialisasi ke JSON.
  final String wireName;

  /// Deskripsi singkat kesalahan dalam Bahasa Indonesia.
  final String description;

  /// Mengonversi nilai String dari JSON ke enum [ErrorType].
  static ErrorType fromJson(String value) {
    return switch (value.toLowerCase().trim()) {
      'lupa_carry' || 'lupacarry' || 'carry_forgotten' => ErrorType.lupaCarry,
      'off_by_10' || 'offby10' => ErrorType.offBy10,
      'lupa_borrow' ||
      'lupaborrow' ||
      'borrow_forgotten' => ErrorType.lupaBorrow,
      'tertukar_arah' ||
      'tertukararah' ||
      'direction_swapped' => ErrorType.tertukarArah,
      'operation_swap_add' ||
      'operationswapadd' ||
      'swap_to_multiply_or_add' ||
      'swaptomultiplyoradd' => ErrorType.swapToMultiplyOrAdd,
      'adjacent_fact_table' ||
      'adjacentfacttable' => ErrorType.adjacentFactTable,
      'only_multiply_one_digit' ||
      'onlymultiplyonedigit' => ErrorType.onlyMultiplyOneDigit,
      'remainder_wrong_rounding' ||
      'remainderwrongrounding' => ErrorType.remainderWrongRounding,
      'other' => ErrorType.other,
      _ => ErrorType.other,
    };
  }

  /// Serialisasi ke string JSON.
  String toJson() => wireName;
}

/// Representasi satu nilai opsi pengalih (Distractor) beserta tipe kesalahannya.
class Distractor {
  const Distractor({required this.value, required this.errorType});

  /// Nilai angka yang ditampilkan sebagai opsi salah.
  final int value;

  /// Tipe kesalahan prosedural yang mendasari angka ini.
  final ErrorType errorType;

  /// Membuat [Distractor] dari Map JSON.
  factory Distractor.fromJson(Map<String, dynamic> json) {
    return Distractor(
      value: (json['value'] as num).toInt(),
      errorType: ErrorType.fromJson(
        (json['error_type'] ?? json['errorType'] ?? 'other') as String,
      ),
    );
  }

  /// Serialisasi ke Map JSON.
  Map<String, dynamic> toJson() {
    return {'value': value, 'error_type': errorType.toJson()};
  }

  /// Membuat salinan objek dengan field yang dimodifikasi.
  Distractor copyWith({int? value, ErrorType? errorType}) {
    return Distractor(
      value: value ?? this.value,
      errorType: errorType ?? this.errorType,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Distractor &&
          runtimeType == other.runtimeType &&
          value == other.value &&
          errorType == other.errorType;

  @override
  int get hashCode => Object.hash(value, errorType);

  @override
  String toString() => 'Distractor(value: $value, errorType: $errorType)';
}

/// Kumpulan opsi pengecoh yang terikat pada satu pertanyaan.
///
/// Menggunakan array virtual `values = [correctAnswer, ...distractors]`
/// dan [shuffledIndices] sebagai urutan tombol di UI untuk menjamin tidak ada
/// duplikasi atau jawaban benar yang hilang.
class QuestionDistractors {
  const QuestionDistractors({
    required this.questionId,
    required this.distractors,
    required this.shuffledIndices,
  });

  /// ID pertanyaan pemilik distractor ini.
  final String questionId;

  /// Daftar 3 opsi distraktor.
  final List<Distractor> distractors;

  /// Permutasi indeks tampilan `[0..3]`, di mana indeks 0 merujuk ke jawaban benar.
  final List<int> shuffledIndices;

  /// Menghasilkan urutan angka yang akan ditampilkan di 4 tombol UI.
  ///
  /// `values = [correctAnswer, ...distractors.map((d) => d.value)]`
  /// Tombol ke-k menampilkan `values[shuffledIndices[k]]`.
  List<int> getDisplayValues(int correctAnswer) {
    final values = <int>[correctAnswer, ...distractors.map((d) => d.value)];
    return shuffledIndices.map((i) => values[i]).toList();
  }

  /// Memeriksa apakah indeks tombol yang dipilih pemain adalah jawaban yang benar.
  ///
  /// Jawaban benar selalu dipetakan dari indeks 0 virtual.
  bool isCorrectIndex(int selectedIndex) {
    if (selectedIndex < 0 || selectedIndex >= shuffledIndices.length) {
      return false;
    }
    return shuffledIndices[selectedIndex] == 0;
  }

  /// Mengambil objek [Distractor] pada tombol ke-[selectedIndex].
  ///
  /// Mengembalikan `null` jika [selectedIndex] adalah jawaban benar.
  Distractor? getDistractorAt(int selectedIndex) {
    if (selectedIndex < 0 || selectedIndex >= shuffledIndices.length) {
      return null;
    }
    final virtualIndex = shuffledIndices[selectedIndex];
    if (virtualIndex == 0) return null; // Jawaban benar
    final distractorIndex = virtualIndex - 1;
    if (distractorIndex >= 0 && distractorIndex < distractors.length) {
      return distractors[distractorIndex];
    }
    return null;
  }

  /// Mengambil [ErrorType] dari tombol salah yang ditekan pemain.
  ErrorType? getErrorTypeAt(int selectedIndex) {
    return getDistractorAt(selectedIndex)?.errorType;
  }

  /// Membuat [QuestionDistractors] dari Map JSON.
  factory QuestionDistractors.fromJson(Map<String, dynamic> json) {
    final distractorsRaw = json['distractors'] as List<dynamic>;
    final distractorsList = distractorsRaw
        .map((e) => Distractor.fromJson(e as Map<String, dynamic>))
        .toList();

    final indicesRaw =
        (json['shuffled_indices'] ?? json['shuffledIndices']) as List<dynamic>;
    final indicesList = indicesRaw.map((e) => (e as num).toInt()).toList();

    return QuestionDistractors(
      questionId: (json['question_id'] ?? json['questionId']) as String,
      distractors: distractorsList,
      shuffledIndices: indicesList,
    );
  }

  /// Serialisasi ke Map JSON.
  Map<String, dynamic> toJson() {
    return {
      'question_id': questionId,
      'distractors': distractors.map((d) => d.toJson()).toList(),
      'shuffled_indices': shuffledIndices,
    };
  }

  /// Membuat salinan objek dengan field yang dimodifikasi.
  QuestionDistractors copyWith({
    String? questionId,
    List<Distractor>? distractors,
    List<int>? shuffledIndices,
  }) {
    return QuestionDistractors(
      questionId: questionId ?? this.questionId,
      distractors: distractors ?? this.distractors,
      shuffledIndices: shuffledIndices ?? this.shuffledIndices,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! QuestionDistractors || runtimeType != other.runtimeType) {
      return false;
    }

    if (questionId != other.questionId ||
        distractors.length != other.distractors.length ||
        shuffledIndices.length != other.shuffledIndices.length) {
      return false;
    }

    for (var i = 0; i < distractors.length; i++) {
      if (distractors[i] != other.distractors[i]) return false;
    }

    for (var i = 0; i < shuffledIndices.length; i++) {
      if (shuffledIndices[i] != other.shuffledIndices[i]) return false;
    }

    return true;
  }

  @override
  int get hashCode => Object.hash(
    questionId,
    Object.hashAll(distractors),
    Object.hashAll(shuffledIndices),
  );

  @override
  String toString() =>
      'QuestionDistractors(qid: $questionId, distractors: ${distractors.length}, '
      'shuffled: $shuffledIndices)';
}

/// Alias untuk [QuestionDistractors].
typedef DistractorSet = QuestionDistractors;
