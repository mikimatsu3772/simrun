import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/game_controller.dart';
import '../domain/stats.dart';
import '../domain/training.dart';

class TrainingScreen extends ConsumerStatefulWidget {
  const TrainingScreen({super.key});

  @override
  ConsumerState<TrainingScreen> createState() => _TrainingScreenState();
}

class _TrainingScreenState extends ConsumerState<TrainingScreen> {
  int _tpToSpend = Trainer.tpPerUnit;

  @override
  Widget build(BuildContext context) {
    final game = ref.watch(gameControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('トレーニング')),
      body: game.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('エラー: $e')),
        data: (state) {
          final runner = state.runner;
          if (runner == null) return const Center(child: Text('ランナーがいません'));

          final maxTp = state.tp;
          final spend = _tpToSpend.clamp(0, maxTp);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text('所持TP: $maxTp',
                          style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 8),
                      if (maxTp >= Trainer.tpPerUnit) ...[
                        Slider(
                          value: spend.toDouble(),
                          min: 0,
                          max: maxTp.toDouble(),
                          divisions: maxTp ~/ Trainer.tpPerUnit,
                          label: '$spend TP',
                          onChanged: (v) => setState(() => _tpToSpend =
                              (v ~/ Trainer.tpPerUnit) * Trainer.tpPerUnit),
                        ),
                        Text('消費TP: $spend'),
                      ] else
                        const Padding(
                          padding: EdgeInsets.all(8),
                          child: Text('TPが足りません。移動して貯めましょう!'),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              for (final stat in StatType.values)
                Card(
                  child: ListTile(
                    title: Text(stat.label),
                    subtitle: Text(
                        '現在 ${runner.stats[stat]} / 成長傾向 ×${runner.growthRates[stat].toStringAsFixed(2)}'),
                    trailing: FilledButton(
                      onPressed: spend >= Trainer.tpPerUnit &&
                              runner.stats[stat] < Stats.maxValue
                          ? () async {
                              final before = runner.stats[stat];
                              final ok = await ref
                                  .read(gameControllerProvider.notifier)
                                  .train(stat, spend);
                              if (ok && context.mounted) {
                                final after = ref
                                        .read(gameControllerProvider)
                                        .value
                                        ?.runner
                                        ?.stats[stat] ??
                                    before;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                        '${stat.label} +${after - before}!'),
                                    duration: const Duration(seconds: 1),
                                  ),
                                );
                              }
                            }
                          : null,
                      child: const Text('鍛える'),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
