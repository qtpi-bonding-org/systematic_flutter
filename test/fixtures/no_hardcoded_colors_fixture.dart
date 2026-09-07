import 'stubs.dart';

class GoodWidget extends StatelessWidget {
  const GoodWidget();

  @override
  Widget build(BuildContext context) {
    return const Widget();
  }
}

class BadColorConstructor extends StatelessWidget {
  const BadColorConstructor();

  @override
  Widget build(BuildContext context) {
    return Color(0xFF00FF00);
  }
}

class BadColorsStatic extends StatelessWidget {
  const BadColorsStatic();

  @override
  Widget build(BuildContext context) {
    return Colors.red;
  }
}

class BadAppPaletteStatic extends StatelessWidget {
  const BadAppPaletteStatic();

  @override
  Widget build(BuildContext context) {
    return AppPalette.red;
  }
}
