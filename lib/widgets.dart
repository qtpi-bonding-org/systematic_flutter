/// Optional widgets for visualizing and editing color palettes.
/// 
/// This is a separate import to keep the core library lightweight.
/// Only import this if you need the visual editing widgets.
library flutter_color_palette_widgets;

// Export the visual widgets
export 'src/widgets/contrast_matrix_widget.dart';
export 'src/widgets/colorblind_matrix_widget.dart';
export 'src/widgets/palette_editor_widget.dart';
export 'src/widgets/color_picker_widget.dart';
export 'src/widgets/palette_demo_widget.dart';