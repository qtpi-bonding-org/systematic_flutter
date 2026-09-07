import 'stubs.dart';

class GoodPadding extends StatelessWidget {
  const GoodPadding();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(AppSizes.space),
      child: const Widget(),
    );
  }
}

class GoodScaledPadding extends StatelessWidget {
  const GoodScaledPadding();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppSizes.space * 2),
      child: const Widget(),
    );
  }
}

class BadRawPadding extends StatelessWidget {
  const BadRawPadding();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(16),
      child: const Widget(),
    );
  }
}

class BadRawOnlyPadding extends StatelessWidget {
  const BadRawOnlyPadding();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 4, bottom: 8),
      child: const Widget(),
    );
  }
}
