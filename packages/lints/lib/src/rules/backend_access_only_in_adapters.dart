import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
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

  /// [compositionRootPaths], when given, replaces the `composition_root_paths`
  /// option (a seam for tests, which cannot read `lint_config.yaml`).
  BackendAccessOnlyInAdapters({List<String>? compositionRootPaths})
    : _compositionRootPaths = compositionRootPaths,
      super(
        name: 'backend_access_only_in_adapters',
        description:
            'Flags context.read/watch/select, scope lookups, bloc widgets, '
            'cubit, scope and data-layer types in views, GetIt anywhere in '
            'widgets, and cubit/scope values a view gets without a '
            'BuildContext (locals, call or property targets) plus top-level '
            'functions and getters returning them outside adapter helpers.',
      );

  final List<String>? _compositionRootPaths;

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
        _compositionRootPaths ??
            config.list(name, 'composition_root_paths', const []),
        path,
        context.package?.root.path,
      ),
    );
    registry
      ..addMethodInvocation(this, visitor)
      ..addInstanceCreationExpression(this, visitor)
      ..addNamedType(this, visitor)
      ..addSimpleIdentifier(this, visitor)
      ..addPropertyAccess(this, visitor)
      ..addPrefixedIdentifier(this, visitor)
      ..addVariableDeclaration(this, visitor)
      ..addFunctionDeclaration(this, visitor)
      ..addTopLevelVariableDeclaration(this, visitor);
  }
}

/// [adapter] and [unchecked] are exempt from the view rules. [view] flags
/// everything. [plain] (a non-widget, non-adapter, non-backend class) flags
/// only bloc and scope types in its field declarations.
enum _Scope { unchecked, plain, view, adapter }

class _Visitor extends SimpleAstVisitor<void> {
  _Visitor(this.rule, {required this.dataPaths, required this.compositionRoot});

  final AnalysisRule rule;
  final List<String> dataPaths;

  /// Whether the file is a composition root: everything declared in it is
  /// exempt (widgets, States, closures, top-level functions), GetIt included.
  final bool compositionRoot;

  /// Offsets of the NamedTypes already reported, so a type that is both a
  /// GetIt type and a banned site is reported once.
  final Set<int> _reportedTypes = {};

  /// `offset:length` of every node already reported, so one node reached
  /// from two checks (a context call that is also a banned-typed target) is
  /// reported once.
  final Set<String> _reportedNodes = {};

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
  static const _adapterHelperNames = {'adapterHelper', 'AdapterHelper'};
  static const _getItNames = {'GetIt', 'getIt'};

  @override
  void visitMethodInvocation(MethodInvocation node) {
    final name = node.methodName.name;
    final target = node.target;
    final isContextCall =
        _contextMethods.contains(name) &&
        (isBuildContextType(node.realTarget?.staticType) ||
            (target == null && _isInBuildContextExtension(node)));
    final isLookup =
        target != null &&
        _scopeLookups.contains('${_targetClassName(target)}.$name');
    if (isContextCall || isLookup) _flagInView(node);
    _checkBackendValue(node.realTarget);
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    if (!_bannedCreations.contains(node.constructorName.type.name.lexeme)) {
      return;
    }
    _flagInView(node);
  }

  @override
  void visitPropertyAccess(PropertyAccess node) {
    _checkBackendValue(node.realTarget);
  }

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    _checkBackendValue(node.prefix);
  }

  @override
  void visitVariableDeclaration(VariableDeclaration node) {
    final init = node.initializer;
    if (init is MethodInvocation ||
        init is FunctionExpressionInvocation ||
        init is PropertyAccess ||
        init is PrefixedIdentifier ||
        init is SimpleIdentifier) {
      _checkBackendValue(init);
    }
  }

  /// Reports [node] once, whichever check reached it first.
  void _report(AstNode node) {
    if (_reportedNodes.add('${node.offset}:${node.length}')) {
      rule.reportAtNode(node);
    }
  }

  /// Reports [node] when it sits in a view.
  void _flagInView(AstNode node) {
    if (_scopeOf(node) == _Scope.view) _report(node);
  }

  /// Flags [expr] when it is a banned-typed backend value used in a view
  /// without a BuildContext. Only the innermost banned value is reported: if
  /// its own target or prefix is banned too, that one gets reported instead
  /// (`appScope.notes.rename()` reports `appScope`).
  void _checkBackendValue(Expression? expr) {
    if (expr == null) return;
    if (!_containsType(expr.staticType, _isSupertypeBanned)) return;
    final inner = _innerValue(expr);
    if (inner != null && _containsType(inner.staticType, _isSupertypeBanned)) {
      return;
    }
    _flagInView(expr);
  }

  /// The expression [expr] reads its value from, when it has one.
  static Expression? _innerValue(Expression expr) => switch (expr) {
    MethodInvocation() => expr.realTarget,
    PropertyAccess() => expr.realTarget,
    PrefixedIdentifier() => expr.prefix,
    _ => null,
  };

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    if (compositionRoot || node.parent is! CompilationUnit) return;
    final isHelper = node.metadata.any(
      (a) => _adapterHelperNames.contains(_lastName(a.name)),
    );
    if (isHelper) return;
    final returnType = node.declaredFragment?.element.returnType;
    if (!_containsType(returnType, _isSupertypeBanned)) return;
    // A declared return type in a view is already reported by visitNamedType.
    if (node.returnType != null &&
        _topLevelFunctionScope(node) == _Scope.view) {
      return;
    }
    rule.reportAtToken(node.name);
  }

  @override
  void visitNamedType(NamedType node) {
    final scope = _scopeOf(node);
    final isGetIt =
        node.name.lexeme == 'GetIt' || node.type?.element?.name == 'GetIt';
    if (isGetIt) {
      if (_isGetItScope(scope) && _reportedTypes.add(node.offset)) {
        rule.reportAtToken(node.name);
      }
      return;
    }
    if (scope == _Scope.view) {
      if (_isTypeSite(node) && _isBannedType(node.type)) _report(node);
    } else if (scope == _Scope.plain) {
      if (_isInFieldType(node) && _isSupertypeBanned(node.type)) _report(node);
    }
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    if (!_isGetItIdentifier(node)) return;
    if (node.inDeclarationContext()) return;
    if (_isGetItScope(_scopeOf(node))) _report(node);
  }

  @override
  void visitTopLevelVariableDeclaration(TopLevelVariableDeclaration node) {
    if (compositionRoot) return;
    for (final variable in node.variables.variables) {
      final type = variable.declaredFragment?.element.type;
      if (_containsType(type, _isSupertypeBanned)) {
        rule.reportAtToken(variable.name);
      }
    }
  }

  static bool _isGetItScope(_Scope scope) =>
      scope == _Scope.view || scope == _Scope.adapter;

  /// The class name a lookup target refers to. A typedef resolves to the
  /// class it aliases; otherwise the syntactic name is used.
  static String _targetClassName(Expression target) {
    final identifier = switch (target) {
      SimpleIdentifier() => target,
      PrefixedIdentifier() => target.identifier,
      _ => null,
    };
    if (identifier == null) return '';
    final element = identifier.element;
    if (element is TypeAliasElement) {
      return element.aliasedType.element?.name ?? identifier.name;
    }
    return identifier.name;
  }

  /// True for `GetIt` and `getIt` by name, or for a typedef whose aliased
  /// class is GetIt.
  static bool _isGetItIdentifier(SimpleIdentifier node) {
    if (_getItNames.contains(node.name)) return true;
    final element = node.element;
    return element is TypeAliasElement &&
        element.aliasedType.element?.name == 'GetIt';
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

  /// Whether [node] is a part of a type annotation that a type site can
  /// contain. Formal parameters count only when [parameters] is true (field
  /// types that hold a function type).
  static bool _isTypePart(AstNode node, {required bool parameters}) =>
      node is TypeArgumentList ||
      node is NamedType ||
      node is GenericFunctionType ||
      node is RecordTypeAnnotation ||
      node is RecordTypeAnnotationPositionalField ||
      node is RecordTypeAnnotationNamedField ||
      node is RecordTypeAnnotationNamedFields ||
      (parameters && (node is FormalParameterList || node is FormalParameter));

  /// Whether [node] is the type of a declaration or expression that counts
  /// as a site: a field, a parameter, a return type, a cast, an `is` test or
  /// a pattern. Constructor names, method type arguments and local variable
  /// types are not sites.
  static bool _isTypeSite(NamedType node) {
    AstNode child = node;
    AstNode? parent = node.parent;
    while (parent != null && _isTypePart(parent, parameters: false)) {
      child = parent;
      parent = parent.parent;
    }
    if (parent == null) return false;
    if (parent is VariableDeclarationList) {
      return parent.parent is FieldDeclaration;
    }
    if (parent is FormalParameter) return true;
    if (parent is MethodDeclaration) return parent.returnType == child;
    if (parent is FunctionDeclaration) return parent.returnType == child;
    return parent is AsExpression ||
        parent is IsExpression ||
        parent is DeclaredVariablePattern ||
        parent is ObjectPattern ||
        parent is CastPattern;
  }

  /// Whether [node] is part of a field's declared type, through any function
  /// or record type pieces.
  static bool _isInFieldType(NamedType node) {
    AstNode? parent = node.parent;
    while (parent != null && _isTypePart(parent, parameters: true)) {
      parent = parent.parent;
    }
    return parent is VariableDeclarationList &&
        parent.parent is FieldDeclaration;
  }

  /// Whether [type] is a banned backend type: a bloc, cubit or scope, or a
  /// type declared under a data path.
  bool _isBannedType(DartType? type) {
    if (_isSupertypeBanned(type)) return true;
    if (type == null) return false;
    final path = type.element?.library?.firstFragment.source.fullName;
    if (path == null) return false;
    return dataPaths.any(path.contains);
  }

  static bool _isSupertypeBanned(DartType? type) =>
      type != null &&
      _bannedSupertypes.any((name) => hasNamedSupertype(type, name));

  /// Whether [type], or any type nested in it (type arguments, function
  /// parameter and return types, record fields), satisfies [test].
  static bool _containsType(DartType? type, bool Function(DartType) test) {
    if (type == null) return false;
    if (test(type)) return true;
    if (type is InterfaceType) {
      return type.typeArguments.any((t) => _containsType(t, test));
    }
    if (type is FunctionType) {
      return _containsType(type.returnType, test) ||
          type.formalParameters.any((p) => _containsType(p.type, test));
    }
    if (type is RecordType) {
      return type.positionalFields.any((f) => _containsType(f.type, test)) ||
          type.namedFields.any((f) => _containsType(f.type, test));
    }
    return false;
  }

  /// The scope of the nearest enclosing class, extension or top-level
  /// function, or [_Scope.unchecked] when none of them is a checked context.
  _Scope _scopeOf(AstNode node) {
    if (compositionRoot) return _Scope.unchecked;
    for (AstNode? n = node.parent; n != null; n = n.parent) {
      if (n is ClassDeclaration) return _classScope(n);
      if (n is ExtensionDeclaration) {
        return isBuildContextType(n.onClause?.extendedType.type)
            ? _Scope.view
            : _Scope.unchecked;
      }
      if (n is FunctionDeclaration && n.parent is CompilationUnit) {
        return _topLevelFunctionScope(n);
      }
    }
    return _Scope.unchecked;
  }

  _Scope _topLevelFunctionScope(FunctionDeclaration node) {
    final isHelper = node.metadata.any(
      (a) => _adapterHelperNames.contains(_lastName(a.name)),
    );
    if (isHelper) return _Scope.adapter;
    if (isWidgetType(node.returnType?.type)) return _Scope.view;
    final parameters =
        node.functionExpression.parameters?.parameters ?? const [];
    final takesContext = parameters.any(
      (p) => isBuildContextType(p.declaredFragment?.element.type),
    );
    return takesContext ? _Scope.view : _Scope.unchecked;
  }

  final Map<ClassDeclaration, _Scope> _classScopes = {};

  _Scope _classScope(ClassDeclaration node) =>
      _classScopes.putIfAbsent(node, () => _computeClassScope(node));

  _Scope _computeClassScope(ClassDeclaration node) {
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
    if (isWidgetType(type)) return _Scope.view;
    if (_isSupertypeBanned(type)) return _Scope.unchecked;
    // Adapter-side helpers: an `@adapterHelper` class, or a keybinding
    // `Action` that adapters provide. Services stay plain.
    final isHelper = node.metadata.any(
      (a) => _adapterHelperNames.contains(_lastName(a.name)),
    );
    if (isHelper || hasNamedSupertype(type, 'Action')) return _Scope.adapter;
    return _Scope.plain;
  }

  static String _lastName(Identifier id) =>
      id is PrefixedIdentifier ? id.identifier.name : id.name;
}
