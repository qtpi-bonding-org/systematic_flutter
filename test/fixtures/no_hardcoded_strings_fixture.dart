import 'stubs.dart';

class GoodText extends StatelessWidget {
  const GoodText();

  @override
  Widget build(BuildContext context) {
    return Text(MessageKey.greeting);
  }
}

class BadText extends StatelessWidget {
  const BadText();

  @override
  Widget build(BuildContext context) {
    return Text('Hello there');
  }
}
