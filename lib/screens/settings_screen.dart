import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import 'deduction_rules_screen.dart';
import 'income_sources_screen.dart';

class SettingsScreen extends StatelessWidget {
  final VoidCallback onLoggedOut;
  const SettingsScreen({super.key, required this.onLoggedOut});

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Seguro que quieres cerrar tu sesión en este dispositivo?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Cerrar sesión')),
        ],
      ),
    );
    if (confirmed == true) {
      await AuthService.instance.logout();
      onLoggedOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
        children: [
          Text('Ajustes', style: theme.textTheme.headlineMedium),
          const SizedBox(height: 24),
          _SettingsSection(
            title: 'Ingresos',
            items: [
              _SettingsItem(
                icon: Icons.payments_outlined,
                label: 'Fuentes de ingreso',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const IncomeSourcesScreen()),
                ),
              ),
              _SettingsItem(icon: Icons.calendar_month_outlined, label: 'Calendario de pago'),
            ],
          ),
          _SettingsSection(
            title: 'Descuentos',
            items: [
              _SettingsItem(
                icon: Icons.rule_outlined,
                label: 'Reglas de descuento (IGSS, ISR)',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const DeductionRulesScreen()),
                ),
              ),
            ],
          ),
          _SettingsSection(
            title: 'Cuenta',
            items: [
              _SettingsItem(icon: Icons.cloud_outlined, label: 'Sincronización en la nube'),
              _SettingsItem(
                icon: Icons.logout,
                label: 'Cerrar sesión',
                onTap: () => _confirmLogout(context),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<_SettingsItem> items;
  const _SettingsSection({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.line),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Column(
              children: [
                for (int i = 0; i < items.length; i++) ...[
                  if (i > 0) const Divider(height: 1),
                  items[i],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  const _SettingsItem({required this.icon, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.ink),
      title: Text(label),
      trailing: const Icon(Icons.chevron_right, color: AppColors.slate),
      onTap: onTap ??
          () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('$label: próximamente')),
            );
          },
    );
  }
}
