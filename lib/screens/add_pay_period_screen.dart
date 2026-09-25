import 'package:flutter/material.dart';

import '../models/pay_period.dart';
import '../models/settings_models.dart';
import '../services/api_exception.dart';
import '../state/app_state_scope.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';

class _IncomeLine {
  String label;
  double amount;
  _IncomeLine({required this.label, required this.amount});
}

class _DeductionLine {
  DeductionRuleTemplate rule;
  double baseAmount;
  _DeductionLine({required this.rule, required this.baseAmount});
}

class AddPayPeriodScreen extends StatefulWidget {
  const AddPayPeriodScreen({super.key});

  @override
  State<AddPayPeriodScreen> createState() => _AddPayPeriodScreenState();
}

class _AddPayPeriodScreenState extends State<AddPayPeriodScreen> {
  DateTime _periodStart = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _periodEnd = DateTime(DateTime.now().year, DateTime.now().month + 1, 0);
  DateTime _payDate = DateTime.now();
  final _paymentMethodController = TextEditingController(text: 'Transferencia');
  WorkSchedule _schedule = WorkSchedule.tiempoCompleto;

  final List<_IncomeLine> _incomes = [];
  final List<_DeductionLine> _deductions = [];
  bool _isSaving = false;

  @override
  void dispose() {
    _paymentMethodController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(DateTime initial, ValueChanged<DateTime> onPicked) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) onPicked(picked);
  }

  Future<void> _addIncomeLine() async {
    final templates = AppStateScope.of(context).incomeSourceTemplates;
    final labelController = TextEditingController();
    final amountController = TextEditingController();
    IncomeSourceTemplate? selectedTemplate;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Agregar ingreso'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (templates.isNotEmpty) ...[
                DropdownButtonFormField<IncomeSourceTemplate>(
                  initialValue: selectedTemplate,
                  decoration: const InputDecoration(labelText: 'Usar una fuente guardada (opcional)'),
                  items: templates
                      .map((t) => DropdownMenuItem(value: t, child: Text(t.label)))
                      .toList(),
                  onChanged: (t) {
                    setDialogState(() {
                      selectedTemplate = t;
                      if (t != null) {
                        labelController.text = t.label;
                        amountController.text = t.defaultAmount.toStringAsFixed(2);
                      }
                    });
                  },
                ),
                const SizedBox(height: 12),
              ],
              TextField(
                controller: labelController,
                decoration: const InputDecoration(labelText: 'Nombre (ej. Salario base)'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Monto (Q)'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Agregar')),
          ],
        ),
      ),
    );

    if (result != true) return;
    final amount = double.tryParse(amountController.text);
    if (labelController.text.trim().isEmpty || amount == null || amount <= 0) return;

    setState(() {
      _incomes.add(_IncomeLine(label: labelController.text.trim(), amount: amount));
    });
  }

  Future<void> _addDeductionLine() async {
    final rules = AppStateScope.of(context).deductionRuleTemplates;
    if (rules.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Primero crea una regla de descuento en Ajustes (ej. IGSS).'),
        ),
      );
      return;
    }

    DeductionRuleTemplate selectedRule = rules.first;
    final baseController = TextEditingController(
      text: _incomes.fold(0.0, (s, i) => s + i.amount).toStringAsFixed(2),
    );

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Agregar descuento'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<DeductionRuleTemplate>(
                initialValue: selectedRule,
                decoration: const InputDecoration(labelText: 'Regla'),
                items: rules
                    .map((r) => DropdownMenuItem(
                          value: r,
                          child: Text('${r.label} (${(r.percentage * 100).toStringAsFixed(2)}%)'),
                        ))
                    .toList(),
                onChanged: (r) => setDialogState(() => selectedRule = r ?? selectedRule),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: baseController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Base sobre la que se calcula (Q)'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Agregar')),
          ],
        ),
      ),
    );

    if (result != true) return;
    final base = double.tryParse(baseController.text);
    if (base == null || base < 0) return;

    setState(() {
      _deductions.add(_DeductionLine(rule: selectedRule, baseAmount: base));
    });
  }

  Future<void> _save() async {
    if (_incomes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Agrega al menos un ingreso.')),
      );
      return;
    }
    if (_periodEnd.isBefore(_periodStart)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La fecha final no puede ser antes que la inicial.')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      await AppStateScope.of(context).createPayPeriod(
        periodStart: _periodStart,
        periodEnd: _periodEnd,
        payDate: _payDate,
        paymentMethod: _paymentMethodController.text.trim(),
        schedule: _schedule,
        incomes: _incomes.map((i) => {'label': i.label, 'amount': i.amount}).toList(),
        deductions: _deductions
            .map((d) => {
                  'deduction_rule_id': int.parse(d.rule.id),
                  'base_amount': d.baseAmount,
                })
            .toList(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Planilla guardada.')),
      );
      Navigator.of(context).maybePop();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo guardar la planilla.')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text('Nueva planilla'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                children: [
                  Text('Período', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 8),
                  _DateField(
                    label: 'Inicio',
                    date: _periodStart,
                    onTap: () => _pickDate(_periodStart, (d) => setState(() => _periodStart = d)),
                  ),
                  const SizedBox(height: 8),
                  _DateField(
                    label: 'Fin',
                    date: _periodEnd,
                    onTap: () => _pickDate(_periodEnd, (d) => setState(() => _periodEnd = d)),
                  ),
                  const SizedBox(height: 8),
                  _DateField(
                    label: 'Fecha de pago',
                    date: _payDate,
                    onTap: () => _pickDate(_payDate, (d) => setState(() => _payDate = d)),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _paymentMethodController,
                    decoration: const InputDecoration(labelText: 'Método de pago'),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<WorkSchedule>(
                    initialValue: _schedule,
                    decoration: const InputDecoration(labelText: 'Esquema de trabajo'),
                    items: WorkSchedule.values
                        .map((s) => DropdownMenuItem(value: s, child: Text(s.label)))
                        .toList(),
                    onChanged: (s) => setState(() => _schedule = s ?? _schedule),
                  ),
                  const SizedBox(height: 28),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Ingresos', style: theme.textTheme.titleLarge),
                      TextButton.icon(
                        onPressed: _addIncomeLine,
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Agregar'),
                      ),
                    ],
                  ),
                  if (_incomes.isEmpty)
                    Text('Todavía no has agregado ningún ingreso.', style: theme.textTheme.bodyMedium)
                  else
                    ..._incomes.asMap().entries.map(
                          (entry) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(entry.value.label),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(AppFormatters.currency(entry.value.amount)),
                                IconButton(
                                  icon: const Icon(Icons.close, size: 18),
                                  onPressed: () => setState(() => _incomes.removeAt(entry.key)),
                                ),
                              ],
                            ),
                          ),
                        ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Descuentos', style: theme.textTheme.titleLarge),
                      TextButton.icon(
                        onPressed: _addDeductionLine,
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Agregar'),
                      ),
                    ],
                  ),
                  if (_deductions.isEmpty)
                    Text('Sin descuentos agregados.', style: theme.textTheme.bodyMedium)
                  else
                    ..._deductions.asMap().entries.map(
                          (entry) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(entry.value.rule.label),
                            subtitle: Text('Base: ${AppFormatters.currency(entry.value.baseAmount)}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '-${AppFormatters.currency(entry.value.baseAmount * entry.value.rule.percentage)}',
                                  style: const TextStyle(color: AppColors.rust),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close, size: 18),
                                  onPressed: () => setState(() => _deductions.removeAt(entry.key)),
                                ),
                              ],
                            ),
                          ),
                        ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isSaving ? null : _save,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.ink,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Guardar planilla'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final DateTime date;
  final VoidCallback onTap;
  const _DateField({required this.label, required this.date, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.line),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: theme.textTheme.bodyMedium),
            Row(
              children: [
                Text(AppFormatters.date(date), style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right, size: 18, color: AppColors.slate),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
