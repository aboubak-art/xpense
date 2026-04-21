import 'package:flutter/material.dart';

/// Converts a hex color string to a Flutter Color.
/// Supports 6-char (#RRGGBB) and 8-char (#AARRGGBB) formats.
Color hexToColor(String hex) {
  final buffer = StringBuffer();
  if (hex.length == 6 || hex.length == 7) buffer.write('ff');
  buffer.write(hex.replaceFirst('#', ''));
  return Color(int.parse(buffer.toString(), radix: 16));
}
