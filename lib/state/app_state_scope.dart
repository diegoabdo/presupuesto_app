import 'package:flutter/widgets.dart';

import 'app_state.dart';

/// Hace que el mismo [AppState] (y sus datos ya cargados) esté disponible
/// para toda la app sin pasar el objeto manualmente pantalla por pantalla.
///
/// Uso: `AppStateScope.of(context)` dentro de cualquier build().
class AppStateScope extends InheritedNotifier<AppState> {
  const AppStateScope({
    super.key,
    required AppState appState,
    required super.child,
  }) : super(notifier: appState);

  static AppState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppStateScope>();
    assert(scope != null, 'No hay un AppStateScope en el árbol de widgets.');
    return scope!.notifier!;
  }
}
