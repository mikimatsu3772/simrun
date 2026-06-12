/// ランナーの5ステータス。
enum StatType {
  speed('スピード'),
  stamina('スタミナ'),
  power('パワー'),
  guts('根性'),
  wisdom('賢さ');

  const StatType(this.label);
  final String label;
}

/// ステータス値のセット。0〜1200 を想定(初期値は素質で決まる)。
class Stats {
  const Stats({
    this.speed = 0,
    this.stamina = 0,
    this.power = 0,
    this.guts = 0,
    this.wisdom = 0,
  });

  final int speed;
  final int stamina;
  final int power;
  final int guts;
  final int wisdom;

  static const int maxValue = 1200;

  int operator [](StatType type) => switch (type) {
        StatType.speed => speed,
        StatType.stamina => stamina,
        StatType.power => power,
        StatType.guts => guts,
        StatType.wisdom => wisdom,
      };

  Stats add(StatType type, int amount) {
    int clamp(int v) => v.clamp(0, maxValue);
    return Stats(
      speed: type == StatType.speed ? clamp(speed + amount) : speed,
      stamina: type == StatType.stamina ? clamp(stamina + amount) : stamina,
      power: type == StatType.power ? clamp(power + amount) : power,
      guts: type == StatType.guts ? clamp(guts + amount) : guts,
      wisdom: type == StatType.wisdom ? clamp(wisdom + amount) : wisdom,
    );
  }

  int get total => speed + stamina + power + guts + wisdom;

  Map<String, dynamic> toJson() => {
        'speed': speed,
        'stamina': stamina,
        'power': power,
        'guts': guts,
        'wisdom': wisdom,
      };

  factory Stats.fromJson(Map<String, dynamic> json) => Stats(
        speed: json['speed'] as int? ?? 0,
        stamina: json['stamina'] as int? ?? 0,
        power: json['power'] as int? ?? 0,
        guts: json['guts'] as int? ?? 0,
        wisdom: json['wisdom'] as int? ?? 0,
      );
}

/// 成長傾向。各ステータスの成長係数(0.8〜1.4 程度)。
class GrowthRates {
  const GrowthRates({
    this.speed = 1.0,
    this.stamina = 1.0,
    this.power = 1.0,
    this.guts = 1.0,
    this.wisdom = 1.0,
  });

  final double speed;
  final double stamina;
  final double power;
  final double guts;
  final double wisdom;

  double operator [](StatType type) => switch (type) {
        StatType.speed => speed,
        StatType.stamina => stamina,
        StatType.power => power,
        StatType.guts => guts,
        StatType.wisdom => wisdom,
      };

  Map<String, dynamic> toJson() => {
        'speed': speed,
        'stamina': stamina,
        'power': power,
        'guts': guts,
        'wisdom': wisdom,
      };

  factory GrowthRates.fromJson(Map<String, dynamic> json) => GrowthRates(
        speed: (json['speed'] as num?)?.toDouble() ?? 1.0,
        stamina: (json['stamina'] as num?)?.toDouble() ?? 1.0,
        power: (json['power'] as num?)?.toDouble() ?? 1.0,
        guts: (json['guts'] as num?)?.toDouble() ?? 1.0,
        wisdom: (json['wisdom'] as num?)?.toDouble() ?? 1.0,
      );
}
