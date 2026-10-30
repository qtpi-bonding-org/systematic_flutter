import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:systematic_lints/src/rules/no_hardcoded_strings.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NoHardcodedStringsTest);
    defineReflectiveTests(NoHardcodedStringsArgumentsTest);
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

@reflectiveTest
class NoHardcodedStringsArgumentsTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = NoHardcodedStrings();
    super.setUp();
  }

  static const _prelude = r'''
class Tooltip {
  Tooltip({String? message, String? tooltip});
}

class Field {
  Field({String? hintText, String? label});
}

class MessageKey {
  MessageKey._();
  static const greeting = 'greeting';
}
''';

  Future<void> test_flags_literal_in_text_argument() async {
    const literal = "'Close'";
    const source = '$_prelude\nfinal bad = Tooltip(tooltip: $literal);\n';
    await assertDiagnostics(source, [
      lint(source.indexOf(literal), literal.length),
    ]);
  }

  Future<void> test_flags_label_and_hint_text() async {
    const hint = "'Search'";
    const label = "'Name'";
    const source = '$_prelude\nfinal bad = Field(hintText: $hint, label: $label);\n';
    await assertDiagnostics(source, [
      lint(source.indexOf(hint), hint.length),
      lint(source.indexOf(label), label.length),
    ]);
  }

  Future<void> test_allows_a_key_in_a_text_argument() async {
    await assertNoDiagnostics('$_prelude\nfinal good = Tooltip(tooltip: MessageKey.greeting);\n');
  }

  Future<void> test_allows_a_literal_without_letters() async {
    await assertNoDiagnostics("$_prelude\nfinal good = Field(label: '•', hintText: '');\n");
  }

  Future<void> test_ignores_other_named_arguments() async {
    await assertNoDiagnostics("$_prelude\nfinal good = Tooltip(message: 'not in the list');\n");
  }
}
