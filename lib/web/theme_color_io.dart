import 'package:flutter/material.dart';

/// No-op fuera de web: en móvil/desktop nativo el color de fondo del
/// sistema se maneja con SystemChrome, no hay un <body> que teñir.
void syncWebChromeColor(Color color) {}
