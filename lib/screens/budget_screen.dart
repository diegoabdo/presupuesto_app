import 'package:flutter/material.dart';

import '../models/budget_category.dart';
import '../services/data_repository.dart';
import '../state/app_state.dart';
import '../state/app_state_scope.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/animated_progress_bar.dart';
import 'add_expense_screen.dart';
import 'budget_categories_screen.dart';

class BudgetScreen extends StatelessWidget {
  const BudgetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appState = AppStateScope.of(context);

    if (appState.isLoading && appState.budgetCategories.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final categories = appState.budgetCategories;
    final totalSpent = categories.fold(0.0, (s, c) => s + c.spent);

    // "Disponible real" es el efectivo que de verdad te queda: lo que
    // entró este mes (de tus planillas) menos todo lo gastado, sin
    // importar cómo lo repartiste por categoría.
    final now = DateTime.now();
    final monthIncome = appState.payPeriods
        .where((p) => p.payDate.year == now.year && p.payDate.month == now.month)
        .fold(0.0, (s, p) => s + p.netPay);
    final realAvailable = monthIncome - totalSpent;

    return SafeArea(
      child: DefaultTabController(
        length: 3,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          floatingActionButton: FloatingActionButton(
            heroTag: 'budget_add_expense',
            backgroundColor: AppColors.ink,
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AddExpenseScreen()),
              );
            },
            child: const Icon(Icons.add),
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Presupuesto', style: theme.textTheme.headlineMedium),
                        IconButton(
                          icon: Icon(Icons.tune, color: AppColors.ink),
                          tooltip: 'Editar categorías',
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const BudgetCategoriesScreen()),
                            );
                          },
                        ),
                      ],
                    ),
                    Text('Este mes', style: theme.textTheme.bodyMedium),
                    const SizedBox(height: 20),
                    // El número que de verdad importa: cuánto efectivo te
                    // queda en la mano. Va primero y más grande que todo.
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.ink,
                        borderRadius: BorderRadius.circular(AppRadii.card),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Disponible real',
                            style: theme.textTheme.bodyMedium
                                ?.copyWith(color: theme.colorScheme.onPrimary.withValues(alpha: 0.7)),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            AppFormatters.currency(realAvailable),
                            style:
                                theme.textTheme.displayMedium?.copyWith(color: theme.colorScheme.onPrimary),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Lo que entró este mes (${AppFormatters.currency(monthIncome)}) menos '
                            'lo gastado (${AppFormatters.currency(totalSpent)})',
                            style: theme.textTheme.bodySmall
                                ?.copyWith(color: theme.colorScheme.onPrimary.withValues(alpha: 0.7)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    TabBar(
                      labelColor: AppColors.ink,
                      unselectedLabelColor: AppColors.slate,
                      indicatorColor: AppColors.ink,
                      indicatorSize: TabBarIndicatorSize.label,
                      labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                      unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      tabAlignment: TabAlignment.start,
                      isScrollable: true,
                      tabs: const [
                        Tab(text: 'Presupuesto'),
                        Tab(text: 'Gastos'),
                        Tab(text: 'Por categoría'),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: TabBarView(
                  children: [
                    _BudgetPlanTab(categories: categories),
                    const _ExpensesTab(),
                    _ByCategoryTab(categories: categories),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Pestaña "Presupuesto": solo el plan — nombre de cada categoría y cuánto
/// le asignaste, sin mezclarlo con lo gastado (eso vive en las otras dos
/// pestañas).
class _BudgetPlanTab extends StatelessWidget {
  final List<BudgetCategory> categories;
  const _BudgetPlanTab({required this.categories});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appState = AppStateScope.of(context);

    return RefreshIndicator(
      onRefresh: appState.refreshBudgetCategories,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
        children: [
          if (categories.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(
                'Todavía no tienes categorías de presupuesto.',
                style: theme.textTheme.bodyMedium,
              ),
            )
          else
            for (int i = 0; i < categories.length; i++) ...[
              if (i > 0) const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              categories[i].name,
                              style: theme.textTheme.bodyLarge,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (!categories[i].isRecurring) ...[
                            const SizedBox(width: 6),
                            Text(
                              '· solo este mes',
                              style: theme.textTheme.bodySmall?.copyWith(color: AppColors.slate),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Text(
                      categories[i].hasLimit
                          ? AppFormatters.currency(categories[i].budgeted!)
                          : 'Sin límite',
                      style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          const SizedBox(height: 20),
          Center(
            child: TextButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const BudgetCategoriesScreen()),
              ),
              icon: const Icon(Icons.tune, size: 18),
              label: const Text('Agregar o editar categorías'),
            ),
          ),
        ],
      ),
    );
  }
}

/// Pestaña "Gastos": totales del mes (planilla vs. gastado) y el historial
/// completo de gastos, sin agrupar por categoría.
class _ExpensesTab extends StatefulWidget {
  const _ExpensesTab();

  @override
  State<_ExpensesTab> createState() => _ExpensesTabState();
}

class _ExpensesTabState extends State<_ExpensesTab> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  bool _requested = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_requested) {
      _requested = true;
      final appState = AppStateScope.of(context);
      if (appState.allExpenses == null) {
        appState.loadAllExpenses();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    final appState = AppStateScope.of(context);
    final expenses = appState.allExpenses;

    final now = DateTime.now();
    final totalSpent = appState.budgetCategories.fold(0.0, (s, c) => s + c.spent);
    final monthIncome = appState.payPeriods
        .where((p) => p.payDate.year == now.year && p.payDate.month == now.month)
        .fold(0.0, (s, p) => s + p.netPay);

    return RefreshIndicator(
      onRefresh: () async {
        await Future.wait([appState.loadAllExpenses(), appState.refreshBudgetCategories()]);
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
        children: [
          Row(
            children: [
              Expanded(child: _Stat(label: 'Total de planilla', value: AppFormatters.currency(monthIncome))),
              Expanded(child: _Stat(label: 'Total gastado', value: AppFormatters.currency(totalSpent))),
            ],
          ),
          const SizedBox(height: 24),
          Text('Historial', style: theme.textTheme.titleLarge),
          const SizedBox(height: 12),
          if (expenses == null)
            const Padding(
              padding: EdgeInsets.only(top: 32),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (expenses.isEmpty)
            Text('Todavía no tienes gastos registrados.', style: theme.textTheme.bodyMedium)
          else
            for (final expense in expenses) _FlatExpenseTile(expense: expense),
        ],
      ),
    );
  }
}

class _FlatExpenseTile extends StatelessWidget {
  final BudgetExpense expense;
  const _FlatExpenseTile({required this.expense});

  Future<void> _delete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar gasto'),
        content: Text(
          '¿Eliminar el gasto de ${AppFormatters.currency(expense.amount)} '
          'del ${AppFormatters.date(expense.spentAt)}?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.rust),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    try {
      await AppStateScope.of(context)
          .deleteExpense(id: expense.id, budgetCategoryId: expense.budgetCategoryId);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo eliminar el gasto.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(AppRadii.card),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    Text(AppFormatters.date(expense.spentAt), style: theme.textTheme.bodyMedium),
                    if (expense.categoryName != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.line),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          expense.categoryName!,
                          style: theme.textTheme.bodySmall?.copyWith(color: AppColors.slate),
                        ),
                      ),
                  ],
                ),
                if (expense.note != null && expense.note!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    expense.note!,
                    style: theme.textTheme.bodySmall?.copyWith(color: AppColors.slate),
                  ),
                ],
              ],
            ),
          ),
          Text(AppFormatters.currency(expense.amount), style: theme.textTheme.bodyLarge),
          IconButton(
            icon: Icon(Icons.close, size: 16, color: AppColors.slate),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () => _delete(context),
          ),
        ],
      ),
    );
  }
}

/// Pestaña "Por categoría": lo que ya existía — cada categoría expandible
/// con su barra de progreso y el desglose de sus gastos.
class _ByCategoryTab extends StatelessWidget {
  final List<BudgetCategory> categories;
  const _ByCategoryTab({required this.categories});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appState = AppStateScope.of(context);

    return RefreshIndicator(
      onRefresh: appState.refreshBudgetCategories,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
        children: [
          if (categories.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(
                'Todavía no tienes categorías de presupuesto.',
                style: theme.textTheme.bodyMedium,
              ),
            )
          else
            ...categories.map((c) => _CategoryRow(category: c)),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  const _Stat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.bodyMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 4),
        // FittedBox en vez de dejar que el texto envuelva: en una pantalla
        // angosta (ej. iPhone) "Q 7,450.00" no cabe en un tercio del ancho
        // y el "Q" se iba a su propia línea — esto lo encoge para que
        // siempre quede en una sola línea.
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(value, style: theme.textTheme.titleLarge?.copyWith(color: AppColors.ink)),
        ),
      ],
    );
  }
}

class _CategoryRow extends StatefulWidget {
  final BudgetCategory category;
  const _CategoryRow({required this.category});

  @override
  State<_CategoryRow> createState() => _CategoryRowState();
}

class _CategoryRowState extends State<_CategoryRow> {
  bool _expanded = false;

  void _toggle(AppState appState) {
    setState(() => _expanded = !_expanded);
    if (_expanded && !appState.expensesByCategory.containsKey(widget.category.id)) {
      appState.loadExpensesForCategory(widget.category.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appState = AppStateScope.of(context);
    final category = widget.category;
    final color = category.isOverBudget ? AppColors.rust : AppColors.brass;
    final amountLabel = category.hasLimit
        ? '${AppFormatters.currency(category.spent)} / ${AppFormatters.currency(category.budgeted!)}'
        : '${AppFormatters.currency(category.spent)} · sin límite';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => _toggle(appState),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _expanded ? Icons.expand_less : Icons.expand_more,
                          size: 20,
                          color: AppColors.slate,
                        ),
                        const SizedBox(width: 4),
                        Text(category.name, style: theme.textTheme.bodyLarge),
                      ],
                    ),
                    Text(amountLabel, style: theme.textTheme.bodyMedium),
                  ],
                ),
                if (category.hasLimit) ...[
                  const SizedBox(height: 8),
                  AnimatedProgressBar(
                    value: category.progress.clamp(0, 1),
                    backgroundColor: AppColors.line,
                    color: color,
                  ),
                ],
              ],
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: _expanded
              ? _ExpenseBreakdown(
                  categoryId: category.id,
                  expenses: appState.expensesByCategory[category.id],
                )
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }
}

class _ExpenseBreakdown extends StatelessWidget {
  final String categoryId;
  final List<BudgetExpense>? expenses;
  const _ExpenseBreakdown({required this.categoryId, required this.expenses});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final expenses = this.expenses;

    if (expenses == null) {
      return const Padding(
        padding: EdgeInsets.only(bottom: 16),
        child: Center(
          child: SizedBox(
            height: 18,
            width: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }
    if (expenses.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16, left: 26),
        child: Text('Sin gastos registrados todavía.', style: theme.textTheme.bodyMedium),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        children: [
          for (final expense in expenses) _ExpenseTile(categoryId: categoryId, expense: expense),
        ],
      ),
    );
  }
}

class _ExpenseTile extends StatelessWidget {
  final String categoryId;
  final BudgetExpense expense;
  const _ExpenseTile({required this.categoryId, required this.expense});

  Future<void> _delete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar gasto'),
        content: Text(
          '¿Eliminar el gasto de ${AppFormatters.currency(expense.amount)} '
          'del ${AppFormatters.date(expense.spentAt)}?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.rust),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    try {
      await AppStateScope.of(context).deleteExpense(id: expense.id, budgetCategoryId: categoryId);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo eliminar el gasto.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: 26, bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppFormatters.date(expense.spentAt), style: theme.textTheme.bodyMedium),
                if (expense.note != null && expense.note!.isNotEmpty)
                  Text(
                    expense.note!,
                    style: theme.textTheme.bodySmall?.copyWith(color: AppColors.slate),
                  ),
              ],
            ),
          ),
          Text(AppFormatters.currency(expense.amount), style: theme.textTheme.bodyLarge),
          IconButton(
            icon: Icon(Icons.close, size: 16, color: AppColors.slate),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () => _delete(context),
          ),
        ],
      ),
    );
  }
}
