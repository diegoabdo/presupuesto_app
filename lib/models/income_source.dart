import '../utils/json_helpers.dart';

/// Representa una línea de ingreso dentro de una planilla:
/// salario base, un bono recurrente, un bono puntual, etc.
class IncomeSource {
  final String id;
  final String label;
  final double amount;
  final bool isRecurring;

  const IncomeSource({
    required this.id,
    required this.label,
    required this.amount,
    this.isRecurring = true,
  });

  /// La API devuelve estas líneas ya resueltas dentro de una planilla
  /// (tabla pay_period_incomes): {id, label, amount}. No trae is_recurring
  /// porque eso es una propiedad de la plantilla, no del monto ya registrado.
  factory IncomeSource.fromJson(Map<String, dynamic> json) {
    return IncomeSource(
      id: json['id'].toString(),
      label: json['label'] as String,
      amount: jsonToDouble(json['amount']),
      isRecurring: json['is_recurring'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'label': label,
        'amount': amount,
      };
}
