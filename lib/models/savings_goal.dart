import '../utils/json_helpers.dart';

/// Un aporte individual hacia una meta de ahorro.
class SavingsContribution {
  final String id;
  final DateTime date;
  final double amount;
  final String? note;

  const SavingsContribution({
    required this.id,
    required this.date,
    required this.amount,
    this.note,
  });

  factory SavingsContribution.fromJson(Map<String, dynamic> json) {
    return SavingsContribution(
      id: json['id'].toString(),
      date: DateTime.parse(json['contributed_at'] as String),
      amount: jsonToDouble(json['amount']),
      note: json['note'] as String?,
    );
  }
}

/// Una meta de ahorro (ej. el enganche de una casa), calculada a partir
/// de la suma de sus aportes en vez de guardar un total aparte.
class SavingsGoal {
  final String id;
  final String name;
  final double targetAmount;
  final DateTime? targetDate;
  final List<SavingsContribution> contributions;

  const SavingsGoal({
    required this.id,
    required this.name,
    required this.targetAmount,
    this.targetDate,
    required this.contributions,
  });

  double get currentAmount =>
      contributions.fold(0.0, (sum, c) => sum + c.amount);

  double get remaining => (targetAmount - currentAmount).clamp(0, double.infinity);

  double get progress =>
      targetAmount <= 0 ? 0 : (currentAmount / targetAmount).clamp(0, 1);

  /// Construye la meta a partir del JSON de SavingsGoalResource
  /// (incluye "contributions" solo cuando el backend las cargó).
  factory SavingsGoal.fromJson(Map<String, dynamic> json) {
    return SavingsGoal(
      id: json['id'].toString(),
      name: json['name'] as String,
      targetAmount: jsonToDouble(json['target_amount']),
      targetDate: json['target_date'] != null
          ? DateTime.parse(json['target_date'] as String)
          : null,
      contributions: (json['contributions'] as List<dynamic>? ?? [])
          .map((e) => SavingsContribution.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
