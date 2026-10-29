import 'package:flutter/material.dart';
import 'package:flutter_color_palette/flutter_color_palette.dart';

class ThemeService extends ChangeNotifier {
  ThemeService(
      {required IColorPalette lightPalette, IColorPalette? darkPalette})
      : _lightPalette = lightPalette,
        _darkPalette = darkPalette;

  final IColorPalette _lightPalette;
  final IColorPalette? _darkPalette;
  bool _isDarkMode = false;
  final Map<String, Color> _overrides = {};

  bool get isDarkMode => _isDarkMode;

  Map<String, Color> get overrides => Map.unmodifiable(_overrides);

  IColorPalette get currentPalette {
    final base = _isDarkMode ? (_darkPalette ?? _lightPalette) : _lightPalette;
    if (_overrides.isEmpty) return base;
    return AppColorPalette(
      colors: {...base.colors, ..._overrides},
      name: base.name,
    );
  }

  void toggleDarkMode() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  void setDarkMode(bool isDark) {
    if (_isDarkMode == isDark) return;
    _isDarkMode = isDark;
    notifyListeners();
  }

  void setOverride(String key, Color value) {
    _overrides[key] = value;
    notifyListeners();
  }

  void clearOverrides() {
    if (_overrides.isEmpty) return;
    _overrides.clear();
    notifyListeners();
  }
}
