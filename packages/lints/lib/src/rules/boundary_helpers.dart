import 'package:analyzer/dart/element/type.dart';
import 'package:glob/glob.dart';
import 'package:path/path.dart' as p;

import 'failure_helpers.dart';

/// Base classes whose subclasses are adapters. Matched by name.
const adapterBaseNames = {
  'AdapterWidget',
  'StatefulAdapterWidget',
  'CubitAdapter',
  'MultiCubitAdapter',
};

/// True if [type] is an adapter class (itself or a subtype of one of
/// [adapterBaseNames]).
bool isAdapterType(DartType? type) =>
    adapterBaseNames.any((name) => hasNamedSupertype(type, name));

/// True if [type] is a Widget subtype (or the Widget itself).
bool isWidgetType(DartType? type) => hasNamedSupertype(type, 'Widget');

/// True if [type] is BuildContext, by name.
bool isBuildContextType(DartType? type) =>
    hasNamedSupertype(type, 'BuildContext');

/// The `State<X>` supertype of [type], or null when [type] is not a State.
InterfaceType? stateSupertype(InterfaceType type) {
  for (final supertype in type.allSupertypes) {
    if (supertype.element.name == 'State') return supertype;
  }
  return null;
}

/// Whether [path] (absolute) matches any of [patterns]. A pattern matches
/// as a glob against the package-relative path, or as a plain substring of
/// the absolute path.
bool pathMatchesAny(List<String> patterns, String path, String? packageRoot) {
  if (patterns.isEmpty) return false;
  final relative = packageRoot == null
      ? null
      : p.relative(path, from: packageRoot).replaceAll(r'\', '/');
  for (final pattern in patterns) {
    if (relative != null && Glob(pattern).matches(relative)) return true;
    if (path.contains(pattern)) return true;
  }
  return false;
}
