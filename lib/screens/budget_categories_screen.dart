import 'package:flutter/material.dart';

import '../models/budget_category.dart';
import '../services/api_exception.dart';
import '../state/app_state_scope.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';

class BudgetCategoriesScreen extends StatelessWidget {
  const BudgetCategoriesScreen({super.key});

  Future<void> _addOrEdit(BuildContext context, {BudgetCategory? existing}) async {
    final nameController = TextEditingController(text: existing?.name ?? '');
    final budgetController = TextEditingController(
      text: existing != null ? existing.budgeted.toStringAsFixed(2) : '',
    );
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existing == null ? 'Nueva categoría' : 'Editar categoría'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Nombre (ej. Renta, Comida)'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Ingresa un nombre' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: budgetController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Presupuesto mensual (Q)'),
                validator: (v) {
                  final value = double.tryParse(v ?? '');
                  if (value == null || value < 0) return 'Ingresa un monto válido';
                  return null;
                },
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
    if (!context.mounted) return;

    try {
      final appState = AppStateScope.of(context);
      if (existing == null) {
        await appState.createBudgetCategory(
          name: nameController.text.trim(),
          monthlyBudget: double.parse(budgetController.text),
        );
      } else {
        await appState.updateBudgetCategory(
          id: existing.id,
          name: nameController.text.trim(),
          monthlyBudget: double.parse(budgetController.text),
        );
      }
    } on ApiException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo guardar la categoría.')),
      );
    }
  }

  Future<void> _delete(BuildContext context, BudgetCategory category) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar categoría'),
        content: Text(
          '¿Eliminar "${category.name}"? Esto no borra los gastos que ya '
          'registraste en ella, pero dejarán de contarse en ningún '
          'presupuesto.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.rust),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!context.mounted) return;

    try {
      await AppStateScope.of(context).deleteBudgetCategory(category.id);
    } on ApiException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo eliminar la categoría.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categories = AppStateScope.of(context).budgetCategories;

    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(title: const Text('Categorías de presupuesto')),
      floatingActionButton: FloatingActionButton(
        heroTag: 'budget_categories_add',
        backgroundColor: AppColors.ink,
        onPressed: () => _addOrEdit(context),
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        child: categories.isEmpty
            ? Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Todavía no tienes categorías de presupuesto. Agrega la '
                  'primera con el botón +.',
                  style: theme.textTheme.bodyMedium,
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
                itemCount: categories.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final c = categories[i];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(c.name),
                    subtitle: Text(
                      'Presupuesto: ${AppFormatters.currency(c.budgeted)} · '
                      'Gastado este mes: ${AppFormatters.currency(c.spent)}',
                    ),
                    onTap: () => _addOrEdit(context, existing: c),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: AppColors.rust),
                      onPressed: () => _delete(context, c),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
