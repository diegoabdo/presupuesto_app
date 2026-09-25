import 'package:flutter/material.dart';

import '../models/budget_category.dart';
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

class _CategoryRow extends StatelessWidget {
  final BudgetCategory category;
  const _CategoryRow({required this.category});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = category.isOverBudget ? AppColors.rust : AppColors.brass;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(category.name, style: theme.textTheme.bodyLarge),
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
    );
  }
}
