import '../models/budget_category.dart';
import '../models/pay_period.dart';
import '../models/savings_goal.dart';
import '../models/settings_models.dart';
import '../utils/json_helpers.dart';
import 'api_client.dart';

/// Un gasto individual (tabla budget_expenses). El backend no lo agrupa
/// en un Resource propio, así que lo modelamos aquí mismo.
class BudgetExpense {
  final String id;
  final String budgetCategoryId;
  final String? categoryName;
  final double amount;
  final String? note;
  final DateTime spentAt;

  const BudgetExpense({
    required this.id,
    required this.budgetCategoryId,
    required this.amount,
    required this.spentAt,
    this.categoryName,
    this.note,
  });

  factory BudgetExpense.fromJson(Map<String, dynamic> json) => BudgetExpense(
        id: json['id'].toString(),
        budgetCategoryId: json['budget_category_id'].toString(),
        categoryName: (json['category'] as Map<String, dynamic>?)?['name'] as String?,
        amount: jsonToDouble(json['amount']),
        note: json['note'] as String?,
        spentAt: DateTime.parse(json['spent_at'] as String),
      );
}

/// Punto único para leer y escribir los datos reales del backend.
/// Las pantallas no llaman a ApiClient directamente: pasan por aquí.
class DataRepository {
  DataRepository._();
  static final DataRepository instance = DataRepository._();

  final _client = ApiClient.instance;

  /// Laravel envuelve las colecciones de un API Resource en {"data": [...]},
  /// pero un índice que devuelve el modelo "a pelo" (sin Resource) llega
  /// como arreglo plano. Esto acepta ambas formas.
  List<dynamic> _asList(dynamic json) {
    if (json is List) return json;
    if (json is Map && json['data'] is List) return json['data'] as List<dynamic>;
    return const [];
  }

  String _dateOnly(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  // ---- Planillas (pay periods) ----

  Future<List<PayPeriod>> fetchPayPeriods() {
    return _client.get('/pay-periods', (json) {
      return _asList(json).map((e) => PayPeriod.fromJson(e as Map<String, dynamic>)).toList();
    });
  }

  Future<PayPeriod> createPayPeriod({
    required DateTime periodStart,
    required DateTime periodEnd,
    required DateTime payDate,
    required String paymentMethod,
    required WorkSchedule schedule,
    required List<Map<String, dynamic>> incomes,
    required List<Map<String, dynamic>> deductions,
  }) {
    return _client.post(
      '/pay-periods',
      {
        'period_start': _dateOnly(periodStart),
        'period_end': _dateOnly(periodEnd),
        'pay_date': _dateOnly(payDate),
        'payment_method': paymentMethod,
        'work_schedule': schedule.apiValue,
        'incomes': incomes,
        'deductions': deductions,
      },
      (json) => PayPeriod.fromJson(json as Map<String, dynamic>),
    );
  }

  /// Actualiza los datos del período y reemplaza sus ingresos. Los
  /// descuentos no se envían: el backend los deja fijos desde que se creó
  /// la planilla (ver PayPeriodController::update).
  Future<PayPeriod> updatePayPeriod({
    required String id,
    required DateTime periodStart,
    required DateTime periodEnd,
    required DateTime payDate,
    required String paymentMethod,
    required WorkSchedule schedule,
    required List<Map<String, dynamic>> incomes,
  }) {
    return _client.put(
      '/pay-periods/$id',
      {
        'period_start': _dateOnly(periodStart),
        'period_end': _dateOnly(periodEnd),
        'pay_date': _dateOnly(payDate),
        'payment_method': paymentMethod,
        'work_schedule': schedule.apiValue,
        'incomes': incomes,
      },
      (json) => PayPeriod.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<void> deletePayPeriod(String id) => _client.delete('/pay-periods/$id');

  // ---- Fuentes de ingreso (plantillas) ----

  Future<List<IncomeSourceTemplate>> fetchIncomeSources() {
    return _client.get('/income-sources', (json) {
      return _asList(json).map((e) => IncomeSourceTemplate.fromJson(e as Map<String, dynamic>)).toList();
    });
  }

  Future<IncomeSourceTemplate> createIncomeSource({
    required String label,
    required double defaultAmount,
    required bool isRecurring,
  }) {
    return _client.post(
      '/income-sources',
      {
        'label': label,
        'default_amount': defaultAmount,
        'is_recurring': isRecurring,
      },
      (json) => IncomeSourceTemplate.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<void> deleteIncomeSource(String id) => _client.delete('/income-sources/$id');

  // ---- Reglas de descuento (plantillas) ----

  Future<List<DeductionRuleTemplate>> fetchDeductionRules() {
    return _client.get('/deduction-rules', (json) {
      return _asList(json).map((e) => DeductionRuleTemplate.fromJson(e as Map<String, dynamic>)).toList();
    });
  }

  /// [percentageHuman] va en formato humano (ej. 4.83 para 4.83%), igual
  /// que en el formulario — la API lo convierte a fracción internamente.
  Future<DeductionRuleTemplate> createDeductionRule({
    required String label,
    required double percentageHuman,
  }) {
    return _client.post(
      '/deduction-rules',
      {
        'label': label,
        'percentage': percentageHuman,
      },
      (json) => DeductionRuleTemplate.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<void> deleteDeductionRule(String id) => _client.delete('/deduction-rules/$id');

  // ---- Categorías de presupuesto ----

  Future<BudgetCategory> createBudgetCategory({
    required String name,
    required double? monthlyBudget,
    bool isRecurring = true,
  }) {
    return _client.post(
      '/budget-categories',
      {'name': name, 'monthly_budget': monthlyBudget, 'is_recurring': isRecurring},
      (json) => BudgetCategory.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<BudgetCategory> updateBudgetCategory({
    required String id,
    required String name,
    required double? monthlyBudget,
    bool isRecurring = true,
  }) {
    return _client.put(
      '/budget-categories/$id',
      {'name': name, 'monthly_budget': monthlyBudget, 'is_recurring': isRecurring},
      (json) => BudgetCategory.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<void> deleteBudgetCategory(String id) => _client.delete('/budget-categories/$id');

  // ---- Presupuesto ----

  Future<List<BudgetCategory>> fetchBudgetCategories() {
    return _client.get('/budget-categories', (json) {
      return _asList(json).map((e) => BudgetCategory.fromJson(e as Map<String, dynamic>)).toList();
    });
  }

  Future<BudgetExpense> createExpense({
    required String budgetCategoryId,
    required double amount,
    String? note,
    required DateTime spentAt,
  }) {
    return _client.post(
      '/budget-expenses',
      {
        'budget_category_id': int.parse(budgetCategoryId),
        'amount': amount,
        if (note != null && note.isNotEmpty) 'note': note,
        'spent_at': _dateOnly(spentAt),
      },
      (json) => BudgetExpense.fromJson(json as Map<String, dynamic>),
    );
  }

  /// Historial de gastos, opcionalmente filtrado por categoría (para el
  /// desglose que se ve al expandir una categoría en Presupuesto).
  Future<List<BudgetExpense>> fetchExpenses({String? budgetCategoryId}) {
    final query = budgetCategoryId != null ? '?budget_category_id=$budgetCategoryId' : '';
    return _client.get('/budget-expenses$query', (json) {
      return _asList(json).map((e) => BudgetExpense.fromJson(e as Map<String, dynamic>)).toList();
    });
  }

  Future<void> deleteExpense(String id) => _client.delete('/budget-expenses/$id');

  // ---- Ahorro ----

  Future<List<SavingsGoal>> fetchSavingsGoals() {
    return _client.get('/savings-goals', (json) {
      return _asList(json).map((e) => SavingsGoal.fromJson(e as Map<String, dynamic>)).toList();
    });
  }

  Future<SavingsGoal> createSavingsGoal({
    required String name,
    required double targetAmount,
    DateTime? targetDate,
  }) {
    return _client.post(
      '/savings-goals',
      {
        'name': name,
        'target_amount': targetAmount,
        if (targetDate != null) 'target_date': _dateOnly(targetDate),
      },
      (json) => SavingsGoal.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<SavingsGoal> updateSavingsGoal({
    required String id,
    required String name,
    required double targetAmount,
    DateTime? targetDate,
  }) {
    return _client.put(
      '/savings-goals/$id',
      {
        'name': name,
        'target_amount': targetAmount,
        'target_date': targetDate != null ? _dateOnly(targetDate) : null,
      },
      (json) => SavingsGoal.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<void> deleteSavingsGoal(String id) => _client.delete('/savings-goals/$id');

  Future<SavingsGoal> addContribution({
    required String savingsGoalId,
    required double amount,
    String? note,
    required DateTime contributedAt,
  }) {
    return _client.post(
      '/savings-goals/$savingsGoalId/contributions',
      {
        'amount': amount,
        if (note != null && note.isNotEmpty) 'note': note,
        'contributed_at': _dateOnly(contributedAt),
      },
      (json) => SavingsGoal.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<SavingsGoal> updateContribution({
    required String savingsGoalId,
    required String contributionId,
    required double amount,
    String? note,
    required DateTime contributedAt,
  }) {
    return _client.put(
      '/savings-goals/$savingsGoalId/contributions/$contributionId',
      {
        'amount': amount,
        if (note != null && note.isNotEmpty) 'note': note,
        'contributed_at': _dateOnly(contributedAt),
      },
      (json) => SavingsGoal.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<SavingsGoal> deleteContribution({
    required String savingsGoalId,
    required String contributionId,
  }) {
    return _client.deleteWithResult(
      '/savings-goals/$savingsGoalId/contributions/$contributionId',
      (json) => SavingsGoal.fromJson(json as Map<String, dynamic>),
    );
  }
}
