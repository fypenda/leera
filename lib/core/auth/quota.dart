/// How many corrections the account may still ask for.
enum Plan { free, plus }

class Quota {
  const Quota({
    required this.plan,
    required this.used,
    required this.limit,
    required this.resetsAt,
  });

  final Plan plan;
  final int used;
  final int limit;

  /// When [used] goes back to zero.
  final DateTime resetsAt;

  int get remaining => used >= limit ? 0 : limit - used;

  /// Reads the backend's `quota` object; throws [FormatException] otherwise.
  factory Quota.fromJson(Object? json) {
    if (json is! Map) throw const FormatException('The quota is missing.');
    final plan = switch (json['plan']) {
      'plus' => Plan.plus,
      'free' => Plan.free,
      _ => throw const FormatException('Unknown plan.'),
    };
    final used = json['used'];
    final limit = json['limit'];
    final resetsAt = DateTime.tryParse('${json['resetsAt']}');
    if (used is! int || limit is! int || resetsAt == null) {
      throw const FormatException('The quota is incomplete.');
    }
    return Quota(plan: plan, used: used, limit: limit, resetsAt: resetsAt);
  }
}

/// The quota in one short line: "1 correction left this week".
String describeQuota(Quota quota) {
  final period = quota.plan == Plan.plus ? 'today' : 'this week';
  return switch (quota.remaining) {
    0 => 'No corrections left $period',
    1 => '1 correction left $period',
    final n => '$n corrections left $period',
  };
}
