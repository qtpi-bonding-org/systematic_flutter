# Flutter Color Palette

A pure, mathematical color system for Flutter with automatic theme generation and contextual theming support.

## Features

- **Pure Color Abstraction**: Uses enumerated colors (color1, color2, etc.) without UI semantics
- **Mathematical Symmetry**: Automatic luminance-based light/dark mode generation
- **Contextual Theming**: Per-tracker or per-context theme support
- **Accessibility Tools**: WCAG contrast checking and colorblind simulation
- **Lightweight Core**: Optional widget imports keep the core package minimal

## Installation

Add this to your `pubspec.yaml`:

```yaml
dependencies:
  flutter_color_palette: ^0.1.0
```

## Basic Usage

### 1. Define Your Palette

```dart
import 'package:flutter_color_palette/flutter_color_palette.dart';

// Create a palette with enumerated colors
final myPalette = AppColorPalette(
  colors: {
    'color1': Color(0xFF2196F3), // Blue
    'color2': Color(0xFF4CAF50), // Green  
    'color3': Color(0xFFFF9800), // Orange
    'neutral1': Color(0xFF212121), // Dark gray
    'neutral2': Color(0xFF757575), // Medium gray
    'neutral3': Color(0xFFF5F5F5), // Light gray
  },
  name: 'My App Theme',
);
```

### 2. Get Automatic Dark Mode

```dart
// Automatic luminance-based symmetry
final darkPalette = myPalette.symmetricPalette;

// Dark colors become light, light colors become dark
print(darkPalette.getColor('neutral1')); // Light color
print(darkPalette.getColor('neutral3')); // Dark color
```

### 3. Use with Flutter Themes

```dart
// Convert to Flutter ThemeData
final lightTheme = ThemeData(
  primarySwatch: MaterialColor(
    myPalette.getColor('color1')!.value,
    <int, Color>{
      50: myPalette.getColor('neutral3')!,
      500: myPalette.getColor('color1')!,
      900: myPalette.getColor('neutral1')!,
    },
  ),
  scaffoldBackgroundColor: myPalette.getColor('neutral3'),
  // ... map other colors
);

final darkTheme = ThemeData(
  primarySwatch: MaterialColor(
    darkPalette.getColor('color1')!.value,
    <int, Color>{
      50: darkPalette.getColor('neutral3')!,
      500: darkPalette.getColor('color1')!,
      900: darkPalette.getColor('neutral1')!,
    },
  ),
  scaffoldBackgroundColor: darkPalette.getColor('neutral3'),
  // ... map other colors
);
```

## Advanced Features

### Contextual Theming

```dart
import 'package:flutter_color_palette/flutter_color_palette.dart';

// Service for managing multiple themes
final themeService = ContextualThemeService();

// Register themes for different contexts
themeService.registerTheme('fitness', fitnessTheme);
themeService.registerTheme('productivity', productivityTheme);
themeService.registerTheme('wellness', wellnessTheme);

// Use in your app
final currentTheme = themeService.getTheme('fitness');
```

### Accessibility Testing

```dart
import 'package:flutter_color_palette/flutter_color_palette.dart';

// Check contrast ratios
final ratio = ContrastCalculator.contrastRatio(
  myPalette.getColor('color1')!,
  myPalette.getColor('neutral3')!,
);

// Get WCAG grade
final grade = ContrastCalculator.getAccessibilityGrade(
  myPalette.getColor('color1')!,
  myPalette.getColor('neutral3')!,
); // Returns 'AAA', 'AA', 'A', or 'FAIL'

// Simulate colorblindness
final protanopiaColor = ColorblindSimulator.simulateColorblindness(
  myPalette.getColor('color1')!,
  ColorblindType.protanopia,
);
```

### Visual Widgets (Optional)

Import the widgets separately to keep your core bundle lightweight:

```dart
import 'package:flutter_color_palette/widgets.dart';

// Interactive contrast matrix with colorblind modes
ContrastMatrixWidget(
  lightPalette: myPalette,
  showColorblindModes: true,  // Enable colorblind simulation modes
  showAccessibilityGrades: true,
  cellSize: 50,
)

// Interactive palette editor
PaletteEditorWidget(
  initialPalette: myPalette,
  onPaletteChanged: (newPalette) {
    // Handle palette updates
  },
)

// Dedicated colorblind accessibility testing
ColorblindMatrixWidget(
  palette: myPalette,
  showContrastMatrix: true,
)
```

### Interactive Colorblind Testing

The `ContrastMatrixWidget` now includes interactive colorblind simulation:

- **Theme Toggle**: Switch between light and dark modes
- **Vision Type Selector**: Test 8 different types of color vision deficiency
- **Real-time Contrast**: See how contrast ratios change with different vision types
- **Scientific Accuracy**: Uses Brettel-Viénot-Mollon algorithm with proper LMS color space

```dart
// Full-featured accessibility testing widget
ContrastMatrixWidget(
  lightPalette: myPalette,
  showColorblindModes: true,     // Interactive mode selection
  showAccessibilityGrades: true, // WCAG grades (AAA, AA, A, FAIL)
  cellSize: 50,
)
```

## Theme Sharing

Export and share your themes like Notion templates:

```dart
// Export theme
final export = ThemeExport.fromPalette(
  myPalette,
  metadata: {
    'author': 'Your Name',
    'category': 'productivity',
    'tags': ['minimal', 'blue', 'professional'],
  },
);

final jsonString = export.toJson();

// Import theme
final importedExport = ThemeExport.fromJson(jsonString);
final importedPalette = importedExport.toPalette();
```

## Design Philosophy

This package follows these principles:

1. **Pure Colors**: No semantic naming (primary/secondary). Use enumerated colors (color1, color2) for maximum flexibility.

2. **Mathematical Symmetry**: Dark mode is generated through luminance inversion, not manual color picking.

3. **Separation of Concerns**: Color definition is separate from UI usage. Map colors to UI elements in your theme layer.

4. **Accessibility First**: Built-in contrast checking and colorblind simulation.

5. **Lightweight Core**: Visual widgets are optional imports to keep the core package minimal.

## Examples

### Minimal 3-Color Palette

```dart
final minimal = AppColorPalette(
  colors: {
    'color1': Color(0xFF000000), // Black
    'color2': Color(0xFF808080), // Gray  
    'color3': Color(0xFFFFFFFF), // White
  },
);
```

### Rich 6-Color Palette

```dart
final rich = AppColorPalette(
  colors: {
    'color1': Color(0xFF1976D2), // Primary blue
    'color2': Color(0xFF388E3C), // Success green
    'color3': Color(0xFFF57C00), // Warning orange
    'color4': Color(0xFFD32F2F), // Error red
    'neutral1': Color(0xFF212121), // Dark
    'neutral2': Color(0xFFFAFAFA), // Light
  },
);
```

## Contributing

This package is designed for the Quanitya project but can be used in any Flutter app. Contributions welcome!

## License

MIT License - see LICENSE file for details.