import 'package:flutter/material.dart';

import '../models/pay_period.dart';
import '../state/app_state_scope.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/animated_progress_bar.dart';
import '../widgets/ledger_row.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appState = AppStateScope.of(context);

    if (appState.isLoading && !appState.hasData) {
      return const Center(child: CircularProgressIndicator());
    }
    if (appState.error != null && !appState.hasData) {
      return _ErrorState(message: appState.error!, onRetry: appState.loadAll);
    }

    // El backend ya entrega las planillas ordenadas por fecha de pago
    // descendente, así que la primera es la más reciente.
    final periods = appState.payPeriods;
    final nextPay = periods.isNotEmpty ? periods.first : null;
    final goals = appState.savingsGoals;
    final goal = goals.isNotEmpty ? goals.first : null;
    final categories = appState.budgetCategories;
    final totalBudgeted = categories.fold(0.0, (s, c) => s + (c.budgeted ?? 0));
    final totalSpent = categories.fold(0.0, (s, c) => s + c.spent);

    return RefreshIndicator(
      onRefresh: appState.loadAll,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
          children: [
            Text(
              'Hola, ${appState.currentUser?.name.split(' ').first ?? ''}',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 4),
            Text('Tu resumen', style: theme.textTheme.headlineMedium),
            const SizedBox(height: 28),

            // Hero: próximo pago
            if (nextPay != null)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(AppRadii.card),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Última planilla registrada',
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: theme.colorScheme.onPrimary.withValues(alpha: 0.7)),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppFormatters.currency(nextPay.netPay),
                      style: theme.textTheme.displayMedium?.copyWith(color: theme.colorScheme.onPrimary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${AppFormatters.date(nextPay.payDate)} · ${nextPay.paymentMethod} · ${nextPay.schedule.label}',
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: theme.colorScheme.onPrimary.withValues(alpha: 0.7)),
                    ),
                  ],
                ),
              )
            else
              _EmptyCard(text: 'Todavía no tienes planillas registradas.'),

            const SizedBox(height: 28),

            Row(
              children: [
                Expanded(
                  child: _SummaryStat(
                    label: 'Presupuestado',
                    value: AppFormatters.currency(totalBudgeted),
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: _SummaryStat(
                    label: 'Gastado',
                    value: AppFormatters.currency(totalSpent),
                    valueColor: totalSpent > totalBudgeted ? AppColors.rust : AppColors.ink,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            if (goal != null) ...[
              Text(goal.name, style: theme.textTheme.titleLarge),
              const SizedBox(height: 12),
              AnimatedProgressBar(
                value: goal.progress,
                minHeight: 8,
                backgroundColor: AppColors.line,
                color: AppColors.brass,
              ),
              const SizedBox(height: 8),
              Text(
                '${AppFormatters.currency(goal.currentAmount)} de ${AppFormatters.currency(goal.targetAmount)} '
                '· ${(goal.progress * 100).toStringAsFixed(0)}%',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 32),
            ],

            Text('Categorías de presupuesto', style: theme.textTheme.titleLarge),
            const Divider(height: 24),
            if (categories.isEmpty)
              _EmptyCard(text: 'Todavía no tienes categorías de presupuesto.')
            else
              ...categories.map(
                (c) => LedgerRow(
                  label: c.name,
                  sublabel: c.hasLimit
                      ? '${AppFormatters.currency(c.spent)} de ${AppFormatters.currency(c.budgeted!)}'
                      : '${AppFormatters.currency(c.spent)} · sin límite',
                  trailing: c.hasLimit ? AppFormatters.currency(c.remaining!) : '—',
                  trailingColor: c.isOverBudget ? AppColors.rust : AppColors.sage,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SummaryStat extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _SummaryStat({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.bodyMedium),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(color: valueColor ?? AppColors.ink),
        ),
      ],
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final String text;
  const _EmptyCard({required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(AppRadii.card),
      ),
      child: Text(text, style: theme.textTheme.bodyMedium),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Reintentar')),
          ],
        ),
      ),
    );
  }
}
