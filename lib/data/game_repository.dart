import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/game_state.dart';

/// ゲーム状態の永続化。
/// Phase 1 は JSON + SharedPreferences。データ量が増えたら drift に差し替える。
abstract class GameRepository {
  Future<GameState> load();
  Future<void> save(GameState state);
}

class PrefsGameRepository implements GameRepository {
  static const _key = 'simrun.gameState.v1';

  @override
  Future<GameState> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return GameState.empty;
    try {
      return GameState.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } on FormatException {
      return GameState.empty;
    }
  }

  @override
  Future<void> save(GameState state) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(state.toJson()));
  }
}

/// テスト用インメモリ実装。
class InMemoryGameRepository implements GameRepository {
  GameState _state = GameState.empty;

  @override
  Future<GameState> load() async => _state;

  @override
  Future<void> save(GameState state) async => _state = state;
}
