import 'package:flutter/material.dart';
import 'package:qtpi_ui/qtpi_ui.dart';
import 'device_preset.dart';

/// What the engine needs from a theme, with nothing app-specific. Backed by the
/// Project-1 [ThemeService] (color overrides + dark mode are already built).
abstract interface class ThemeController implements Listenable {
  Map<String, Color> get tokens;
  String get paletteName;
  void setToken(String key, Color value);
  void reset();
  bool get isDark;
  set isDark(bool value);
  DevicePreset? get devicePreset;
  set devicePreset(DevicePreset? value);
}

/// Adapter composing the real [ThemeService] (color + dark) with a selected
/// [DevicePreset]. The preset is applied to [UiScaler] by the DeviceFrame
/// widget (which owns a BuildContext); this controller only holds state.
class StorybookThemeController extends ChangeNotifier
    implements ThemeController {
  StorybookThemeController(this._theme) {
    _theme.addListener(notifyListeners);
  }

  final ThemeService _theme;
  DevicePreset? _preset;

  @override
  Map<String, Color> get tokens => _theme.currentPalette.colors;

  @override
  String get paletteName => _theme.currentPalette.name ?? '';

  @override
  void setToken(String key, Color value) => _theme.setOverride(key, value);

  @override
  void reset() => _theme.clearOverrides();

  @override
  bool get isDark => _theme.isDarkMode;

  @override
  set isDark(bool value) => _theme.setDarkMode(value);

  @override
  DevicePreset? get devicePreset => _preset;

  @override
  set devicePreset(DevicePreset? value) {
    _preset = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _theme.removeListener(notifyListeners);
    super.dispose();
  }
}
