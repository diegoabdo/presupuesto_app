import '../models/budget_category.dart';
import '../models/deduction.dart';
import '../models/income_source.dart';
import '../models/pay_period.dart';
import '../models/savings_goal.dart';

/// Datos de ejemplo (no vienen de ningún backend todavía).
/// Sirven para poder ver y ajustar las pantallas mientras se construye
/// la API en Laravel. Los montos son ilustrativos, no tus datos reales.
class MockData {
  MockData._();

  static const _igssPercentage = 0.0483;

  static final List<PayPeriod> payPeriods = [
    PayPeriod(
      id: 'pp-2026-07',
      periodStart: DateTime(2026, 7, 1),
      periodEnd: DateTime(2026, 7, 31),
      payDate: DateTime(2026, 8, 5),
      paymentMethod: 'Transferencia',
      schedule: WorkSchedule.tiempoCompleto,
      incomeSources: const [
        IncomeSource(id: 'base', label: 'Salario base', amount: 5750),
        IncomeSource(id: 'bono14', label: 'Bono 14', amount: 5750, isRecurring: false),
      ],
      deductions: const [
        DeductionRule(
          id: 'igss',
          label: 'Cuota IGSS',
          percentage: _igssPercentage,
          baseAmount: 5750,
        ),
      ],
    ),
    PayPeriod(
      id: 'pp-2026-08',
      periodStart: DateTime(2026, 8, 1),
      periodEnd: DateTime(2026, 8, 31),
      payDate: DateTime(2026, 9, 5),
      paymentMethod: 'Transferencia',
      schedule: WorkSchedule.medioTiempo,
      incomeSources: const [
        IncomeSource(id: 'base', label: 'Salario base', amount: 2875),
        IncomeSource(id: 'bono-inc', label: 'Bonificación incentivo', amount: 250),
      ],
      deductions: const [
        DeductionRule(
          id: 'igss',
          label: 'Cuota IGSS',
          percentage: _igssPercentage,
          baseAmount: 2875,
        ),
      ],
    ),
    PayPeriod(
      id: 'pp-2026-09',
      periodStart: DateTime(2026, 9, 1),
      periodEnd: DateTime(2026, 9, 30),
      payDate: DateTime(2026, 10, 5),
      paymentMethod: 'Transferencia',
      schedule: WorkSchedule.medioTiempo,
      incomeSources: const [
        IncomeSource(id: 'base', label: 'Salario base', amount: 2875),
        IncomeSource(id: 'bono-inc', label: 'Bonificación incentivo', amount: 250),
        IncomeSource(id: 'parking', label: 'Parking bonus', amount: 200, isRecurring: false),
      ],
      deductions: const [
        DeductionRule(
          id: 'igss',
          label: 'Cuota IGSS',
          percentage: _igssPercentage,
          baseAmount: 2875,
        ),
      ],
    ),
  ];

  static final PayPeriod nextPayPeriod = PayPeriod(
    id: 'pp-2026-10',
    periodStart: DateTime(2026, 10, 1),
    periodEnd: DateTime(2026, 10, 31),
    payDate: DateTime(2026, 11, 5),
    paymentMethod: 'Transferencia',
    schedule: WorkSchedule.tiempoCompleto,
    incomeSources: const [
      IncomeSource(id: 'base', label: 'Salario base', amount: 5750),
      IncomeSource(id: 'bono-inc', label: 'Bonificación incentivo', amount: 250),
    ],
    deductions: const [
      DeductionRule(
        id: 'igss',
        label: 'Cuota IGSS',
        percentage: _igssPercentage,
        baseAmount: 5750,
      ),
    ],
  );

  static const List<BudgetCategory> budgetCategories = [
    BudgetCategory(id: 'renta', name: 'Renta', budgeted: 1500, spent: 1500),
    BudgetCategory(id: 'comida', name: 'Comida', budgeted: 900, spent: 745.50),
    BudgetCategory(id: 'transporte', name: 'Transporte', budgeted: 400, spent: 380),
    BudgetCategory(id: 'salidas', name: 'Salidas y ocio', budgeted: 350, spent: 410),
    BudgetCategory(id: 'servicios', name: 'Servicios', budgeted: 300, spent: 275),
  ];

  static final List<SavingsGoal> savingsGoals = [
    SavingsGoal(
      id: 'enganche-casa',
      name: 'Enganche de casa',
      targetAmount: 120000,
      targetDate: DateTime(2028, 3, 1),
      contributions: [
        SavingsContribution(id: 'c1', date: DateTime(2026, 6, 5), amount: 1200),
        SavingsContribution(id: 'c2', date: DateTime(2026, 7, 10), amount: 1800),
        SavingsContribution(id: 'c3', date: DateTime(2026, 8, 5), amount: 1200),
        SavingsContribution(id: 'c4', date: DateTime(2026, 9, 5), amount: 1200),
      ],
    ),
    SavingsGoal(
      id: 'fondo-emergencia',
      name: 'Fondo de emergencia',
      targetAmount: 15000,
      targetDate: null,
      contributions: [
        SavingsContribution(id: 'e1', date: DateTime(2026, 7, 20), amount: 1500),
        SavingsContribution(id: 'e2', date: DateTime(2026, 8, 15), amount: 1000),
        SavingsContribution(id: 'e3', date: DateTime(2026, 9, 10), amount: 700),
      ],
    ),
  ];
}
