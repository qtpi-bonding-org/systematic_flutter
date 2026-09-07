import 'stubs.dart';

// Allowed: SizedBox(height:/width:) inside the token classes themselves.
// Named differently from stubs.dart's own VSpace/HSpace (which this file
// also imports) to avoid a duplicate-declaration error -- the rule only
// matches on class-name text, so which name is used here doesn't matter,
// as long as the test's allowedEnclosingClasses list matches it.
class _LocalVSpace {
  _LocalVSpace._();
  static SizedBox get x1 => SizedBox(height: 8);
}

class _LocalHSpace {
  _LocalHSpace._();
  static SizedBox get x1 => SizedBox(width: 8);
}

// Allowed: a SizedBox with neither height nor width (sizing a child, not
// spacing) is not this rule's concern.
class GoodBoxedChild extends StatelessWidget {
  const GoodBoxedChild();

  @override
  Widget build(BuildContext context) {
    return SizedBox(child: const Widget());
  }
}

// Not allowed: a raw spacing SizedBox outside VSpace/HSpace.
class BadInlineSpacer extends StatelessWidget {
  const BadInlineSpacer();

  @override
  Widget build(BuildContext context) {
    return SizedBox(height: 16);
  }
}
