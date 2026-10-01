import 'package:flutter/material.dart';

import '../services/api_exception.dart';
import '../state/app_state_scope.dart';
import '../theme/app_theme.dart';

class DeductionRulesScreen extends StatelessWidget {
  const DeductionRulesScreen({super.key});

  Future<void> _addRule(BuildContext context) async {
    final labelController = TextEditingController();
    final percentageController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nueva regla de descuento'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: labelController,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Nombre (ej. Cuota IGSS)'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Ingresa un nombre' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: percentageController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Porcentaje (ej. 4.83 para 4.83%)',
                ),
                validator: (v) {
                  final value = double.tryParse(v ?? '');
                  if (value == null || value <= 0 || value > 100) {
                    return 'Ingresa un porcentaje entre 0 y 100';
                  }
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
      await AppStateScope.of(context).createDeductionRuleTemplate(
        label: labelController.text.trim(),
        percentageHuman: double.parse(percentageController.text),
      );
    } on ApiException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo guardar la regla.')),
      );
    }
  }

  Future<void> _delete(BuildContext context, String id) async {
    try {
      await AppStateScope.of(context).deleteDeductionRuleTemplate(id);
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
    final rules = AppStateScope.of(context).deductionRuleTemplates;

    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(title: const Text('Reglas de descuento')),
      floatingActionButton: FloatingActionButton(
        heroTag: 'deduction_rules_add',
        backgroundColor: AppColors.ink,
        onPressed: () => _addRule(context),
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        child: rules.isEmpty
            ? Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Todavía no tienes reglas de descuento (ej. IGSS, ISR). '
                  'Agrega al menos una para poder registrar planillas nuevas.',
                  style: theme.textTheme.bodyMedium,
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
                itemCount: rules.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final r = rules[i];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(r.label),
                    subtitle: Text('${(r.percentage * 100).toStringAsFixed(2)}%'),
                    trailing: IconButton(
                      icon: Icon(Icons.delete_outline, color: AppColors.rust),
                      onPressed: () => _delete(context, r.id),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
