import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/distance_source.dart';
import '../data/game_repository.dart';
import '../domain/activity.dart';
import '../domain/game_state.dart';
import '../domain/runner.dart';
import '../domain/stats.dart';
import '../domain/training.dart';

final gameRepositoryProvider =
    Provider<GameRepository>((ref) => PrefsGameRepository());

final distanceSourceProvider = Provider<DistanceSource>((ref) {
  final source = MockDistanceSource();
  ref.onDispose(source.dispose);
  return source;
});

/// デバッグ用の時計。日付送りデバッグのためにオフセットを持てる。
final clockProvider =
    NotifierProvider<ClockNotifier, Duration>(ClockNotifier.new);

class ClockNotifier extends Notifier<Duration> {
  @override
  Duration build() => Duration.zero;

  void advance(Duration d) => state = state + d;
}

final gameControllerProvider =
    AsyncNotifierProvider<GameController, GameState>(GameController.new);

class GameController extends AsyncNotifier<GameState> {
  StreamSubscription<DistanceSample>? _sub;

  DateTime get _now => DateTime.now().add(ref.read(clockProvider));

  @override
  Future<GameState> build() async {
    final repo = ref.watch(gameRepositoryProvider);
    final source = ref.watch(distanceSourceProvider);

    var loaded = await repo.load();
    // 初回起動なら1世代目のルーキーを生成する。
    if (loaded.runner == null) {
      loaded = loaded.copyWith(
        runner: Runner.rookie(
          name: '1号',
          now: _now,
          generation: loaded.nextGeneration,
        ),
      );
      await repo.save(loaded);
    }

    await _sub?.cancel();
    _sub = source.samples.listen(_onDistance);
    ref.onDispose(() => _sub?.cancel());
    await source.start();

    return loaded;
  }

  Future<void> _mutate(GameState Function(GameState) update) async {
    final current = state.value;
    if (current == null) return;
    final next = update(current);
    state = AsyncData(next);
    await ref.read(gameRepositoryProvider).save(next);
  }

  void _onDistance(DistanceSample sample) {
    final slot = TimeSlot.fromHour(sample.timestamp.hour);
    final tp = TpConverter.convert(sample.meters, slot);
    _mutate((s) => s.copyWith(
          tp: s.tp + tp,
          activities: [
            ...s.activities,
            ActivityRecord(
              recordedAt: sample.timestamp,
              distanceMeters: sample.meters,
              timeSlot: slot,
              earnedTp: tp,
            ),
          ],
        ));
  }

  /// トレーニング実行。成功時 true。
  Future<bool> train(StatType stat, int tp) async {
    final s = state.value;
    final runner = s?.runner;
    if (s == null || runner == null) return false;

    final result = Trainer.train(
      runner,
      stat: stat,
      tp: tp,
      availableTp: s.tp,
      now: _now,
    );
    if (result == null) return false;

    final (updated, training) = result;
    await _mutate((s) => s.copyWith(
          runner: updated,
          tp: s.tp - training.spentTp,
          trainings: [...s.trainings, training],
        ));
    return true;
  }

  /// 引退期限が来ていれば引退処理を行い、次世代ランナーを迎える。
  /// 引退が発生したら殿堂入りしたランナーを返す。
  Future<Runner?> checkRetirement() async {
    final s = state.value;
    final runner = s?.runner;
    if (s == null || runner == null || !runner.shouldRetire(_now)) return null;

    final retired = runner.copyWith(retired: true);
    final rookie = Runner.rookie(
      name: '${retired.generation + 1}号',
      now: _now,
      generation: retired.generation + 1,
    );
    await _mutate((s) => s.copyWith(
          runner: rookie,
          hallOfFame: [...s.hallOfFame, retired],
        ));
    return retired;
  }

  /// デバッグ: 時計を進める。
  void advanceClock(Duration d) {
    ref.read(clockProvider.notifier).advance(d);
  }
}
