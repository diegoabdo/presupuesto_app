import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../state/app_state_scope.dart';
import '../state/theme_controller.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import 'deduction_rules_screen.dart';
import 'income_sources_screen.dart';
import 'pay_calendar_screen.dart';

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

  void _showSyncInfo(BuildContext context, DateTime? lastSyncedAt) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sincronización en la nube'),
        content: Text(
          lastSyncedAt != null
              ? 'Tus datos viven en tu cuenta y se actualizan cada vez que abres '
                  'la app o haces pull-to-refresh.\n\nÚltima sincronización: '
                  '${AppFormatters.date(lastSyncedAt)}, ${TimeOfDay.fromDateTime(lastSyncedAt).format(ctx)}.'
              : 'Tus datos viven en tu cuenta y se actualizan cada vez que abres '
                  'la app o haces pull-to-refresh.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Entendido')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appState = AppStateScope.of(context);
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
        children: [
          Text('Ajustes', style: theme.textTheme.headlineMedium),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Apariencia', style: theme.textTheme.bodyMedium),
                const SizedBox(height: 8),
                ListenableBuilder(
                  listenable: ThemeController.instance,
                  builder: (context, _) => SegmentedButton<ThemeMode>(
                    style: SegmentedButton.styleFrom(
                      selectedBackgroundColor: AppColors.ink,
                      selectedForegroundColor: AppColors.paper,
                      side: BorderSide(color: AppColors.line),
                    ),
                    segments: const [
                      ButtonSegment(
                        value: ThemeMode.light,
                        icon: Icon(Icons.light_mode_outlined),
                        label: Text('Claro'),
                      ),
                      ButtonSegment(
                        value: ThemeMode.dark,
                        icon: Icon(Icons.dark_mode_outlined),
                        label: Text('Oscuro'),
                      ),
                      ButtonSegment(
                        value: ThemeMode.system,
                        icon: Icon(Icons.brightness_auto_outlined),
                        label: Text('Sistema'),
                      ),
                    ],
                    selected: {ThemeController.instance.mode},
                    onSelectionChanged: (selection) =>
                        ThemeController.instance.setMode(selection.first),
                  ),
                ),
              ],
            ),
          ),
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
              _SettingsItem(
                icon: Icons.calendar_month_outlined,
                label: 'Calendario de pago',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const PayCalendarScreen()),
                ),
              ),
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
              _SettingsItem(
                icon: Icons.cloud_done_outlined,
                label: 'Sincronización en la nube',
                trailing: const _SyncBadge(),
                onTap: () => _showSyncInfo(context, appState.lastSyncedAt),
              ),
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
              borderRadius: BorderRadius.circular(AppRadii.card),
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
  final Widget? trailing;
  const _SettingsItem({required this.icon, required this.label, this.onTap, this.trailing});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.ink),
      title: Text(label),
      trailing: trailing ?? Icon(Icons.chevron_right, color: AppColors.slate),
      onTap: onTap ??
          () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('$label: próximamente')),
            );
          },
    );
  }
}

class _SyncBadge extends StatelessWidget {
  const _SyncBadge();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: AppColors.sage, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          'Activa',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.sage),
        ),
      ],
    );
  }
}
