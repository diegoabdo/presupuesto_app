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

  Future<void> _deleteGoal() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar meta'),
        content: Text(
          '¿Eliminar "${_goal.name}" y todos sus aportes registrados? '
          'Esta acción no se puede deshacer.',
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
    if (confirmed != true || !mounted) return;

    try {
      await AppStateScope.of(context).deleteSavingsGoal(_goal.id);
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo eliminar la meta.')),
      );
    }
  }

  /// Formulario compartido por "Agregar aporte" y "Editar aporte": monto,
  /// nota y fecha. Devuelve null si se cancela.
  Future<({double amount, String? note, DateTime date})?> _showContributionDialog({
    required String title,
    double? initialAmount,
    String? initialNote,
    DateTime? initialDate,
  }) async {
    final amountController =
        TextEditingController(text: initialAmount != null ? initialAmount.toStringAsFixed(2) : '');
    final noteController = TextEditingController(text: initialNote ?? '');
    DateTime date = initialDate ?? DateTime.now();
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(title),
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
                const SizedBox(height: 12),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: date,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) setDialogState(() => date = picked);
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(labelText: 'Fecha'),
                    child: Text(AppFormatters.date(date)),
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

    if (result != true) return null;
    return (amount: double.parse(amountController.text), note: noteController.text.trim(), date: date);
  }

  Future<void> _addContribution() async {
    final input = await _showContributionDialog(title: 'Agregar aporte');
    if (input == null) return;
    if (!mounted) return;

    try {
      final appState = AppStateScope.of(context);
      await appState.addContribution(
        savingsGoalId: _goal.id,
        amount: input.amount,
        note: input.note?.isEmpty ?? true ? null : input.note,
        contributedAt: input.date,
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

  Future<void> _editContribution(SavingsContribution contribution) async {
    final input = await _showContributionDialog(
      title: 'Editar aporte',
      initialAmount: contribution.amount,
      initialNote: contribution.note,
      initialDate: contribution.date,
    );
    if (input == null) return;
    if (!mounted) return;

    try {
      final appState = AppStateScope.of(context);
      await appState.updateContribution(
        savingsGoalId: _goal.id,
        contributionId: contribution.id,
        amount: input.amount,
        note: input.note?.isEmpty ?? true ? null : input.note,
        contributedAt: input.date,
      );
      if (!mounted) return;
      final updated = appState.savingsGoals.firstWhere(
        (g) => g.id == _goal.id,
        orElse: () => _goal,
      );
      setState(() => _goal = updated);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aporte actualizado.')),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo actualizar el aporte.')),
      );
    }
  }

  Future<void> _deleteContribution(SavingsContribution contribution) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar aporte'),
        content: Text(
          '¿Eliminar el aporte de ${AppFormatters.currency(contribution.amount)} '
          'del ${AppFormatters.date(contribution.date)}?',
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
    if (confirmed != true || !mounted) return;

    try {
      final appState = AppStateScope.of(context);
      await appState.deleteContribution(savingsGoalId: _goal.id, contributionId: contribution.id);
      if (!mounted) return;
      final updated = appState.savingsGoals.firstWhere(
        (g) => g.id == _goal.id,
        orElse: () => _goal,
      );
      setState(() => _goal = updated);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aporte eliminado.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo eliminar el aporte.')),
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
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Eliminar meta',
            onPressed: _deleteGoal,
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
                  child: _Stat(label: 'Acumulado', value: AppFormatters.currency(goal.currentAmount)),
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
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(AppFormatters.date(c.date), style: theme.textTheme.bodyMedium),
                            if (c.note != null && c.note!.isNotEmpty)
                              Text(
                                c.note!,
                                style: theme.textTheme.bodySmall?.copyWith(color: AppColors.slate),
                              ),
                          ],
                        ),
                      ),
                      Text(
                        '+${AppFormatters.currency(c.amount)}',
                        style: theme.textTheme.bodyLarge?.copyWith(color: AppColors.sage),
                      ),
                      PopupMenuButton<String>(
                        icon: Icon(Icons.more_vert, size: 18, color: AppColors.slate),
                        onSelected: (action) {
                          if (action == 'edit') _editContribution(c);
                          if (action == 'delete') _deleteContribution(c);
                        },
                        itemBuilder: (ctx) => const [
                          PopupMenuItem(value: 'edit', child: Text('Editar')),
                          PopupMenuItem(value: 'delete', child: Text('Eliminar')),
                        ],
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
