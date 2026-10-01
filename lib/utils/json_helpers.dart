/// Convierte un valor JSON a double, aceptando tanto números como texto.
///
/// Laravel serializa los atributos con cast `decimal:N` como STRING
/// (ej. "50.00") cuando el modelo se devuelve "a pelo" (sin pasar por un
/// API Resource que lo convierta a float explícitamente) — es un
/// comportamiento conocido de Eloquent para no perder precisión. Como no
/// todos los endpoints usan un Resource, el cliente acepta ambas formas
/// en vez de asumir una sola.
double jsonToDouble(dynamic value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.parse(value);
  throw FormatException('Valor numérico inválido: $value');
}

/// Como [jsonToDouble], pero deja pasar null (ej. un presupuesto "sin límite").
double? jsonToDoubleOrNull(dynamic value) => value == null ? null : jsonToDouble(value);
