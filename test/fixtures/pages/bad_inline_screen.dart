import '../stubs.dart';

class BadInlineScreen extends StatelessWidget {
  const BadInlineScreen();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(AppSizes.space),
      child: Text('hi'),
    );
  }
}
