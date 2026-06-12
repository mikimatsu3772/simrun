import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simrun/app/game_controller.dart';
import 'package:simrun/data/distance_source.dart';
import 'package:simrun/data/game_repository.dart';
import 'package:simrun/domain/stats.dart';

void main() {
  test('1世代フルサイクル: 距離注入 → TP → トレーニング → 引退 → 次世代', () async {
    final repo = InMemoryGameRepository();
    final mock = MockDistanceSource();
    final container = ProviderContainer(overrides: [
      gameRepositoryProvider.overrideWithValue(repo),
      distanceSourceProvider.overrideWithValue(mock),
    ]);
    addTearDown(container.dispose);

    // 初回起動: 1世代目のルーキーが生まれる
    var state = await container.read(gameControllerProvider.future);
    expect(state.runner, isNotNull);
    expect(state.runner!.generation, 1);
    expect(state.tp, 0);

    // 距離を注入(昼5km = 50TP)
    mock.inject(5000, timestamp: DateTime.now().copyWith(hour: 12));
    await Future<void>.delayed(const Duration(milliseconds: 50));
    state = container.read(gameControllerProvider).value!;
    expect(state.tp, 50);
    expect(state.activities.single.distanceMeters, 5000);

    // トレーニング(30TP消費)
    final before = state.runner!.stats[StatType.speed];
    final ok = await container
        .read(gameControllerProvider.notifier)
        .train(StatType.speed, 30);
    expect(ok, isTrue);
    state = container.read(gameControllerProvider).value!;
    expect(state.tp, 20);
    expect(state.runner!.stats[StatType.speed], greaterThan(before));
    expect(state.trainings, hasLength(1));

    // まだ引退期限前なので引退しない
    expect(
        await container.read(gameControllerProvider.notifier).checkRetirement(),
        isNull);

    // 時計を15日進めて引退 → 殿堂入り&次世代誕生
    container.read(gameControllerProvider.notifier).advanceClock(
        const Duration(days: 15));
    final retired = await container
        .read(gameControllerProvider.notifier)
        .checkRetirement();
    expect(retired, isNotNull);
    expect(retired!.generation, 1);

    state = container.read(gameControllerProvider).value!;
    expect(state.hallOfFame.single.retired, isTrue);
    expect(state.runner!.generation, 2);
    expect(state.runner!.retired, isFalse);

    // 永続化も世代交代後の状態になっている
    final persisted = await repo.load();
    expect(persisted.hallOfFame, hasLength(1));
    expect(persisted.runner!.generation, 2);
  });
}
