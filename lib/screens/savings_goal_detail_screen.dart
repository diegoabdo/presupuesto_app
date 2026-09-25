import 'package:flutter/material.dart';

import '../models/savings_goal.dart';
import '../services/api_exception.dart';
import '../state/app_state_scope.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/progress_ring.dart';

class SavingsGoalDetailScreen extends StatefulWidget {
  final SavingsGoal goal;

  const SavingsGoalDetailScreen({super.key, required this.goal});

  @override
  State<SavingsGoalDetailScreen> createState() => _SavingsGoalDetailScreenState();
}

class _SavingsGoalDetailScreenState extends State<SavingsGoalDetailScreen> {
  late SavingsGoal _goal = widget.goal;

  Future<void> _editGoal() async {
    final nameController = TextEditingController(text: _goal.name);
    final targetController = TextEditingController(text: _goal.targetAmount.toStringAsFixed(2));
    DateTime? targetDate = _goal.targetDate;
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Editar meta'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Nombre'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Ingresa un nombre' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: targetController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Monto meta (Q)'),
                  validator: (v) {
                    final value = double.tryParse(v ?? '');
                    if (value == null || value <= 0) return 'Ingresa un monto válido';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: targetDate ?? DateTime.now().add(const Duration(days: 365)),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) setDialogState(() => targetDate = picked);
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(labelText: 'Fecha meta (opcional)'),
                    child: Text(
                      targetDate != null ? AppFormatters.date(targetDate!) : 'Sin definir',
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
            FilledButton(
              onPressed: () {
                if (formKey.currentState!.validate()) Navigator.pop(ctx, true);
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );

    if (result != true) return;
    if (!mounted) return;

    try {
      final appState = AppStateScope.of(context);
      final updated = await appState.updateSavingsGoal(
        id: _goal.id,
        name: nameController.text.trim(),
        targetAmount: double.parse(targetController.text),
        targetDate: targetDate,
      );
      if (!mounted) return;
      setState(() => _goal = updated);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Meta actualizada.')),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo actualizar la meta.')),
      );
    }
  }

  Future<void> _addContribution() async {
    final amountController = TextEditingController();
    final noteController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Agregar aporte'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: amountController,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Monto (Q)'),
                validator: (v) {
                  final value = double.tryParse(v ?? '');
                  if (value == null || value <= 0) return 'Ingresa un monto válido';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: noteController,
                decoration: const InputDecoration(labelText: 'Nota (opcional)'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) Navigator.pop(ctx, true);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (result != true) return;
    if (!mounted) return;

    final amount = double.parse(amountController.text);
    final note = noteController.text.trim();

    try {
      final appState = AppStateScope.of(context);
      await appState.addContribution(
        savingsGoalId: _goal.id,
        amount: amount,
        note: note.isEmpty ? null : note,
        contributedAt: DateTime.now(),
      );
      if (!mounted) return;
      final updated = appState.savingsGoals.firstWhere(
        (g) => g.id == _goal.id,
        orElse: () => _goal,
      );
      setState(() => _goal = updated);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aporte agregado.')),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo guardar el aporte.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final goal = _goal;
    final contributions = goal.contributions.reversed.toList();

    final monthsElapsed = contributions.isEmpty
        ? 1.0
        : (DateTime.now().difference(contributions.last.date).inDays / 30)
            .clamp(1, double.infinity);
    final avgMonthly = goal.currentAmount / monthsElapsed;
    final monthsRemaining = avgMonthly <= 0 ? null : (goal.remaining / avgMonthly).ceil();

    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        title: Text(goal.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Editar meta',
            onPressed: _editGoal,
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            Center(
              child: ProgressRing(
                progress: goal.progress,
                trackColor: AppColors.line,
                progressColor: AppColors.brass,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${(goal.progress * 100).toStringAsFixed(0)}%',
                      style: theme.textTheme.displayMedium,
                    ),
                    Text('completado', style: theme.textTheme.bodyMedium),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                  child: _Stat(label: 'Ahorrado', value: AppFormatters.currency(goal.currentAmount)),
                ),
                Expanded(
                  child: _Stat(label: 'Meta', value: AppFormatters.currency(goal.targetAmount)),
                ),
              ],
            ),
            if (monthsRemaining != null) ...[
              const SizedBox(height: 14),
              Text(
                'A tu ritmo actual, llegarías a la meta en aproximadamente $monthsRemaining meses.',
                style: theme.textTheme.bodyMedium,
              ),
            ],
            const SizedBox(height: 22),
            Center(
              child: FilledButton.icon(
                onPressed: _addContribution,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.ink,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                ),
                icon: const Icon(Icons.add),
                label: const Text('Agregar aporte'),
              ),
            ),
            const SizedBox(height: 32),
            Text('Aportes recientes', style: theme.textTheme.titleLarge),
            const Divider(height: 24),
            if (contributions.isEmpty)
              Text('Todavía no hay aportes registrados.', style: theme.textTheme.bodyMedium)
            else
              ...contributions.map(
                (c) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(AppFormatters.date(c.date), style: theme.textTheme.bodyMedium),
                      Text(
                        '+${AppFormatters.currency(c.amount)}',
                        style: theme.textTheme.bodyLarge?.copyWith(color: AppColors.sage),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
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
        Text(label, style: theme.textTheme.bodyMedium),
        const SizedBox(height: 4),
        Text(value, style: theme.textTheme.titleLarge),
      ],
    );
  }
}
