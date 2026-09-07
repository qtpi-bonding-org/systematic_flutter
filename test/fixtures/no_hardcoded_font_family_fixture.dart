import 'stubs.dart';

class GoodStyle {
  const GoodStyle();

  TextStyle build() => TextStyle(fontFamily: AppFonts.mono);
}

class BadStyle {
  const BadStyle();

  TextStyle build() => TextStyle(fontFamily: 'Comic Sans');
}
