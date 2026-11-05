import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import '../lint_config.dart';

/// Flags a read of the static `AppSizes` scale where the theme should supply
/// the value (`context.sizes`, `context.opacity`).
///
/// ```yaml
/// no_raw_app_sizes:
///   type_name: AppSizes         # the class to watch (default)
///   allowed_members: []         # names allowed anyway; a trailing * is a prefix
/// ```
class NoRawAppSizes extends AnalysisRule {
  static const LintCode code = LintCode(
    'no_raw_app_sizes',
    'Read this size from the theme (context.sizes, context.opacity) instead '
        'of the static AppSizes scale, so a theme override reaches it.',
  );

  NoRawAppSizes()
    : super(
        name: 'no_raw_app_sizes',
        description:
            'Flags static AppSizes reads that the theme provides through '
            'SystematicSizes and SystematicOpacity.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    if (!LintConfig.applies(context, name)) return;
    final config = LintConfig.forContext(context);
    final visitor = _Visitor(
      this,
      config.string(name, 'type_name', 'AppSizes'),
      config.list(name, 'allowed_members', const []),
    );
    registry.addPrefixedIdentifier(this, visitor);
  }
}

bool isAllowedMember(String member, List<String> allowed) => allowed.any(
  (pattern) => pattern.endsWith('*')
      ? member.startsWith(pattern.substring(0, pattern.length - 1))
      : member == pattern,
);

class _Visitor extends SimpleAstVisitor<void> {
  final AnalysisRule rule;
  final String typeName;
  final List<String> allowed;

  _Visitor(this.rule, this.typeName, this.allowed);

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    if (node.prefix.name != typeName) return;
    if (isAllowedMember(node.identifier.name, allowed)) return;
    rule.reportAtNode(node);
  }
}
