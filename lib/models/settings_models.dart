import '../utils/json_helpers.dart';

/// Plantilla de fuente de ingreso configurada en Ajustes (tabla
/// income_sources). Distinta de IncomeSource: esa es la línea ya registrada
/// dentro de una planilla específica; esto es solo el catálogo reutilizable
/// ("Salario base", "Bono 14", etc.) que ayuda a llenar una planilla nueva
/// más rápido.
class IncomeSourceTemplate {
  final String id;
  final String label;
  final double defaultAmount;
  final bool isRecurring;

  const IncomeSourceTemplate({
    required this.id,
    required this.label,
    required this.defaultAmount,
    required this.isRecurring,
  });

  factory IncomeSourceTemplate.fromJson(Map<String, dynamic> json) {
    return IncomeSourceTemplate(
      id: json['id'].toString(),
      label: json['label'] as String,
      defaultAmount: jsonToDouble(json['default_amount']),
      isRecurring: json['is_recurring'] as bool? ?? true,
    );
  }
}

/// Regla de descuento configurada en Ajustes (tabla deduction_rules), ej.
/// "Cuota IGSS". El porcentaje aquí viene como fracción (0.0483), tal como
/// lo guarda y lo devuelve el backend — pero la API espera el valor humano
/// (4.83) al CREAR una regla nueva; ver DataRepository.createDeductionRule.
class DeductionRuleTemplate {
  final String id;
  final String label;
  final double percentage;

  const DeductionRuleTemplate({
    required this.id,
    required this.label,
    required this.percentage,
  });

  factory DeductionRuleTemplate.fromJson(Map<String, dynamic> json) {
    return DeductionRuleTemplate(
      id: json['id'].toString(),
      label: json['label'] as String,
      percentage: jsonToDouble(json['percentage']),
    );
  }
}
