import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/game_controller.dart';

class LogScreen extends ConsumerWidget {
  const LogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final game = ref.watch(gameControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('移動記録')),
      body: game.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('エラー: $e')),
        data: (state) {
          if (state.activities.isEmpty) {
            return const Center(child: Text('まだ記録がありません'));
          }
          final items = state.activities.reversed.toList();
          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, i) {
              final a = items[i];
              final km = (a.distanceMeters / 1000).toStringAsFixed(2);
              final d = a.recordedAt;
              final date =
                  '${d.month}/${d.day} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
              return ListTile(
                leading: const Icon(Icons.directions_run),
                title: Text('$km km'),
                subtitle: Text('$date(${a.timeSlot.label})'),
                trailing: Text('+${a.earnedTp} TP'),
              );
            },
          );
        },
      ),
    );
  }
}
