import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';

import '../lint_config.dart';
import 'boundary_helpers.dart';
import 'failure_helpers.dart';

/// Views (non-adapter widgets, their States, BuildContext extensions and
/// top-level Widget-returning functions) must reach backend state only
/// through an adapter. GetIt is banned in every widget, adapters included.
class BackendAccessOnlyInAdapters extends AnalysisRule {
  static const LintCode code = LintCode(
    'backend_access_only_in_adapters',
    'Views must reach backend state only through an adapter.',
  );

  BackendAccessOnlyInAdapters()
    : super(
        name: 'backend_access_only_in_adapters',
        description:
            'Flags context.read/watch/select, scope lookups, bloc widgets, '
            'cubit, scope and data-layer types in views, and GetIt anywhere '
            'in widgets.',
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
    final path =
        context.currentUnit?.file.path ?? context.definingUnit.file.path;
    final visitor = _Visitor(
      this,
      dataPaths: config.list(name, 'data_paths', const [
        '/lib/data/',
        '/lib/infrastructure/',
      ]),
      compositionRoot: pathMatchesAny(
        config.list(name, 'composition_root_paths', const []),
        path,
        context.package?.root.path,
      ),
    );
    registry
      ..addMethodInvocation(this, visitor)
      ..addInstanceCreationExpression(this, visitor)
      ..addFieldDeclaration(this, visitor)
      ..addRegularFormalParameter(this, visitor)
      ..addFieldFormalParameter(this, visitor)
      ..addAsExpression(this, visitor)
      ..addNamedType(this, visitor)
      ..addSimpleIdentifier(this, visitor);
  }
}

enum _Scope { unchecked, view, adapter }

class _Visitor extends SimpleAstVisitor<void> {
  _Visitor(this.rule, {required this.dataPaths, required this.compositionRoot});

  final AnalysisRule rule;
  final List<String> dataPaths;

  /// Whether the file is a composition root: its top-level widget functions
  /// are exempt, GetIt included.
  final bool compositionRoot;

  static const _contextMethods = {'read', 'watch', 'select'};
  static const _scopeLookups = {
    'Provider.of',
    'BlocProvider.of',
    'RepositoryProvider.of',
    'ScopeProvider.of',
    'ScopeProvider.maybeOf',
  };
  static const _bannedCreations = {
    'BlocBuilder',
    'BlocListener',
    'BlocConsumer',
    'BlocSelector',
    'BlocProvider',
    'MultiBlocProvider',
    'RepositoryProvider',
    'UiFlowListener',
    'UiFlowStateListener',
    'Connect',
    'Connect2',
    'ConnectFor',
  };
  static const _bannedSupertypes = ['BlocBase', 'Cubit', 'Bloc', 'AppScope'];

  @override
  void visitMethodInvocation(MethodInvocation node) {
    final name = node.methodName.name;
    final target = node.target;
    final isContextCall =
        _contextMethods.contains(name) &&
        (isBuildContextType(node.realTarget?.staticType) ||
            (target == null && _isInBuildContextExtension(node)));
    final isLookup =
        target is SimpleIdentifier &&
        _scopeLookups.contains('${target.name}.$name');
    if (!isContextCall && !isLookup) return;
    if (_scopeOf(node) == _Scope.view) rule.reportAtNode(node);
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    if (!_bannedCreations.contains(node.constructorName.type.name.lexeme)) {
      return;
    }
    if (_scopeOf(node) == _Scope.view) rule.reportAtNode(node);
  }

  @override
  void visitFieldDeclaration(FieldDeclaration node) {
    final type = node.fields.type;
    if (type is NamedType) _checkDeclaredType(type, node);
  }

  @override
  void visitRegularFormalParameter(RegularFormalParameter node) {
    _checkParameter(node);
  }

  @override
  void visitFieldFormalParameter(FieldFormalParameter node) {
    _checkParameter(node);
  }

  void _checkParameter(FormalParameter node) {
    final type = node.type;
    if (type is NamedType) _checkDeclaredType(type, node);
  }

  @override
  void visitAsExpression(AsExpression node) {
    final type = node.type;
    if (type is NamedType) _checkDeclaredType(type, node);
  }

  @override
  void visitNamedType(NamedType node) {
    if (node.name.lexeme != 'GetIt') return;
    if (_scopeOf(node) != _Scope.unchecked) rule.reportAtToken(node.name);
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    final name = node.name;
    if (name != 'GetIt' && name != 'getIt') return;
    if (node.inDeclarationContext()) return;
    if (_scopeOf(node) != _Scope.unchecked) rule.reportAtNode(node);
  }

  /// Whether [node] sits directly inside an extension on BuildContext, so an
  /// implicit-this `read`/`watch`/`select` call there is a context call. The
  /// nearest enclosing extension or class decides; a class in between breaks
  /// the match.
  bool _isInBuildContextExtension(AstNode node) {
    for (AstNode? n = node.parent; n != null; n = n.parent) {
      if (n is ExtensionDeclaration) {
        return isBuildContextType(n.onClause?.extendedType.type);
      }
      if (n is ClassDeclaration) return false;
    }
    return false;
  }

  /// Reports [type] when [site] is inside a view and the type is a banned
  /// backend type.
  void _checkDeclaredType(NamedType type, AstNode site) {
    if (_scopeOf(site) != _Scope.view) return;
    if (_isBannedType(type.type)) rule.reportAtNode(type);
  }

  bool _isBannedType(DartType? type) {
    if (type == null) return false;
    if (_bannedSupertypes.any((name) => hasNamedSupertype(type, name))) {
      return true;
    }
    final path = type.element?.library?.firstFragment.source.fullName;
    if (path == null) return false;
    return dataPaths.any(path.contains);
  }

  /// The scope of the nearest enclosing class, extension or top-level
  /// function, or [_Scope.unchecked] when none of them is a checked context.
  _Scope _scopeOf(AstNode node) {
    for (AstNode? n = node.parent; n != null; n = n.parent) {
      if (n is ClassDeclaration) return _classScope(n);
      if (n is ExtensionDeclaration) {
        return isBuildContextType(n.onClause?.extendedType.type)
            ? _Scope.view
            : _Scope.unchecked;
      }
      if (n is FunctionDeclaration && n.parent is CompilationUnit) {
        if (compositionRoot || !isWidgetType(n.returnType?.type)) {
          return _Scope.unchecked;
        }
        return _Scope.view;
      }
    }
    return _Scope.unchecked;
  }

  _Scope _classScope(ClassDeclaration node) {
    final type = node.declaredFragment?.element.thisType;
    if (type == null) return _Scope.unchecked;
    if (isAdapterType(type)) return _Scope.adapter;
    final state = stateSupertype(type);
    if (state != null) {
      final args = state.typeArguments;
      return args.isNotEmpty && isAdapterType(args.first)
          ? _Scope.adapter
          : _Scope.view;
    }
    return isWidgetType(type) ? _Scope.view : _Scope.unchecked;
  }
}
