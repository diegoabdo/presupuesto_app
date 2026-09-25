/// Error que viene de la API (credenciales inválidas, validación, red, etc.)
/// con un mensaje ya listo para mostrar en pantalla.
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}
