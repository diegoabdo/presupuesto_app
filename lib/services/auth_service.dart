import 'api_client.dart';

class AuthUser {
  final String id;
  final String name;
  final String email;

  const AuthUser({required this.id, required this.name, required this.email});

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
        id: json['id'].toString(),
        name: json['name'] as String,
        email: json['email'] as String,
      );
}

/// Registro, inicio y cierre de sesión contra /api/register, /api/login,
/// /api/logout. El token que devuelve el backend se guarda de forma segura
/// en el dispositivo (flutter_secure_storage) para no pedir login cada vez.
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  final _client = ApiClient.instance;

  Future<bool> get isLoggedIn => _client.hasToken;

  /// Trae el usuario de la sesión actual (GET /me). Se usa para saludar
  /// por su nombre real, incluso cuando la sesión se restauró desde el
  /// token guardado (sin pasar por login() en este arranque de la app).
  Future<AuthUser> me() {
    return _client.get<AuthUser>(
      '/me',
      (json) => AuthUser.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<AuthUser> login({required String email, required String password}) async {
    final json = await _client.post<Map<String, dynamic>>(
      '/login',
      {
        'email': email,
        'password': password,
        'device_name': 'flutter-app',
      },
      (json) => json as Map<String, dynamic>,
      auth: false,
    );
    await _client.saveToken(json['token'] as String);
    return AuthUser.fromJson(json['user'] as Map<String, dynamic>);
  }

  Future<AuthUser> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final json = await _client.post<Map<String, dynamic>>(
      '/register',
      {
        'name': name,
        'email': email,
        'password': password,
        'password_confirmation': password,
      },
      (json) => json as Map<String, dynamic>,
      auth: false,
    );
    await _client.saveToken(json['token'] as String);
    return AuthUser.fromJson(json['user'] as Map<String, dynamic>);
  }

  /// Cierra sesión solo en este dispositivo (revoca únicamente este token).
  Future<void> logout() async {
    try {
      await _client.post('/logout', {}, (_) => null);
    } catch (_) {
      // Si ya no hay conexión o el token expiró, igual limpiamos localmente.
    } finally {
      await _client.clearToken();
    }
  }
}
