import 'activity.dart';
import 'runner.dart';
import 'training.dart';

/// ゲーム全体の状態。JSONで丸ごと永続化する。
class GameState {
  const GameState({
    required this.runner,
    required this.tp,
    required this.activities,
    required this.trainings,
    required this.hallOfFame,
  });

  final Runner? runner;
  final int tp;
  final List<ActivityRecord> activities;
  final List<TrainingResult> trainings;

  /// 殿堂入り(引退済み)ランナー。Phase 3 の継承で使う。
  final List<Runner> hallOfFame;

  static const empty = GameState(
    runner: null,
    tp: 0,
    activities: [],
    trainings: [],
    hallOfFame: [],
  );

  int get nextGeneration =>
      hallOfFame.isEmpty ? 1 : hallOfFame.last.generation + 1;

  /// 今日(同じ年月日)の移動距離合計(m)。
  int distanceTodayMeters(DateTime now) => activities
      .where((a) =>
          a.recordedAt.year == now.year &&
          a.recordedAt.month == now.month &&
          a.recordedAt.day == now.day)
      .fold(0, (sum, a) => sum + a.distanceMeters);

  int get totalDistanceMeters =>
      activities.fold(0, (sum, a) => sum + a.distanceMeters);

  GameState copyWith({
    Runner? runner,
    bool clearRunner = false,
    int? tp,
    List<ActivityRecord>? activities,
    List<TrainingResult>? trainings,
    List<Runner>? hallOfFame,
  }) =>
      GameState(
        runner: clearRunner ? null : (runner ?? this.runner),
        tp: tp ?? this.tp,
        activities: activities ?? this.activities,
        trainings: trainings ?? this.trainings,
        hallOfFame: hallOfFame ?? this.hallOfFame,
      );

  Map<String, dynamic> toJson() => {
        'runner': runner?.toJson(),
        'tp': tp,
        'activities': activities.map((a) => a.toJson()).toList(),
        'trainings': trainings.map((t) => t.toJson()).toList(),
        'hallOfFame': hallOfFame.map((r) => r.toJson()).toList(),
      };

  factory GameState.fromJson(Map<String, dynamic> json) => GameState(
        runner: json['runner'] == null
            ? null
            : Runner.fromJson(json['runner'] as Map<String, dynamic>),
        tp: json['tp'] as int? ?? 0,
        activities: (json['activities'] as List<dynamic>? ?? [])
            .map((e) => ActivityRecord.fromJson(e as Map<String, dynamic>))
            .toList(),
        trainings: (json['trainings'] as List<dynamic>? ?? [])
            .map((e) => TrainingResult.fromJson(e as Map<String, dynamic>))
            .toList(),
        hallOfFame: (json['hallOfFame'] as List<dynamic>? ?? [])
            .map((e) => Runner.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
