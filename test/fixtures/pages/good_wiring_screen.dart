import '../stubs.dart';

class GoodWiringScreen extends StatelessWidget {
  const GoodWiringScreen();

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => const Widget()),
      ],
      child: const Widget(),
    );
  }
}
