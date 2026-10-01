import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import 'api_exception.dart';

/// Dónde vive tu API de Laravel.
///
/// Por defecto (sin pasar nada) apunta a tu backend local, para que
/// `flutter run` funcione sin configuración extra:
/// - Android (emulador):      http://10.0.2.2:8000/api
///   (10.0.2.2 es cómo el emulador de Android ve a "localhost" de tu PC)
/// - Web / Chrome / PWA / Windows: http://127.0.0.1:8000/api
/// - Dispositivo físico (celular real en la misma red Wi-Fi que tu PC):
///   http://TU_IP_LOCAL:8000/api  (ej. http://192.168.1.50:8000/api)
///   Corre `php artisan serve --host=0.0.0.0` para que la API escuche
///   en toda la red, no solo en 127.0.0.1.
///
/// Para el build que se despliega (Vercel), pasa la URL de producción en
/// tiempo de compilación en vez de editar este archivo:
///   flutter build web --dart-define=API_BASE_URL=https://presupuesto-api-fndjceg7b5guasab.northcentralus-01.azurewebsites.net/api
class ApiConfig {
  ApiConfig._();

  static String baseUrl = _defaultBaseUrl();

  static String _defaultBaseUrl() {
    const override = String.fromEnvironment('API_BASE_URL');
    if (override.isNotEmpty) return override;

    if (kIsWeb) return 'http://127.0.0.1:8000/api';
    try {
      if (Platform.isAndroid) return 'http://10.0.2.2:8000/api';
    } catch (_) {
      // Platform no disponible en este target; usar el valor por defecto.
    }
    return 'http://127.0.0.1:8000/api';
  }
}

/// Cliente HTTP delgado: agrega la URL base, el header de autorización
/// (Bearer token) y decodifica JSON. Todas las llamadas a la API pasan
/// por aquí.
class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  static const _storage = FlutterSecureStorage();
  static const _tokenKey = 'auth_token';

  String? _cachedToken;

  Future<String?> get token async {
    _cachedToken ??= await _storage.read(key: _tokenKey);
    return _cachedToken;
  }

  Future<void> saveToken(String token) async {
    _cachedToken = token;
    await _storage.write(key: _tokenKey, value: token);
  }

  Future<void> clearToken() async {
    _cachedToken = null;
    await _storage.delete(key: _tokenKey);
  }

  Future<bool> get hasToken async => (await token) != null;

  Uri _uri(String path) => Uri.parse('${ApiConfig.baseUrl}$path');

  Future<Map<String, String>> _headers({bool auth = true}) async {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (auth) {
      final t = await token;
      if (t != null) headers['Authorization'] = 'Bearer $t';
    }
    return headers;
  }

  dynamic _decode(http.Response response) {
    if (response.statusCode == 204 || response.body.isEmpty) return null;
    return jsonDecode(utf8.decode(response.bodyBytes));
  }

  Never _throwForResponse(http.Response response) {
    String message = 'Ocurrió un error (${response.statusCode}).';
    try {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (body is Map && body['message'] is String) {
        message = body['message'] as String;
      }
      if (body is Map && body['errors'] is Map) {
        final errors = (body['errors'] as Map).values
            .expand((v) => v is List ? v : [v])
            .map((e) => e.toString())
            .join('\n');
        if (errors.isNotEmpty) message = errors;
      }
    } catch (_) {
      // Respuesta sin JSON (ej. error 500 con HTML); nos quedamos con el
      // mensaje genérico de arriba.
    }
    throw ApiException(message, statusCode: response.statusCode);
  }

  T _handle<T>(http.Response response, T Function(dynamic json) onOk) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return onOk(_decode(response));
    }
    _throwForResponse(response);
  }

  Future<T> get<T>(String path, T Function(dynamic json) onOk) async {
    final response = await http
        .get(_uri(path), headers: await _headers())
        .catchError((e) => throw ApiException('No se pudo conectar con el servidor: $e'));
    return _handle(response, onOk);
  }

  Future<T> post<T>(
    String path,
    Map<String, dynamic> body,
    T Function(dynamic json) onOk, {
    bool auth = true,
  }) async {
    final response = await http
        .post(_uri(path), headers: await _headers(auth: auth), body: jsonEncode(body))
        .catchError((e) => throw ApiException('No se pudo conectar con el servidor: $e'));
    return _handle(response, onOk);
  }

  Future<T> put<T>(
    String path,
    Map<String, dynamic> body,
    T Function(dynamic json) onOk,
  ) async {
    final response = await http
        .put(_uri(path), headers: await _headers(), body: jsonEncode(body))
        .catchError((e) => throw ApiException('No se pudo conectar con el servidor: $e'));
    return _handle(response, onOk);
  }

  Future<void> delete(String path) async {
    final response = await http
        .delete(_uri(path), headers: await _headers())
        .catchError((e) => throw ApiException('No se pudo conectar con el servidor: $e'));
    _handle(response, (_) => null);
  }

  /// Como [delete], pero para los pocos endpoints (ej. borrar un aporte)
  /// que devuelven el recurso padre ya actualizado en vez de 204 vacío.
  Future<T> deleteWithResult<T>(String path, T Function(dynamic json) onOk) async {
    final response = await http
        .delete(_uri(path), headers: await _headers())
        .catchError((e) => throw ApiException('No se pudo conectar con el servidor: $e'));
    return _handle(response, onOk);
  }
}
