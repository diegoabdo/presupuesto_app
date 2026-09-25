import '../utils/json_helpers.dart';

/// Regla de descuento aplicada sobre una base (normalmente el salario base).
/// Ej: Cuota IGSS del 4.83%.
class DeductionRule {
  final String id;
  final String label;
  final double percentage; // ej. 0.0483
  final double baseAmount;

  const DeductionRule({
    required this.id,
    required this.label,
    required this.percentage,
    required this.baseAmount,
  });

  double get amount => baseAmount * percentage;

  /// La API devuelve el descuento ya aplicado dentro de una planilla
  /// (tabla pay_period_deductions): {id, label, percentage, base_amount, amount}.
  factory DeductionRule.fromJson(Map<String, dynamic> json) {
    return DeductionRule(
      id: json['id'].toString(),
      label: json['label'] as String,
      percentage: jsonToDouble(json['percentage']),
      baseAmount: json['base_amount'] != null ? jsonToDouble(json['base_amount']) : 0,
    );
  }
}
