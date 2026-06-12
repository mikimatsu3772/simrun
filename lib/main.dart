import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'ui/home_screen.dart';
import 'ui/pixel/gb_palette.dart';

void main() {
  runApp(const ProviderScope(child: SimrunApp()));
}

class SimrunApp extends StatelessWidget {
  const SimrunApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SIMRUN',
      theme: gbTheme(),
      home: const HomeScreen(),
    );
  }
}
