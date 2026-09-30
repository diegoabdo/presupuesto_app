import 'package:flutter/material.dart';

import '../services/api_exception.dart';
import '../state/app_state_scope.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';

class IncomeSourcesScreen extends StatelessWidget {
  const IncomeSourcesScreen({super.key});

  Future<void> _addTemplate(BuildContext context) async {
    final labelController = TextEditingController();
    final amountController = TextEditingController();
    bool isRecurring = true;
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Nueva fuente de ingreso'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: labelController,
                  autofocus: true,
                  decoration: const InputDecoration(labelText: 'Nombre (ej. Salario base)'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Ingresa un nombre' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Monto habitual (Q)'),
                  validator: (v) {
                    final value = double.tryParse(v ?? '');
                    if (value == null || value < 0) return 'Ingresa un monto válido';
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Es recurrente (aparece cada planilla)'),
                  value: isRecurring,
                  onChanged: (v) => setDialogState(() => isRecurring = v),
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
    if (!context.mounted) return;

    try {
      await AppStateScope.of(context).createIncomeSourceTemplate(
        label: labelController.text.trim(),
        defaultAmount: double.parse(amountController.text),
        isRecurring: isRecurring,
      );
    } on ApiException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo guardar la fuente de ingreso.')),
      );
    }
  }

  Future<void> _delete(BuildContext context, String id) async {
    try {
      await AppStateScope.of(context).deleteIncomeSourceTemplate(id);
    } on ApiException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo eliminar.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final templates = AppStateScope.of(context).incomeSourceTemplates;

    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(title: const Text('Fuentes de ingreso')),
      floatingActionButton: FloatingActionButton(
        heroTag: 'income_sources_add',
        backgroundColor: AppColors.ink,
        onPressed: () => _addTemplate(context),
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        child: templates.isEmpty
            ? Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Todavía no tienes fuentes de ingreso guardadas. Agrega '
                  'las que uses seguido (salario base, bonos) para llenar '
                  'una planilla nueva más rápido.',
                  style: theme.textTheme.bodyMedium,
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
                itemCount: templates.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final t = templates[i];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(t.label),
                    subtitle: Text(
                      '${AppFormatters.currency(t.defaultAmount)} · '
                      '${t.isRecurring ? "Recurrente" : "Puntual"}',
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: AppColors.rust),
                      onPressed: () => _delete(context, t.id),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
