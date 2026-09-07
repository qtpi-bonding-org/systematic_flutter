// Minimal stand-ins for the Flutter API surface the lint rules touch,
// so fixtures resolve without a Flutter SDK dependency. These are not
// meant to run -- only to parse and resolve.

class Widget {
  const Widget();
}

class BuildContext {}

abstract class StatelessWidget extends Widget {
  const StatelessWidget();
  Widget build(BuildContext context);
}

class Color extends Widget {
  Color(int value);
}

class Colors {
  Colors._();
  static final red = Color(0xFFFF0000);
}

class TextStyle {
  TextStyle({double? fontSize, String? fontFamily});
}

class EdgeInsets {
  EdgeInsets.all(double value);
  EdgeInsets.only({
    double left = 0,
    double top = 0,
    double right = 0,
    double bottom = 0,
  });
  EdgeInsets.symmetric({double horizontal = 0, double vertical = 0});
}

class SizedBox extends Widget {
  SizedBox({double? width, double? height, Widget? child});
}

class Padding extends Widget {
  Padding({required EdgeInsets padding, required Widget child});
}

class Column extends Widget {
  Column({List<Widget> children = const []});
}

class Text extends Widget {
  Text(String data, {TextStyle? style});
}

// Design-system tokens, matching pocketcoder's real ones.

class AppPalette {
  AppPalette._();
  static final red = Color(0xFFFF0000);
}

class AppFonts {
  AppFonts._();
  static const mono = 'NotoSansMono';
}

class AppSizes {
  AppSizes._();
  static const double space = 8;
}

class MessageKey {
  MessageKey._();
  static const greeting = 'greeting';
}

class VSpace {
  VSpace._();
  static SizedBox get x1 => SizedBox(height: 8);
}

class HSpace {
  HSpace._();
  static SizedBox get x1 => SizedBox(width: 8);
}

// Provider/DI wiring widgets, for the inline-widget-composition rule.

class MultiBlocProvider extends Widget {
  MultiBlocProvider({required List<Widget> providers, required Widget child});
}

class BlocProvider extends Widget {
  BlocProvider({required Widget Function(BuildContext) create});
}
