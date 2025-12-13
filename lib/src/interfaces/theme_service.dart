import 'dart:async';
import 'color_palette.dart';

/// Service for managing contextual themes and palette switching.
/// 
/// Supports both global theme management and context-specific theming
/// (e.g., different themes for different app sections or entities).
abstract class IThemeService {
  /// Sets the global theme palette.
  void setGlobalTheme(IColorPalette palette);
  
  /// Sets a context-specific theme palette.
  /// 
  /// [contextId] - Unique identifier for the context (e.g., tracker ID)
  /// [palette] - The palette to use for this context
  void setContextTheme(String contextId, IColorPalette palette);
  
  /// Removes a context-specific theme, falling back to global.
  void removeContextTheme(String contextId);
  
  /// Enters a specific context, switching to its theme if available.
  /// 
  /// If no theme is set for this context, continues using current theme.
  void enterContext(String contextId);
  
  /// Exits the current context, reverting to global theme.
  void exitContext();
  
  /// Gets the currently active palette.
  IColorPalette getCurrentPalette();
  
  /// Stream of palette changes for reactive UI updates.
  Stream<IColorPalette> get paletteStream;
  
  /// Current context ID, if any.
  String? get currentContext;
}