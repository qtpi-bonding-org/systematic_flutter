import 'stubs.dart';

class GoodStyle {
  const GoodStyle();

  TextStyle build() => TextStyle();
}

class BadStyle {
  const BadStyle();

  TextStyle build() => TextStyle(fontSize: 14);
}
