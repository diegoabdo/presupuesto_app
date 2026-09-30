import 'package:flutter/material.dart';

import '../models/budget_category.dart';
import '../services/data_repository.dart';
import '../state/app_state.dart';
import '../state/app_state_scope.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
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
    final totalBudgeted = categories.fold(0.0, (s, c) => s + c.budgeted);
    final totalSpent = categories.fold(0.0, (s, c) => s + c.spent);
    final totalRemaining = totalBudgeted - totalSpent;

    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        floatingActionButton: FloatingActionButton(
          heroTag: 'budget_add_expense',
          backgroundColor: AppColors.ink,
          onPressed: categories.isEmpty
              ? null
              : () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AddExpenseScreen()),
                  );
                },
          child: const Icon(Icons.add),
        ),
        body: RefreshIndicator(
          onRefresh: appState.refreshBudgetCategories,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Presupuesto', style: theme.textTheme.headlineMedium),
                  IconButton(
                    icon: const Icon(Icons.tune, color: AppColors.ink),
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
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(child: _Stat(label: 'Presupuestado', value: AppFormatters.currency(totalBudgeted))),
                  Expanded(child: _Stat(label: 'Gastado', value: AppFormatters.currency(totalSpent))),
                  Expanded(
                    child: _Stat(
                      label: 'Disponible',
                      value: AppFormatters.currency(totalRemaining),
                      valueColor: totalRemaining < 0 ? AppColors.rust : AppColors.sage,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              const Divider(height: 1),
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
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  const _Stat({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.bodyMedium),
        const SizedBox(height: 4),
        Text(value, style: theme.textTheme.titleLarge?.copyWith(color: valueColor ?? AppColors.ink)),
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
                    Text(
                      '${AppFormatters.currency(category.spent)} / ${AppFormatters.currency(category.budgeted)}',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: category.progress.clamp(0, 1),
                    minHeight: 6,
                    backgroundColor: AppColors.line,
                    valueColor: AlwaysStoppedAnimation(color),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_expanded)
          _ExpenseBreakdown(
            categoryId: category.id,
            expenses: appState.expensesByCategory[category.id],
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
            icon: const Icon(Icons.close, size: 16, color: AppColors.slate),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () => _delete(context),
          ),
        ],
      ),
    );
  }
}
