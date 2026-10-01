import 'dart:html' as html;

import 'package:flutter/material.dart';

/// Sincroniza el fondo real de <html>/<body> y el meta theme-color con el
/// color que Flutter ya está pintando. Hace falta porque el <style> estático
/// de index.html solo cubre el color inicial (según prefers-color-scheme del
/// sistema); si el usuario cambia el tema dentro de la app sin que coincida
/// con el modo del sistema, esto evita que la franja de arriba (detrás del
/// status bar/notch) se quede con el color equivocado.
void syncWebChromeColor(Color color) {
  final hex = '#${(color.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';
  html.document.documentElement?.style.backgroundColor = hex;
  html.document.body?.style.backgroundColor = hex;
  html.document.querySelector('meta[name="theme-color"]')?.setAttribute('content', hex);
}
