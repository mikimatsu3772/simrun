import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/game_controller.dart';
import '../data/distance_source.dart';

/// 開発用パネル。距離の手動注入と日付送りができる。
/// リリースビルドでは出さない。
void showDebugPanel(BuildContext context, WidgetRef ref) {
  if (kReleaseMode) return;

  showModalBottomSheet<void>(
    context: context,
    builder: (context) {
      final source = ref.read(distanceSourceProvider);
      final mock = source is MockDistanceSource ? source : null;

      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('デバッグパネル',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              if (mock != null) ...[
                const Text('距離を注入:'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final meters in [500, 1000, 3000, 5000, 10000])
                      ActionChip(
                        label: Text(meters >= 1000 ? '${meters ~/ 1000}km' : '${meters}m'),
                        onPressed: () {
                          mock.inject(meters);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('$meters m 注入'),
                              duration: const Duration(milliseconds: 600),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ] else
                const Text('実機の距離ソースを使用中(注入不可)'),
              const Divider(height: 24),
              const Text('時計を進める:'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  for (final (label, d) in [
                    ('+1日', Duration(days: 1)),
                    ('+7日', Duration(days: 7)),
                    ('+14日', Duration(days: 14)),
                  ])
                    ActionChip(
                      label: Text(label),
                      onPressed: () {
                        ref
                            .read(gameControllerProvider.notifier)
                            .advanceClock(d);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('時計を$labelしました'),
                            duration: const Duration(milliseconds: 600),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}
