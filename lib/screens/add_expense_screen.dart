import 'package:flutter/material.dart';

import '../models/budget_category.dart';
import '../services/api_exception.dart';
import '../state/app_state_scope.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

const _noCategoryLabel = 'Sin categoría';

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  String _amount = '0';
  BudgetCategory? _selectedCategory;
  bool _noCategory = false;
  bool _initialized = false;
  bool _isSaving = false;
  DateTime _spentAt = DateTime.now();
  final _noteController = TextEditingController();

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _spentAt,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) setState(() => _spentAt = picked);
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  /// Si ya existe la categoría "Sin categoría" (de un gasto suelto
  /// anterior), la reutiliza en vez de crear una duplicada.
  BudgetCategory? _findNoCategory(List<BudgetCategory> categories) {
    for (final c in categories) {
      if (c.name == _noCategoryLabel) return c;
    }
    return null;
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _tapKey(String key) {
    setState(() {
      if (key == 'back') {
        _amount = _amount.length > 1 ? _amount.substring(0, _amount.length - 1) : '0';
        return;
      }
      if (key == '.') {
        if (_amount.contains('.')) return;
        _amount += '.';
        return;
      }
      // Limit to 2 decimals.
      if (_amount.contains('.') && _amount.split('.')[1].length >= 2) return;
      _amount = _amount == '0' ? key : _amount + key;
    });
  }

  Future<void> _save() async {
    final amount = double.tryParse(_amount);
    final category = _selectedCategory;
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa un monto válido.')),
      );
      return;
    }
    if (!_noCategory && category == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Elige una categoría.')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final appState = AppStateScope.of(context);
      String categoryId;
      if (_noCategory) {
        final existing = _findNoCategory(appState.budgetCategories);
        categoryId = existing?.id ??
            (await appState.createBudgetCategory(
              name: _noCategoryLabel,
              monthlyBudget: null,
            ))
                .id;
      } else {
        categoryId = category!.id;
      }

      await appState.addExpense(
        budgetCategoryId: categoryId,
        amount: amount,
        note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
        spentAt: _spentAt,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gasto guardado.')),
      );
      Navigator.of(context).maybePop();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo guardar el gasto.')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categories = AppStateScope.of(context).budgetCategories;

    if (!_initialized && categories.isNotEmpty) {
      _selectedCategory = categories.first;
      _initialized = true;
    }

    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text('Nuevo gasto'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                children: [
                  Column(
                    children: [
                      Text('Monto', style: theme.textTheme.bodyMedium),
                      const SizedBox(height: 6),
                      Text(
                        'Q $_amount',
                        style: theme.textTheme.displayMedium?.copyWith(fontSize: 44),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text('Categoría', style: theme.textTheme.bodyMedium),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final category in categories.where((c) => c.name != _noCategoryLabel))
                        ChoiceChip(
                          label: Text(category.name),
                          selected: !_noCategory && _selectedCategory?.id == category.id,
                          onSelected: (_) => setState(() {
                            _selectedCategory = category;
                            _noCategory = false;
                          }),
                          selectedColor: AppColors.ink,
                          backgroundColor: AppColors.surface,
                          side: BorderSide(color: AppColors.line),
                          labelStyle: TextStyle(
                            color: !_noCategory && _selectedCategory?.id == category.id
                                ? AppColors.paper
                                : AppColors.ink,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ChoiceChip(
                        label: const Text(_noCategoryLabel),
                        selected: _noCategory,
                        onSelected: (_) => setState(() => _noCategory = true),
                        selectedColor: AppColors.ink,
                        backgroundColor: AppColors.surface,
                        side: BorderSide(color: AppColors.line),
                        labelStyle: TextStyle(
                          color: _noCategory ? AppColors.paper : AppColors.ink,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  InkWell(
                    onTap: _pickDate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        border: Border.all(color: AppColors.line),
                        borderRadius: BorderRadius.circular(AppRadii.control),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Fecha', style: theme.textTheme.bodyMedium),
                          Row(
                            children: [
                              Text(
                                _isToday(_spentAt) ? 'Hoy' : AppFormatters.date(_spentAt),
                                style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(width: 4),
                              Icon(Icons.chevron_right, size: 18, color: AppColors.slate),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _noteController,
                    decoration: InputDecoration(
                      hintText: 'Nota (opcional)',
                      filled: true,
                      fillColor: AppColors.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadii.control),
                        borderSide: BorderSide(color: AppColors.line),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  _Keypad(onKeyTap: _tapKey),
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.control)),
                  ),
                  child: _isSaving
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.paper),
                        )
                      : const Text('Guardar gasto'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Keypad extends StatelessWidget {
  final void Function(String key) onKeyTap;
  const _Keypad({required this.onKeyTap});

  @override
  Widget build(BuildContext context) {
    const keys = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '.', '0', 'back'];
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.7,
      children: keys.map((k) {
        return OutlinedButton(
          onPressed: () => onKeyTap(k),
          style: OutlinedButton.styleFrom(
            backgroundColor: AppColors.surface,
            side: BorderSide(color: AppColors.line),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.control)),
          ),
          child: k == 'back'
              ? Icon(Icons.backspace_outlined, size: 20, color: AppColors.ink)
              : Text(
                  k,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.ink),
                ),
        );
      }).toList(),
    );
  }
}
