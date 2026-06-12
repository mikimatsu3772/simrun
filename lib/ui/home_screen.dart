import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/game_controller.dart';
import '../domain/game_state.dart';
import '../domain/runner.dart';
import '../domain/stats.dart';
import 'debug_panel.dart';
import 'log_screen.dart';
import 'training_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final game = ref.watch(gameControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('SIMRUN'),
        actions: [
          IconButton(
            icon: const Icon(Icons.list_alt),
            tooltip: '記録',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const LogScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.bug_report),
            tooltip: 'デバッグ',
            onPressed: () => showDebugPanel(context, ref),
          ),
        ],
      ),
      body: game.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('エラー: $e')),
        data: (state) => _HomeBody(state: state),
      ),
    );
  }
}

class _HomeBody extends ConsumerWidget {
  const _HomeBody({required this.state});

  final GameState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final runner = state.runner;
    if (runner == null) {
      return const Center(child: Text('ランナーがいません'));
    }
    final now = DateTime.now().add(ref.watch(clockProvider));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _RunnerCard(runner: runner, now: now),
        const SizedBox(height: 16),
        _TodayCard(state: state, now: now),
        const SizedBox(height: 16),
        FilledButton.icon(
          icon: const Icon(Icons.fitness_center),
          label: const Text('トレーニング'),
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const TrainingScreen()),
          ),
        ),
        const SizedBox(height: 16),
        if (state.hallOfFame.isNotEmpty) _HallOfFameCard(state: state),
      ],
    );
  }
}

class _RunnerCard extends ConsumerWidget {
  const _RunnerCard({required this.runner, required this.now});

  final Runner runner;
  final DateTime now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final remaining = runner.remainingDays(now);
    final canRetire = runner.shouldRetire(now);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(runner.name,
                    style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(width: 8),
                Chip(label: Text('第${runner.generation}世代')),
              ],
            ),
            const SizedBox(height: 4),
            Text('${runner.type.label} / 得意: ${runner.aptitude.label}'
                '(${runner.aptitude.range})'),
            const SizedBox(height: 12),
            for (final stat in StatType.values)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    SizedBox(width: 72, child: Text(stat.label)),
                    Expanded(
                      child: LinearProgressIndicator(
                        value: runner.stats[stat] / Stats.maxValue,
                        minHeight: 8,
                      ),
                    ),
                    SizedBox(
                      width: 48,
                      child: Text('${runner.stats[stat]}',
                          textAlign: TextAlign.end),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            if (canRetire)
              FilledButton.tonal(
                onPressed: () async {
                  final retired = await ref
                      .read(gameControllerProvider.notifier)
                      .checkRetirement();
                  if (retired != null && context.mounted) {
                    showDialog<void>(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: Text('${retired.name} 引退!'),
                        content: Text(
                            '第${retired.generation}世代 ${retired.name} は殿堂入りしました。\n'
                            '総合力: ${retired.stats.total}\n\n'
                            '新たなルーキーがチームに加わります。'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('次世代へ'),
                          ),
                        ],
                      ),
                    );
                  }
                },
                child: const Text('引退式を行う'),
              )
            else
              Text('引退まで あと$remaining日',
                  style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _TodayCard extends StatelessWidget {
  const _TodayCard({required this.state, required this.now});

  final GameState state;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final todayKm = state.distanceTodayMeters(now) / 1000;
    final totalKm = state.totalDistanceMeters / 1000;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _Metric(label: '今日の移動', value: '${todayKm.toStringAsFixed(1)} km'),
            _Metric(label: '累積', value: '${totalKm.toStringAsFixed(1)} km'),
            _Metric(label: '所持TP', value: '${state.tp}'),
          ],
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        Text(value, style: Theme.of(context).textTheme.titleLarge),
      ],
    );
  }
}

class _HallOfFameCard extends StatelessWidget {
  const _HallOfFameCard({required this.state});

  final GameState state;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('殿堂', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            for (final r in state.hallOfFame.reversed)
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.emoji_events),
                title: Text('第${r.generation}世代 ${r.name}'),
                subtitle: Text('${r.type.label} / 総合力 ${r.stats.total}'),
              ),
          ],
        ),
      ),
    );
  }
}
