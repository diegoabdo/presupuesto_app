import 'package:flutter/material.dart';

/// Fila simple estilo "libro mayor": etiqueta a la izquierda, monto a la
/// derecha, sin tarjeta ni sombra. Se usa en vez de repetir el mismo
/// componente de tarjeta redondeada en toda la app.
class LedgerRow extends StatelessWidget {
  final String label;
  final String? sublabel;
  final String trailing;
  final Color? trailingColor;
  final VoidCallback? onTap;

  const LedgerRow({
    super.key,
    required this.label,
    this.sublabel,
    required this.trailing,
    this.trailingColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: theme.textTheme.bodyLarge),
                  if (sublabel != null) ...[
                    const SizedBox(height: 2),
                    Text(sublabel!, style: theme.textTheme.bodyMedium),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              trailing,
              style: theme.textTheme.titleLarge?.copyWith(
                color: trailingColor ?? theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
