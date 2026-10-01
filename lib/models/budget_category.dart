import '../utils/json_helpers.dart';

/// Una categoría del presupuesto mensual (renta, comida, transporte, etc.)
/// con lo presupuestado y lo gastado hasta ahora.
///
/// [budgeted] es null cuando la categoría no tiene límite (ej. "Sin
/// categoría" para gastos sueltos). [isRecurring] en false marca una
/// categoría de un solo mes (ej. "Viaje a Xela"): el backend deja de
/// listarla a partir del mes siguiente a cuando se creó.
class BudgetCategory {
  final String id;
  final String name;
  final double? budgeted;
  final double spent;
  final bool isRecurring;

  const BudgetCategory({
    required this.id,
    required this.name,
    required this.budgeted,
    required this.spent,
    this.isRecurring = true,
  });

  bool get hasLimit => budgeted != null;

  double? get remaining => budgeted != null ? budgeted! - spent : null;

  double get progress {
    final budgeted = this.budgeted;
    if (budgeted == null || budgeted <= 0) return 0;
    return (spent / budgeted).clamp(0, 1.5);
  }

  bool get isOverBudget => budgeted != null && spent > budgeted!;

  /// Construye la categoría a partir del JSON de BudgetCategoryResource.
  factory BudgetCategory.fromJson(Map<String, dynamic> json) {
    return BudgetCategory(
      id: json['id'].toString(),
      name: json['name'] as String,
      budgeted: jsonToDoubleOrNull(json['monthly_budget']),
      spent: jsonToDouble(json['spent_this_month']),
      isRecurring: json['is_recurring'] as bool? ?? true,
    );
  }
}
