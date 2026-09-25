import '../utils/json_helpers.dart';

/// Una categoría del presupuesto mensual (renta, comida, transporte, etc.)
/// con lo presupuestado y lo gastado hasta ahora.
class BudgetCategory {
  final String id;
  final String name;
  final double budgeted;
  final double spent;

  const BudgetCategory({
    required this.id,
    required this.name,
    required this.budgeted,
    required this.spent,
  });

  double get remaining => budgeted - spent;

  double get progress => budgeted <= 0 ? 0 : (spent / budgeted).clamp(0, 1.5);

  bool get isOverBudget => spent > budgeted;

  /// Construye la categoría a partir del JSON de BudgetCategoryResource.
  factory BudgetCategory.fromJson(Map<String, dynamic> json) {
    return BudgetCategory(
      id: json['id'].toString(),
      name: json['name'] as String,
      budgeted: jsonToDouble(json['monthly_budget']),
      spent: jsonToDouble(json['spent_this_month']),
    );
  }
}
