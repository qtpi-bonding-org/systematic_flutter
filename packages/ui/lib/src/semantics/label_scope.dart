import 'package:flutter/widgets.dart';
import 'package:l10n_key_resolver/runtime.dart';

/// Supplies the [LabelResolver] for the current locale to everything below it.
///
/// Put one above the app's `MaterialApp`/`WidgetsApp` content and give it a new
/// resolver when the locale changes: widgets that read it rebuild, so spoken
/// labels follow the language.
class LabelScope extends InheritedWidget {
  const LabelScope({super.key, required this.resolver, required super.child});

  final LabelResolver resolver;

  /// The resolver, registering [context] to rebuild when it changes.
  static LabelResolver of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<LabelScope>();
    if (scope == null) {
      throw StateError(
        'No LabelScope above this widget. Wrap the app in LabelScope(resolver: '
        'L10nKeyResolver(AppLocalizations.of(context)), ...).',
      );
    }
    return scope.resolver;
  }

  @override
  bool updateShouldNotify(LabelScope oldWidget) =>
      !identical(resolver, oldWidget.resolver);
}

extension LabelContext on BuildContext {
  /// [label] as text for the current locale.
  String resolveLabel(Label label) => LabelScope.of(this).resolve(label);
}
