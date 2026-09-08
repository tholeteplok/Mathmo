/// Model untuk pertanyaan matematika, tingkat kesulitan kognitif, dan tipe operasi.
///
/// File ini adalah Pure Dart dan tidak bergantung pada Flutter atau Riverpod.
library;

/// Jenis operasi aritmatika yang didukung dalam permainan.
enum Operation {
  /// Penjumlahan (+)
  add('add', '+'),

  /// Pengurangan (−)
  subtract('subtract', '−'),

  /// Perkalian (×)
  multiply('multiply', '×'),

  /// Pembagian (÷)
  divide('divide', '÷'),

  /// Operasi campuran (mis. kombinasi operasi dalam satu level)
  mixed('mixed', 'mixed'),

  /// Operasi multi-langkah campuran (mis. (a + b) × c)
  mixedMultistep('mixed_multistep', 'multistep');

  const Operation(this.wireName, this.symbol);

  /// Nama representasi saat diserialisasi ke JSON.
  final String wireName;

  /// Simbol tampilan matematika.
  final String symbol;

  /// Mengonversi nilai String dari JSON ke enum [Operation].
  static Operation fromJson(String value) {
    return switch (value.toLowerCase().trim()) {
      'add' || '+' => Operation.add,
      'subtract' || '-' || '−' => Operation.subtract,
      'multiply' || '*' || '×' || 'x' => Operation.multiply,
      'divide' || '/' || '÷' || ':' => Operation.divide,
      'mixed' => Operation.mixed,
      'mixed_multistep' || 'mixedmultistep' => Operation.mixedMultistep,
      _ => throw ArgumentError('Nilai Operation tidak valid: $value'),
    };
  }

  /// Serialisasi ke string JSON.
  String toJson() => wireName;
}

/// Besaran/orde digit dari operand dalam soal.
enum OperandMagnitude {
  /// 1 digit (0–9)
  oneDigit('1-digit'),

  /// 2 digit (10–99)
  twoDigit('2-digit'),

  /// 3 digit (100–999)
  threeDigit('3-digit');

  const OperandMagnitude(this.wireName);

  /// String representasi JSON.
  final String wireName;

  /// Mengonversi nilai String dari JSON ke enum [OperandMagnitude].
  static OperandMagnitude fromJson(String value) {
    return switch (value.toLowerCase().trim()) {
      '1-digit' || 'onedigit' || '1' => OperandMagnitude.oneDigit,
      '2-digit' || 'twodigit' || '2' => OperandMagnitude.twoDigit,
      '3-digit' || 'threedigit' || '3' => OperandMagnitude.threeDigit,
      _ => throw ArgumentError('Nilai OperandMagnitude tidak valid: $value'),
    };
  }

  /// Serialisasi ke string JSON.
  String toJson() => wireName;
}

/// Sifat struktural kognitif dari operasi (mis. perlu simpan/pinjam).
enum StructuralProperty {
  /// Memerlukan carry-over (penjumlahan berulang/menyimpan).
  requiresCarry('requires_carry'),

  /// Memerlukan peminjaman (pengurangan dengan borrow).
  requiresBorrow('requires_borrow'),

  /// Melewati batas dekade (mis. 27 + 8 melompati 30).
  crossesDecade('crosses_decade'),

  /// Tidak ada komplikasi struktural (fakta standar/lurus).
  none('none');

  const StructuralProperty(this.wireName);

  /// String representasi JSON.
  final String wireName;

  /// Mengonversi nilai String dari JSON ke enum [StructuralProperty].
  static StructuralProperty fromJson(String value) {
    return switch (value.toLowerCase().trim()) {
      'requires_carry' || 'requirescarry' => StructuralProperty.requiresCarry,
      'requires_borrow' ||
      'requiresborrow' => StructuralProperty.requiresBorrow,
      'crosses_decade' || 'crossesdecade' => StructuralProperty.crossesDecade,
      'none' => StructuralProperty.none,
      _ => throw ArgumentError('Nilai StructuralProperty tidak valid: $value'),
    };
  }

  /// Serialisasi ke string JSON.
  String toJson() => wireName;
}

/// Tag strategi kognitif yang dipaksa digunakan otak untuk menyelesaikan soal.
///
/// Berdasarkan riset strategi aritmatika (Siegler) untuk mengukur fluency:
/// - [retrieval]: Dihafal langsung dari memori jangka panjang (mis. 6x7, 10-2).
/// - [counting]: Masih menghitung manual berurutan (tahap awal).
/// - [derived]: Turunan dari fakta lain (mis. 7+8 = 7+7+1, kompensasi 19+6 = 20+6-1).
/// - [procedural]: Algoritma prosedural bertahap (mis. perkalian susun 2-digit).
enum StrategyTag {
  retrieval('retrieval'),
  counting('counting'),
  derived('derived'),
  procedural('procedural');

  const StrategyTag(this.wireName);

  /// String representasi JSON.
  final String wireName;

  /// Mengonversi nilai String dari JSON ke enum [StrategyTag].
  static StrategyTag fromJson(String value) {
    return switch (value.toLowerCase().trim()) {
      'retrieval' => StrategyTag.retrieval,
      'counting' => StrategyTag.counting,
      'derived' => StrategyTag.derived,
      'procedural' => StrategyTag.procedural,
      _ => throw ArgumentError('Nilai StrategyTag tidak valid: $value'),
    };
  }

  /// Serialisasi ke string JSON.
  String toJson() => wireName;
}

/// Model multi-dimensi kesulitan soal.
///
/// Tidak hanya mengukur jumlah digit, tetapi menangkap kompleksitas
/// struktural dan strategi kognitif yang dituntut.
class QuestionDifficulty {
  const QuestionDifficulty({
    required this.operandMagnitude,
    required this.structuralProperty,
    required this.strategyTag,
    this.stepCount = 1,
  });

  /// Besaran digit operand (1-digit, 2-digit, 3-digit).
  final OperandMagnitude operandMagnitude;

  /// Sifat struktural operasi (carry, borrow, crosses decade, none).
  final StructuralProperty structuralProperty;

  /// Tag strategi kognitif yang diharapkan.
  final StrategyTag strategyTag;

  /// Jumlah langkah perhitungan (1, 2, 3).
  final int stepCount;

  /// Membuat [QuestionDifficulty] dari Map JSON.
  factory QuestionDifficulty.fromJson(Map<String, dynamic> json) {
    return QuestionDifficulty(
      operandMagnitude: OperandMagnitude.fromJson(
        json['operand_magnitude'] as String,
      ),
      structuralProperty: StructuralProperty.fromJson(
        json['structural_property'] as String,
      ),
      strategyTag: StrategyTag.fromJson(json['strategy_tag'] as String),
      stepCount: (json['step_count'] as num?)?.toInt() ?? 1,
    );
  }

  /// Serialisasi ke Map JSON.
  Map<String, dynamic> toJson() {
    return {
      'operand_magnitude': operandMagnitude.toJson(),
      'structural_property': structuralProperty.toJson(),
      'strategy_tag': strategyTag.toJson(),
      'step_count': stepCount,
    };
  }

  /// Membuat salinan objek dengan field yang dimodifikasi.
  QuestionDifficulty copyWith({
    OperandMagnitude? operandMagnitude,
    StructuralProperty? structuralProperty,
    StrategyTag? strategyTag,
    int? stepCount,
  }) {
    return QuestionDifficulty(
      operandMagnitude: operandMagnitude ?? this.operandMagnitude,
      structuralProperty: structuralProperty ?? this.structuralProperty,
      strategyTag: strategyTag ?? this.strategyTag,
      stepCount: stepCount ?? this.stepCount,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QuestionDifficulty &&
          runtimeType == other.runtimeType &&
          operandMagnitude == other.operandMagnitude &&
          structuralProperty == other.structuralProperty &&
          strategyTag == other.strategyTag &&
          stepCount == other.stepCount;

  @override
  int get hashCode =>
      Object.hash(operandMagnitude, structuralProperty, strategyTag, stepCount);

  @override
  String toString() =>
      'QuestionDifficulty(operandMagnitude: $operandMagnitude, '
      'structuralProperty: $structuralProperty, strategyTag: $strategyTag, '
      'stepCount: $stepCount)';
}

/// Data model untuk satu pertanyaan matematika (Question).
///
/// Membawa identitas unik [id], kunci fakta [factKey] untuk Mastery Bank,
/// operand, jawaban benar, serta parameter tingkat kesulitan.
class Question {
  const Question({
    required this.id,
    required this.factKey,
    required this.operation,
    required this.operands,
    required this.correctAnswer,
    required this.difficulty,
    required this.levelBand,
    required this.level,
  });

  /// ID unik pertanyaan (mis. 'q_8f3a1c').
  final String id;

  /// Kunci fakta aritmatika unik (mis. '7x8', 'add_crossdecade_2digit').
  /// Digunakan oleh Mastery Bank dan Distractor Generator.
  final String factKey;

  /// Operasi matematika yang dilakukan.
  final Operation operation;

  /// Daftar operand (mis. [7, 8] untuk 7 x 8).
  final List<int> operands;

  /// Jawaban yang benar.
  final int correctAnswer;

  /// Parameter kesulitan multi-dimensi.
  final QuestionDifficulty difficulty;

  /// ID band tingkat kesulitan (mis. 'onboarding', 'basic', 'intermediate').
  final String levelBand;

  /// Level permainan saat soal ini dimunculkan (mis. 12).
  final int level;

  /// String ekspresi matematika untuk ditampilkan di UI (mis. "7 × 8").
  String get displayExpression {
    if (operands.length == 2) {
      return '${operands[0]} ${operation.symbol} ${operands[1]}';
    }
    return operands.join(' ${operation.symbol} ');
  }

  /// Membuat [Question] dari Map JSON.
  factory Question.fromJson(Map<String, dynamic> json) {
    final operandsRaw = json['operands'] as List<dynamic>;
    final operandsList = operandsRaw.map((e) => (e as num).toInt()).toList();

    return Question(
      id: json['id'] as String,
      factKey: (json['fact_key'] ?? json['factKey']) as String,
      operation: Operation.fromJson(json['operation'] as String),
      operands: operandsList,
      correctAnswer: ((json['correct_answer'] ?? json['correctAnswer']) as num)
          .toInt(),
      difficulty: QuestionDifficulty.fromJson(
        json['difficulty'] as Map<String, dynamic>,
      ),
      levelBand: (json['level_band'] ?? json['levelBand']) as String,
      level: (json['level'] as num).toInt(),
    );
  }

  /// Serialisasi ke Map JSON yang kompatibel dengan format spesifikasi.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fact_key': factKey,
      'operation': operation.toJson(),
      'operands': operands,
      'correct_answer': correctAnswer,
      'difficulty': difficulty.toJson(),
      'level_band': levelBand,
      'level': level,
    };
  }

  /// Membuat salinan objek dengan field yang dimodifikasi.
  Question copyWith({
    String? id,
    String? factKey,
    Operation? operation,
    List<int>? operands,
    int? correctAnswer,
    QuestionDifficulty? difficulty,
    String? levelBand,
    int? level,
  }) {
    return Question(
      id: id ?? this.id,
      factKey: factKey ?? this.factKey,
      operation: operation ?? this.operation,
      operands: operands ?? this.operands,
      correctAnswer: correctAnswer ?? this.correctAnswer,
      difficulty: difficulty ?? this.difficulty,
      levelBand: levelBand ?? this.levelBand,
      level: level ?? this.level,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Question || runtimeType != other.runtimeType) return false;

    if (id != other.id ||
        factKey != other.factKey ||
        operation != other.operation ||
        correctAnswer != other.correctAnswer ||
        difficulty != other.difficulty ||
        levelBand != other.levelBand ||
        level != other.level ||
        operands.length != other.operands.length) {
      return false;
    }

    for (var i = 0; i < operands.length; i++) {
      if (operands[i] != other.operands[i]) return false;
    }

    return true;
  }

  @override
  int get hashCode => Object.hash(
    id,
    factKey,
    operation,
    Object.hashAll(operands),
    correctAnswer,
    difficulty,
    levelBand,
    level,
  );

  @override
  String toString() =>
      'Question(id: $id, factKey: $factKey, expr: $displayExpression, '
      'correct: $correctAnswer, level: $level)';
}
