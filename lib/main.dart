import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'screens/budget_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/income_screen.dart';
import 'screens/login_screen.dart';
import 'screens/savings_screen.dart';
import 'screens/settings_screen.dart';
import 'services/auth_service.dart';
import 'state/app_state.dart';
import 'state/app_state_scope.dart';
import 'state/theme_controller.dart';
import 'theme/app_theme.dart';
import 'web/theme_color.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es', null);
  await ThemeController.instance.load();
  runApp(const PresupuestoApp());
}

/// El AppStateScope debe envolver TODO MaterialApp (y por lo tanto su
/// Navigator), no solo la pantalla inicial. Si solo envolviera a AuthGate,
/// cualquier pantalla abierta con Navigator.push (como "Nuevo gasto") quedaría
/// fuera de su alcance, porque esas rutas se insertan en el Navigator de
/// MaterialApp, que vive por encima de AuthGate en el árbol de widgets.
class PresupuestoApp extends StatefulWidget {
  const PresupuestoApp({super.key});

  @override
  State<PresupuestoApp> createState() => _PresupuestoAppState();
}

class _PresupuestoAppState extends State<PresupuestoApp> {
  final _appState = AppState();

  @override
  Widget build(BuildContext context) {
    return AppStateScope(
      appState: _appState,
      child: ListenableBuilder(
        listenable: ThemeController.instance,
        builder: (context, _) {
          return MaterialApp(
            title: 'Mi Presupuesto',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: ThemeController.instance.mode,
            // AppColors se sincroniza aquí (antes de construir la pantalla)
            // con el brillo que Flutter ya resolvió para este frame, así
            // los widgets que usan AppColors.xxx directamente (en vez de
            // Theme.of(context)) también responden al modo oscuro.
            //
            // También recoloreamos la barra de estado del sistema aquí: sin
            // esto, al cambiar a oscuro la franja de arriba (detrás del
            // notch/dynamic island) se queda con el color claro de fondo
            // porque el so nunca se entera de que el tema cambió.
            builder: (context, child) {
              final brightness = Theme.of(context).brightness;
              AppColors.syncWithBrightness(brightness);
              syncWebChromeColor(AppColors.paper);
              final iconBrightness = brightness == Brightness.dark ? Brightness.light : Brightness.dark;
              SystemChrome.setSystemUIOverlayStyle(
                SystemUiOverlayStyle(
                  statusBarColor: Colors.transparent,
                  statusBarIconBrightness: iconBrightness,
                  statusBarBrightness: brightness,
                  systemNavigationBarColor: AppColors.paper,
                  systemNavigationBarIconBrightness: iconBrightness,
                ),
              );
              return child!;
            },
            home: AuthGate(appState: _appState),
          );
        },
      ),
    );
  }
}

/// Decide si mostrar el login o la app, revisando si ya hay un token
/// guardado en el dispositivo de una sesión anterior.
class AuthGate extends StatefulWidget {
  final AppState appState;
  const AuthGate({super.key, required this.appState});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _checking = true;
  bool _loggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    final loggedIn = await AuthService.instance.isLoggedIn;
    if (loggedIn) {
      await widget.appState.loadAll();
    }
    if (!mounted) return;
    setState(() {
      _loggedIn = loggedIn;
      _checking = false;
    });
  }

  Future<void> _onLoginSuccess() async {
    setState(() => _checking = true);
    await widget.appState.loadAll();
    if (!mounted) return;
    setState(() {
      _loggedIn = true;
      _checking = false;
    });
  }

  void _onLoggedOut() {
    widget.appState.reset();
    setState(() => _loggedIn = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return Scaffold(
        backgroundColor: AppColors.paper,
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (!_loggedIn) {
      return LoginScreen(onSuccess: _onLoginSuccess);
    }
    return AppShell(onLoggedOut: _onLoggedOut);
  }
}

class AppShell extends StatefulWidget {
  final VoidCallback onLoggedOut;
  const AppShell({super.key, required this.onLoggedOut});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  late final _screens = [
    const DashboardScreen(),
    const IncomeScreen(),
    const BudgetScreen(),
    const SavingsScreen(),
    SettingsScreen(onLoggedOut: widget.onLoggedOut),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      // SafeArea(top: false) + un poco de padding extra: sin esto, en un
      // teléfono con home indicator (o incluso sin él) la barra queda
      // pegada justo al borde y se siente aplastada contra la pantalla.
      bottomNavigationBar: SafeArea(
        top: false,
        minimum: const EdgeInsets.only(bottom: 8),
        child: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet),
            label: 'Ingresos',
          ),
          NavigationDestination(
            icon: Icon(Icons.pie_chart_outline),
            selectedIcon: Icon(Icons.pie_chart),
            label: 'Gastos',
          ),
          NavigationDestination(
            icon: Icon(Icons.savings_outlined),
            selectedIcon: Icon(Icons.savings),
            label: 'Capital',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Ajustes',
          ),
        ],
        ),
      ),
    );
  }
}
