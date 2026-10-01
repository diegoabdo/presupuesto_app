import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Controla el modo de tema (claro/oscuro/según el sistema) y lo persiste
/// en el dispositivo para que se recuerde entre sesiones.
class ThemeController extends ChangeNotifier {
  ThemeController._();
  static final ThemeController instance = ThemeController._();

  static const _storage = FlutterSecureStorage();
  static const _key = 'theme_mode';

  ThemeMode mode = ThemeMode.system;

  Future<void> load() async {
    final saved = await _storage.read(key: _key);
    mode = switch (saved) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
    notifyListeners();
  }

  Future<void> setMode(ThemeMode newMode) async {
    if (mode == newMode) return;
    mode = newMode;
    notifyListeners();
    await _storage.write(key: _key, value: newMode.name);
  }
}
