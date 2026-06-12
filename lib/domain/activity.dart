/// 移動の時間帯区分。成長フレーバーの源泉。
enum TimeSlot {
  morning('朝', '集中ボーナス +10%'),
  daytime('昼', ''),
  night('夜', '');

  const TimeSlot(this.label, this.bonusNote);
  final String label;
  final String bonusNote;

  static TimeSlot fromHour(int hour) {
    if (hour >= 4 && hour < 10) return TimeSlot.morning;
    if (hour >= 10 && hour < 18) return TimeSlot.daytime;
    return TimeSlot.night;
  }
}

/// 1回分の移動記録。距離はメートル。
class ActivityRecord {
  const ActivityRecord({
    required this.recordedAt,
    required this.distanceMeters,
    required this.timeSlot,
    required this.earnedTp,
  });

  final DateTime recordedAt;
  final int distanceMeters;
  final TimeSlot timeSlot;
  final int earnedTp;

  Map<String, dynamic> toJson() => {
        'recordedAt': recordedAt.toIso8601String(),
        'distanceMeters': distanceMeters,
        'timeSlot': timeSlot.name,
        'earnedTp': earnedTp,
      };

  factory ActivityRecord.fromJson(Map<String, dynamic> json) => ActivityRecord(
        recordedAt: DateTime.parse(json['recordedAt'] as String),
        distanceMeters: json['distanceMeters'] as int,
        timeSlot: TimeSlot.values.byName(json['timeSlot'] as String),
        earnedTp: json['earnedTp'] as int,
      );
}

/// 距離 → TP 変換。1km = 10TP、朝は +10%。
class TpConverter {
  static const int tpPerKm = 10;
  static const double morningBonus = 1.1;

  static int convert(int distanceMeters, TimeSlot slot) {
    final base = distanceMeters / 1000 * tpPerKm;
    final bonus = slot == TimeSlot.morning ? morningBonus : 1.0;
    return (base * bonus).floor();
  }
}
