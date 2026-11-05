import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import '../lint_config.dart';

/// Flags construction of types a repo has decided not to use, for a design
/// choice the plugin cannot know (every corner a squircle, no stock dialogs).
/// The list is the repo's: with none configured the rule does nothing.
///
/// ```yaml
/// no_banned_constructors:
///   banned: [RoundedRectangleBorder, BorderRadius.circular]
/// ```
/// An entry is a type name (`RoundedRectangleBorder`, every constructor) or
/// `Type.constructor` (`BorderRadius.circular`).
class NoBannedConstructors extends AnalysisRule {
  static const LintCode code = LintCode(
    'no_banned_constructors',
    'This type is banned in this repo (see no_banned_constructors in '
        'lint_config.yaml). Use the design-system replacement.',
  );

  /// [banned] overrides the configured list (for tests).
  NoBannedConstructors({List<String>? banned})
    : _banned = banned,
      super(
        name: 'no_banned_constructors',
        description:
            'Flags construction of types the repo bans in lint_config.yaml.',
      );

  final List<String>? _banned;

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    if (!LintConfig.applies(context, name)) return;
    final banned =
        _banned ??
        LintConfig.forContext(context).list(name, 'banned', const []);
    if (banned.isEmpty) return;
    registry.addInstanceCreationExpression(this, _Visitor(this, banned));
  }
}

bool isBannedConstruction(
  String type,
  String? constructor,
  List<String> banned,
) =>
    banned.contains(type) ||
    (constructor != null && banned.contains('$type.$constructor'));

class _Visitor extends SimpleAstVisitor<void> {
  final AnalysisRule rule;
  final List<String> banned;

  _Visitor(this.rule, this.banned);

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    final name = node.constructorName;
    if (isBannedConstruction(name.type.name.lexeme, name.name?.name, banned)) {
      rule.reportAtNode(node);
    }
  }
}
