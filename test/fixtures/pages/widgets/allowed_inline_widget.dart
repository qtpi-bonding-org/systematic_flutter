import '../../stubs.dart';

// This class is named "...Screen" on purpose -- the directory exemption,
// not the class-name check, is what must keep this file clean.
class NotReallyAScreen extends StatelessWidget {
  const NotReallyAScreen();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(AppSizes.space),
      child: Text('built here on purpose'),
    );
  }
}
