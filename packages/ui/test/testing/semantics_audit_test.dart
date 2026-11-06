import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:systematic_ui/testing.dart';

void main() {
  testWidgets('finds an unlabeled GestureDetector control', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      GestureDetector(
        onTap: () {},
        child: const SizedBox(width: 100, height: 100),
      ),
    );

    expect(auditUnlabeledControls(tester), hasLength(1));
    handle.dispose();
  });

  testWidgets('accepts a labeled tappable Semantics wrapper', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Semantics(
          label: 'Open',
          button: true,
          onTap: () {},
          child: const SizedBox(width: 100, height: 100),
        ),
      ),
    );

    expect(auditUnlabeledControls(tester), isEmpty);
    handle.dispose();
  });
}
