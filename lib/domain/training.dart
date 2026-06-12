import 'runner.dart';
import 'stats.dart';

/// トレーニング1回の結果。
class TrainingResult {
  const TrainingResult({
    required this.stat,
    required this.spentTp,
    required this.gained,
    required this.executedAt,
  });

  final StatType stat;
  final int spentTp;
  final int gained;
  final DateTime executedAt;

  Map<String, dynamic> toJson() => {
        'stat': stat.name,
        'spentTp': spentTp,
        'gained': gained,
        'executedAt': executedAt.toIso8601String(),
      };

  factory TrainingResult.fromJson(Map<String, dynamic> json) => TrainingResult(
        stat: StatType.values.byName(json['stat'] as String),
        spentTp: json['spentTp'] as int,
        gained: json['gained'] as int,
        executedAt: DateTime.parse(json['executedAt'] as String),
      );
}

/// トレーニングロジック。TP消費 → 成長傾向係数を掛けて成長。
class Trainer {
  /// 10TP につき基本成長 +5。成長傾向係数で増減する。
  static const int tpPerUnit = 10;
  static const int gainPerUnit = 5;

  /// [tp] を消費して [stat] を鍛える。TPが足りない・上限到達なら null。
  static (Runner, TrainingResult)? train(
    Runner runner, {
    required StatType stat,
    required int tp,
    required int availableTp,
    required DateTime now,
  }) {
    if (runner.retired) return null;
    if (tp <= 0 || tp > availableTp) return null;
    if (runner.stats[stat] >= Stats.maxValue) return null;

    final units = tp / tpPerUnit;
    final gained = (units * gainPerUnit * runner.growthRates[stat]).round();
    if (gained <= 0) return null;

    final updated = runner.copyWith(stats: runner.stats.add(stat, gained));
    final actualGain = updated.stats[stat] - runner.stats[stat];
    return (
      updated,
      TrainingResult(
        stat: stat,
        spentTp: tp,
        gained: actualGain,
        executedAt: now,
      ),
    );
  }
}
