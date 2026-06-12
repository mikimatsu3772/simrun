import 'dart:convert';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:simrun/domain/activity.dart';
import 'package:simrun/domain/game_state.dart';
import 'package:simrun/domain/runner.dart';
import 'package:simrun/domain/stats.dart';
import 'package:simrun/domain/training.dart';

void main() {
  group('TpConverter', () {
    test('1km = 10TP', () {
      expect(TpConverter.convert(1000, TimeSlot.daytime), 10);
      expect(TpConverter.convert(5000, TimeSlot.daytime), 50);
    });

    test('朝は +10%', () {
      expect(TpConverter.convert(1000, TimeSlot.morning), 11);
    });

    test('端数は切り捨て', () {
      expect(TpConverter.convert(1234, TimeSlot.daytime), 12);
    });
  });

  group('TimeSlot', () {
    test('時間帯の区分', () {
      expect(TimeSlot.fromHour(6), TimeSlot.morning);
      expect(TimeSlot.fromHour(12), TimeSlot.daytime);
      expect(TimeSlot.fromHour(22), TimeSlot.night);
      expect(TimeSlot.fromHour(2), TimeSlot.night);
    });
  });

  group('Trainer', () {
    final now = DateTime(2026, 6, 12);
    final runner = Runner(
      id: 'test',
      name: 'テスト',
      bornAt: now,
      type: RunnerType.balanced,
      aptitude: DistanceAptitude.middle,
      stats: const Stats(speed: 100, stamina: 100, power: 100, guts: 100, wisdom: 100),
      growthRates: const GrowthRates(speed: 1.2),
      generation: 1,
    );

    test('TP消費で成長傾向係数を掛けて成長する', () {
      final result = Trainer.train(runner,
          stat: StatType.speed, tp: 20, availableTp: 50, now: now);
      expect(result, isNotNull);
      final (updated, training) = result!;
      // 20TP = 2unit × 5 × 1.2 = 12
      expect(training.gained, 12);
      expect(updated.stats.speed, 112);
      expect(training.spentTp, 20);
    });

    test('TP不足なら失敗', () {
      expect(
          Trainer.train(runner,
              stat: StatType.speed, tp: 100, availableTp: 50, now: now),
          isNull);
    });

    test('引退済みは鍛えられない', () {
      expect(
          Trainer.train(runner.copyWith(retired: true),
              stat: StatType.speed, tp: 10, availableTp: 50, now: now),
          isNull);
    });

    test('上限でクランプされる', () {
      final maxed =
          runner.copyWith(stats: const Stats(speed: Stats.maxValue));
      expect(
          Trainer.train(maxed,
              stat: StatType.speed, tp: 10, availableTp: 50, now: now),
          isNull);
    });
  });

  group('Runner', () {
    test('14日で引退期限', () {
      final born = DateTime(2026, 6, 1);
      final r = Runner.rookie(name: 'A', now: born, generation: 1);
      expect(r.shouldRetire(DateTime(2026, 6, 14)), isFalse);
      expect(r.shouldRetire(DateTime(2026, 6, 15)), isTrue);
      expect(r.remainingDays(DateTime(2026, 6, 8)), 7);
      expect(r.remainingDays(DateTime(2026, 6, 20)), 0);
    });

    test('JSONラウンドトリップ(ゴースト対戦用のシリアライズ保証)', () {
      final r = Runner.rookie(
          name: 'B', now: DateTime(2026, 6, 1), generation: 3,
          random: Random(42));
      final restored =
          Runner.fromJson(jsonDecode(jsonEncode(r.toJson())) as Map<String, dynamic>);
      expect(restored.id, r.id);
      expect(restored.name, r.name);
      expect(restored.type, r.type);
      expect(restored.aptitude, r.aptitude);
      expect(restored.stats.total, r.stats.total);
      expect(restored.generation, 3);
    });
  });

  group('GameState', () {
    test('JSONラウンドトリップ', () {
      final now = DateTime(2026, 6, 12, 7);
      final runner = Runner.rookie(name: 'C', now: now, generation: 1);
      final state = GameState(
        runner: runner,
        tp: 42,
        activities: [
          ActivityRecord(
            recordedAt: now,
            distanceMeters: 3000,
            timeSlot: TimeSlot.morning,
            earnedTp: 33,
          ),
        ],
        trainings: [
          TrainingResult(
              stat: StatType.guts, spentTp: 10, gained: 5, executedAt: now),
        ],
        hallOfFame: [runner.copyWith(retired: true)],
      );

      final restored = GameState.fromJson(
          jsonDecode(jsonEncode(state.toJson())) as Map<String, dynamic>);
      expect(restored.tp, 42);
      expect(restored.runner?.name, 'C');
      expect(restored.activities.single.earnedTp, 33);
      expect(restored.trainings.single.stat, StatType.guts);
      expect(restored.hallOfFame.single.retired, isTrue);
      expect(restored.nextGeneration, 2);
    });

    test('今日の距離集計', () {
      final now = DateTime(2026, 6, 12, 9);
      final state = GameState.empty.copyWith(activities: [
        ActivityRecord(
            recordedAt: now,
            distanceMeters: 2000,
            timeSlot: TimeSlot.morning,
            earnedTp: 22),
        ActivityRecord(
            recordedAt: now.subtract(const Duration(days: 1)),
            distanceMeters: 5000,
            timeSlot: TimeSlot.daytime,
            earnedTp: 50),
      ]);
      expect(state.distanceTodayMeters(now), 2000);
      expect(state.totalDistanceMeters, 7000);
    });
  });
}
