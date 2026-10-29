import 'dart:async';
import '../interfaces/color_palette.dart';
import '../interfaces/theme_service.dart';

/// Implementation of IThemeService that supports contextual theming.
/// 
/// Manages both global themes and context-specific themes (e.g., per-tracker themes).
/// Automatically switches themes when entering/exiting contexts.
class ContextualThemeService implements IThemeService {
  IColorPalette _globalPalette;
  final Map<String, IColorPalette> _contextPalettes = {};
  String? _currentContextId;
  
  final StreamController<IColorPalette> _paletteController = StreamController<IColorPalette>.broadcast();
  
  /// Creates a new contextual theme service with the given global palette.
  ContextualThemeService(this._globalPalette);
  
  @override
  void setGlobalTheme(IColorPalette palette) {
    _globalPalette = palette;
    
    // If no context is active, update immediately
    if (_currentContextId == null) {
      _notifyPaletteChange(palette);
    }
  }
  
  @override
  void setContextTheme(String contextId, IColorPalette palette) {
    _contextPalettes[contextId] = palette;
    
    // If this is the current context, update immediately
    if (_currentContextId == contextId) {
      _notifyPaletteChange(palette);
    }
  }
  
  @override
  void removeContextTheme(String contextId) {
    _contextPalettes.remove(contextId);
    
    // If this was the current context, fall back to global
    if (_currentContextId == contextId) {
      _notifyPaletteChange(_globalPalette);
    }
  }
  
  @override
  void enterContext(String contextId) {
    _currentContextId = contextId;
    
    // Use context palette if available, otherwise global
    final palette = _contextPalettes[contextId] ?? _globalPalette;
    _notifyPaletteChange(palette);
  }
  
  @override
  void exitContext() {
    _currentContextId = null;
    _notifyPaletteChange(_globalPalette);
  }
  
  @override
  IColorPalette getCurrentPalette() {
    if (_currentContextId != null) {
      return _contextPalettes[_currentContextId!] ?? _globalPalette;
    }
    return _globalPalette;
  }
  
  @override
  Stream<IColorPalette> get paletteStream => _paletteController.stream;
  
  @override
  String? get currentContext => _currentContextId;
  
  /// Notifies listeners of palette changes.
  void _notifyPaletteChange(IColorPalette palette) {
    _paletteController.add(palette);
  }
  
  /// Disposes of the service and closes streams.
  void dispose() {
    _paletteController.close();
  }
}