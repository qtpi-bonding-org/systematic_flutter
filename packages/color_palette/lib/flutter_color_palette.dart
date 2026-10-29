/// A pure, mathematical color system for Flutter with automatic theme generation.
///
/// This library provides:
/// - Pure color abstraction without UI semantics
/// - Automatic luminance-based theme generation
/// - Contextual theming support
/// - Mathematical color symmetry for light/dark modes
library flutter_color_palette;

// Core Interfaces
export 'src/interfaces/color_palette.dart';
export 'src/interfaces/theme_service.dart';

// Implementations
export 'src/implementations/app_color_palette.dart';
export 'src/implementations/contextual_theme_service.dart';

// Utilities
export 'src/utils/luminance_calculator.dart';
export 'src/utils/contrast_calculator.dart';
export 'src/utils/colorblind_simulator.dart';
export 'src/utils/color_extensions.dart';

// Models
export 'src/models/theme_export.dart';