import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_lint_generator/src/rules/no_hardcoded_strings.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NoHardcodedStringsTest);
  });
}

@reflectiveTest
class NoHardcodedStringsTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = NoHardcodedStrings();
    super.setUp();
  }

  Future<void> test_flags_string_literal_in_Text() async {
    await assertDiagnostics(
      r'''
class Text {
  Text(String data);
}

class MessageKey {
  MessageKey._();
  static const greeting = 'greeting';
}

final good = Text(MessageKey.greeting);
final bad = Text('Hello there');
''',
      [lint(172, 13)],
    );
  }
}
