import 'dart:async';

/// 距離の取得イベント。メートル単位。
class DistanceSample {
  const DistanceSample({required this.meters, required this.timestamp});

  final int meters;
  final DateTime timestamp;
}

/// 距離取得の抽象。
/// 実機では HealthKit / Health Connect 実装、開発中はモック実装を使う。
abstract class DistanceSource {
  /// 新しい移動距離が確定するたびに流れるストリーム。
  Stream<DistanceSample> get samples;

  Future<void> start();
  Future<void> dispose();
}

/// 開発・テスト用のモック。デバッグパネルから手動で距離を注入する。
class MockDistanceSource implements DistanceSource {
  final _controller = StreamController<DistanceSample>.broadcast();

  @override
  Stream<DistanceSample> get samples => _controller.stream;

  @override
  Future<void> start() async {}

  /// デバッグパネルから呼ぶ。[timestamp] 省略時は現在時刻。
  void inject(int meters, {DateTime? timestamp}) {
    _controller.add(
      DistanceSample(meters: meters, timestamp: timestamp ?? DateTime.now()),
    );
  }

  @override
  Future<void> dispose() async {
    await _controller.close();
  }
}
