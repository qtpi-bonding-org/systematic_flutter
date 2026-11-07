import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/type.dart';

/// Matches by element name intentionally: tests and clients may define their
/// own failure bases. The library URI is not constrained.
bool hasNamedSupertype(DartType? type, String name) {
  if (type is! InterfaceType) return false;
  return <InterfaceType>[
    type,
    ...type.allSupertypes,
  ].any((candidate) => candidate.element.name == name);
}

bool isCoreType(DartType? type, String name) {
  if (type is! InterfaceType) return false;
  return <InterfaceType>[type, ...type.allSupertypes].any((candidate) {
    final element = candidate.element;
    return element.library.uri.toString() == 'dart:core' &&
        element.name == name;
  });
}

bool isException(DartType? type) => isCoreType(type, 'Exception');
bool isError(DartType? type) => isCoreType(type, 'Error');
bool isFailure(DartType? type) =>
    hasNamedSupertype(type, 'DomainException') ||
    hasNamedSupertype(type, 'EnvironmentException');

bool isCatchVariable(String name, AstNode node) {
  for (AstNode? parent = node.parent; parent != null; parent = parent.parent) {
    if (parent is CatchClause) {
      return parent.exceptionParameter?.name == name;
    }
  }
  return false;
}
