import 'package:flutter/material.dart';

import '../models/pay_period.dart';
import '../state/app_state_scope.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import 'add_pay_period_screen.dart';

class IncomeScreen extends StatelessWidget {
  const IncomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appState = AppStateScope.of(context);

    if (appState.isLoading && appState.payPeriods.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    // El backend ya las entrega ordenadas por fecha de pago descendente.
    final periods = appState.payPeriods;

    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        floatingActionButton: FloatingActionButton(
          heroTag: 'income_add_pay_period',
          backgroundColor: AppColors.ink,
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AddPayPeriodScreen()),
            );
          },
          child: const Icon(Icons.add),
        ),
        body: RefreshIndicator(
          onRefresh: appState.loadAll,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
            children: [
              Text('Ingresos', style: theme.textTheme.headlineMedium),
              const SizedBox(height: 4),
              Text('Historial de planillas', style: theme.textTheme.bodyMedium),
              const SizedBox(height: 24),
              if (periods.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 24),
                  child: Text(
                    'Todavía no tienes planillas registradas.',
                    style: theme.textTheme.bodyMedium,
                  ),
                )
              else
                ...periods.map((p) => _PayPeriodTile(period: p)),
            ],
          ),
        ),
      ),
    );
  }
}

class _PayPeriodTile extends StatelessWidget {
  final PayPeriod period;
  const _PayPeriodTile({required this.period});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(4),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        title: Text(
          '${AppFormatters.shortDate(period.periodStart)} – ${AppFormatters.shortDate(period.periodEnd)}',
          style: theme.textTheme.bodyLarge,
        ),
        subtitle: Text(
          '${period.schedule.label} · ${AppFormatters.date(period.payDate)}',
          style: theme.textTheme.bodyMedium,
        ),
        trailing: Text(
          AppFormatters.currency(period.netPay),
          style: theme.textTheme.titleLarge,
        ),
        children: [
          const Divider(height: 1),
          const SizedBox(height: 12),
          ...period.incomeSources.map(
            (i) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(i.label, style: theme.textTheme.bodyMedium),
                  Text(AppFormatters.currency(i.amount), style: theme.textTheme.bodyMedium),
                ],
              ),
            ),
          ),
          ...period.deductions.map(
            (d) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${d.label} (-${(d.percentage * 100).toStringAsFixed(2)}%)',
                    style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.rust),
                  ),
                  Text(
                    '-${AppFormatters.currency(d.amount)}',
                    style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.rust),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => AddPayPeriodScreen(existing: period)),
                ),
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text('Editar'),
              ),
              TextButton.icon(
                onPressed: () => _confirmDelete(context, period),
                icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.rust),
                label: const Text('Eliminar', style: TextStyle(color: AppColors.rust)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, PayPeriod period) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar planilla'),
        content: Text(
          '¿Seguro que quieres eliminar la planilla del '
          '${AppFormatters.date(period.payDate)}? Esta acción no se puede deshacer.',
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
      await AppStateScope.of(context).deletePayPeriod(period.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Planilla eliminada.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo eliminar la planilla.')),
        );
      }
    }
  }
}
