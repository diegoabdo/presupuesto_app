import 'package:flutter/foundation.dart';

import '../models/budget_category.dart';
import '../models/pay_period.dart';
import '../models/savings_goal.dart';
import '../models/settings_models.dart';
import '../services/api_exception.dart';
import '../services/data_repository.dart';

/// Guarda en memoria los datos ya cargados de la API y notifica a las
/// pantallas cuando cambian, para no repetir la petición HTTP en cada tab.
class AppState extends ChangeNotifier {
  final _repo = DataRepository.instance;

  bool isLoading = false;
  String? error;
  DateTime? lastSyncedAt;

  List<PayPeriod> payPeriods = [];
  List<BudgetCategory> budgetCategories = [];
  List<SavingsGoal> savingsGoals = [];
  List<IncomeSourceTemplate> incomeSourceTemplates = [];
  List<DeductionRuleTemplate> deductionRuleTemplates = [];

  /// Gastos ya cargados por categoría, para el desglose que se ve al
  /// expandir una categoría en Presupuesto. Se piden bajo demanda (no en
  /// loadAll) porque la mayoría de las veces el usuario no los abre.
  final Map<String, List<BudgetExpense>> expensesByCategory = {};

  bool get hasData =>
      payPeriods.isNotEmpty || budgetCategories.isNotEmpty || savingsGoals.isNotEmpty;

  /// Carga todo de una vez (se llama al iniciar sesión y al hacer
  /// pull-to-refresh). Las peticiones van en paralelo.
  Future<void> loadAll() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _repo.fetchPayPeriods(),
        _repo.fetchBudgetCategories(),
        _repo.fetchSavingsGoals(),
        _repo.fetchIncomeSources(),
        _repo.fetchDeductionRules(),
      ]);
      payPeriods = results[0] as List<PayPeriod>;
      budgetCategories = results[1] as List<BudgetCategory>;
      savingsGoals = results[2] as List<SavingsGoal>;
      incomeSourceTemplates = results[3] as List<IncomeSourceTemplate>;
      deductionRuleTemplates = results[4] as List<DeductionRuleTemplate>;
      lastSyncedAt = DateTime.now();
    } on ApiException catch (e) {
      error = e.message;
    } catch (e) {
      error = 'No se pudo cargar la información. Revisa tu conexión.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshBudgetCategories() async {
    budgetCategories = await _repo.fetchBudgetCategories();
    notifyListeners();
  }

  Future<void> refreshSavingsGoals() async {
    savingsGoals = await _repo.fetchSavingsGoals();
    notifyListeners();
  }

  Future<void> refreshPayPeriods() async {
    payPeriods = await _repo.fetchPayPeriods();
    notifyListeners();
  }

  /// Registra un gasto y refresca el presupuesto para que el monto
  /// gastado/disponible quede al día de inmediato.
  Future<void> addExpense({
    required String budgetCategoryId,
    required double amount,
    String? note,
    required DateTime spentAt,
  }) async {
    await _repo.createExpense(
      budgetCategoryId: budgetCategoryId,
      amount: amount,
      note: note,
      spentAt: spentAt,
    );
    expensesByCategory.remove(budgetCategoryId);
    await refreshBudgetCategories();
  }

  /// Trae (o refresca) el desglose de gastos de una categoría. Se guarda
  /// en memoria para no volver a pedirlo cada vez que se colapsa/expande.
  Future<void> loadExpensesForCategory(String budgetCategoryId) async {
    expensesByCategory[budgetCategoryId] =
        await _repo.fetchExpenses(budgetCategoryId: budgetCategoryId);
    notifyListeners();
  }

  Future<void> deleteExpense({required String id, required String budgetCategoryId}) async {
    await _repo.deleteExpense(id);
    expensesByCategory.remove(budgetCategoryId);
    await refreshBudgetCategories();
  }

  /// Agrega un aporte a una meta y actualiza esa meta en memoria con la
  /// respuesta del backend (ya trae el saldo/porcentaje recalculado).
  Future<void> addContribution({
    required String savingsGoalId,
    required double amount,
    String? note,
    required DateTime contributedAt,
  }) async {
    final updated = await _repo.addContribution(
      savingsGoalId: savingsGoalId,
      amount: amount,
      note: note,
      contributedAt: contributedAt,
    );
    _replaceSavingsGoal(updated);
  }

  /// Crea una planilla nueva y refresca la lista completa (así queda en el
  /// orden correcto que ya decide el backend).
  Future<void> createPayPeriod({
    required DateTime periodStart,
    required DateTime periodEnd,
    required DateTime payDate,
    required String paymentMethod,
    required WorkSchedule schedule,
    required List<Map<String, dynamic>> incomes,
    required List<Map<String, dynamic>> deductions,
  }) async {
    await _repo.createPayPeriod(
      periodStart: periodStart,
      periodEnd: periodEnd,
      payDate: payDate,
      paymentMethod: paymentMethod,
      schedule: schedule,
      incomes: incomes,
      deductions: deductions,
    );
    await refreshPayPeriods();
  }

  /// Actualiza una planilla existente (período, método de pago, esquema
  /// e ingresos). Los descuentos quedan igual: ver DataRepository.updatePayPeriod.
  Future<void> updatePayPeriod({
    required String id,
    required DateTime periodStart,
    required DateTime periodEnd,
    required DateTime payDate,
    required String paymentMethod,
    required WorkSchedule schedule,
    required List<Map<String, dynamic>> incomes,
  }) async {
    await _repo.updatePayPeriod(
      id: id,
      periodStart: periodStart,
      periodEnd: periodEnd,
      payDate: payDate,
      paymentMethod: paymentMethod,
      schedule: schedule,
      incomes: incomes,
    );
    await refreshPayPeriods();
  }

  Future<void> deletePayPeriod(String id) async {
    await _repo.deletePayPeriod(id);
    payPeriods = payPeriods.where((p) => p.id != id).toList();
    notifyListeners();
  }

  Future<void> createSavingsGoal({
    required String name,
    required double targetAmount,
    DateTime? targetDate,
  }) async {
    final goal = await _repo.createSavingsGoal(
      name: name,
      targetAmount: targetAmount,
      targetDate: targetDate,
    );
    savingsGoals = [...savingsGoals, goal];
    notifyListeners();
  }

  Future<SavingsGoal> updateSavingsGoal({
    required String id,
    required String name,
    required double targetAmount,
    DateTime? targetDate,
  }) async {
    final updated = await _repo.updateSavingsGoal(
      id: id,
      name: name,
      targetAmount: targetAmount,
      targetDate: targetDate,
    );
    _replaceSavingsGoal(updated);
    return updated;
  }

  void _replaceSavingsGoal(SavingsGoal updated) {
    final index = savingsGoals.indexWhere((g) => g.id == updated.id);
    if (index != -1) {
      savingsGoals = [...savingsGoals]..[index] = updated;
    } else {
      savingsGoals = [...savingsGoals, updated];
    }
    notifyListeners();
  }

  Future<void> createIncomeSourceTemplate({
    required String label,
    required double defaultAmount,
    required bool isRecurring,
  }) async {
    final template = await _repo.createIncomeSource(
      label: label,
      defaultAmount: defaultAmount,
      isRecurring: isRecurring,
    );
    incomeSourceTemplates = [...incomeSourceTemplates, template];
    notifyListeners();
  }

  Future<void> deleteIncomeSourceTemplate(String id) async {
    await _repo.deleteIncomeSource(id);
    incomeSourceTemplates = incomeSourceTemplates.where((t) => t.id != id).toList();
    notifyListeners();
  }

  Future<void> createDeductionRuleTemplate({
    required String label,
    required double percentageHuman,
  }) async {
    final template = await _repo.createDeductionRule(
      label: label,
      percentageHuman: percentageHuman,
    );
    deductionRuleTemplates = [...deductionRuleTemplates, template];
    notifyListeners();
  }

  Future<void> deleteDeductionRuleTemplate(String id) async {
    await _repo.deleteDeductionRule(id);
    deductionRuleTemplates = deductionRuleTemplates.where((t) => t.id != id).toList();
    notifyListeners();
  }

  Future<void> createBudgetCategory({
    required String name,
    required double monthlyBudget,
  }) async {
    final category = await _repo.createBudgetCategory(name: name, monthlyBudget: monthlyBudget);
    budgetCategories = [...budgetCategories, category];
    notifyListeners();
  }

  Future<void> updateBudgetCategory({
    required String id,
    required String name,
    required double monthlyBudget,
  }) async {
    final updated = await _repo.updateBudgetCategory(id: id, name: name, monthlyBudget: monthlyBudget);
    final index = budgetCategories.indexWhere((c) => c.id == id);
    if (index != -1) {
      budgetCategories = [...budgetCategories]..[index] = updated;
    } else {
      budgetCategories = [...budgetCategories, updated];
    }
    notifyListeners();
  }

  Future<void> deleteBudgetCategory(String id) async {
    await _repo.deleteBudgetCategory(id);
    budgetCategories = budgetCategories.where((c) => c.id != id).toList();
    notifyListeners();
  }

  /// Limpia todo al cerrar sesión, para que el próximo usuario que inicie
  /// sesión en este dispositivo no vea datos del anterior.
  void reset() {
    payPeriods = [];
    budgetCategories = [];
    savingsGoals = [];
    incomeSourceTemplates = [];
    deductionRuleTemplates = [];
    expensesByCategory.clear();
    error = null;
    isLoading = false;
    lastSyncedAt = null;
    notifyListeners();
  }
}
