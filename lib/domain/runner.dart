import 'dart:math';

import 'stats.dart';

/// ランナーのタイプ(素質)。
enum RunnerType {
  speedster('スピード型'),
  stayer('スタミナ型'),
  fighter('根性型'),
  balanced('バランス型');

  const RunnerType(this.label);
  final String label;
}

/// 得意距離。
enum DistanceAptitude {
  short('短距離', '〜5km'),
  middle('中距離', '〜ハーフ'),
  long('長距離', 'フル');

  const DistanceAptitude(this.label, this.range);
  final String label;
  final String range;
}

/// 世代の長さ(日数)。
const int generationLengthDays = 14;

class Runner {
  const Runner({
    required this.id,
    required this.name,
    required this.bornAt,
    required this.type,
    required this.aptitude,
    required this.stats,
    required this.growthRates,
    required this.generation,
    this.retired = false,
  });

  final String id;
  final String name;
  final DateTime bornAt;
  final RunnerType type;
  final DistanceAptitude aptitude;
  final Stats stats;
  final GrowthRates growthRates;

  /// 何世代目か(1始まり)。
  final int generation;
  final bool retired;

  /// 引退予定日。
  DateTime get retireAt => bornAt.add(const Duration(days: generationLengthDays));

  /// 世代の残り日数(0未満にはならない)。
  int remainingDays(DateTime now) {
    final diff = retireAt.difference(now).inDays;
    return diff < 0 ? 0 : diff;
  }

  bool shouldRetire(DateTime now) => !retired && !now.isBefore(retireAt);

  Runner copyWith({Stats? stats, bool? retired}) => Runner(
        id: id,
        name: name,
        bornAt: bornAt,
        type: type,
        aptitude: aptitude,
        stats: stats ?? this.stats,
        growthRates: growthRates,
        generation: generation,
        retired: retired ?? this.retired,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'bornAt': bornAt.toIso8601String(),
        'type': type.name,
        'aptitude': aptitude.name,
        'stats': stats.toJson(),
        'growthRates': growthRates.toJson(),
        'generation': generation,
        'retired': retired,
      };

  factory Runner.fromJson(Map<String, dynamic> json) => Runner(
        id: json['id'] as String,
        name: json['name'] as String,
        bornAt: DateTime.parse(json['bornAt'] as String),
        type: RunnerType.values.byName(json['type'] as String),
        aptitude: DistanceAptitude.values.byName(json['aptitude'] as String),
        stats: Stats.fromJson(json['stats'] as Map<String, dynamic>),
        growthRates:
            GrowthRates.fromJson(json['growthRates'] as Map<String, dynamic>),
        generation: json['generation'] as int? ?? 1,
        retired: json['retired'] as bool? ?? false,
      );

  /// 新規ランナーを生成する。タイプに応じて初期値と成長傾向が偏る。
  factory Runner.rookie({
    required String name,
    required DateTime now,
    required int generation,
    Random? random,
  }) {
    final rng = random ?? Random();
    final type = RunnerType.values[rng.nextInt(RunnerType.values.length)];
    final aptitude =
        DistanceAptitude.values[rng.nextInt(DistanceAptitude.values.length)];

    int base() => 80 + rng.nextInt(41); // 80〜120
    double rate(bool strong) =>
        strong ? 1.15 + rng.nextDouble() * 0.25 : 0.85 + rng.nextDouble() * 0.25;

    final growthRates = switch (type) {
      RunnerType.speedster => GrowthRates(
          speed: rate(true), power: rate(true),
          stamina: rate(false), guts: rate(false), wisdom: rate(false)),
      RunnerType.stayer => GrowthRates(
          stamina: rate(true), wisdom: rate(true),
          speed: rate(false), power: rate(false), guts: rate(false)),
      RunnerType.fighter => GrowthRates(
          guts: rate(true), power: rate(true),
          speed: rate(false), stamina: rate(false), wisdom: rate(false)),
      RunnerType.balanced => GrowthRates(
          speed: 1.0 + rng.nextDouble() * 0.1,
          stamina: 1.0 + rng.nextDouble() * 0.1,
          power: 1.0 + rng.nextDouble() * 0.1,
          guts: 1.0 + rng.nextDouble() * 0.1,
          wisdom: 1.0 + rng.nextDouble() * 0.1),
    };

    return Runner(
      id: '${now.millisecondsSinceEpoch}-${rng.nextInt(0xFFFFFF)}',
      name: name,
      bornAt: now,
      type: type,
      aptitude: aptitude,
      stats: Stats(
        speed: base(),
        stamina: base(),
        power: base(),
        guts: base(),
        wisdom: base(),
      ),
      growthRates: growthRates,
      generation: generation,
    );
  }
}
