import 'package:cubit_ui_flow/cubit_ui_flow.dart';
import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../l10n/l10n_key_resolver.g.dart';

/// Resolves labels through the generated keys once the locale is known.
///
/// The app's builder calls [update] with the current [AppLocalizations] and
/// returns this same instance, so a LabelScope holding it does not re-notify.
class AppLabelResolver implements LabelResolver {
  L10nKeyResolver? _resolver;

  AppLabelResolver update(AppLocalizations l10n) {
    _resolver = L10nKeyResolver(l10n);
    return this;
  }

  @override
  String resolve(Label label) {
    final resolver = _resolver;
    if (resolver == null) {
      throw StateError(
        'AppLabelResolver.update was never called; wrap the app in LabelScope.',
      );
    }
    return resolver.resolve(label);
  }
}

/// Shows toasts through a ScaffoldMessenger, replacing any toast on screen.
class SnackBarFeedback implements IFeedbackService {
  SnackBarFeedback(this._messenger);

  final GlobalKey<ScaffoldMessengerState> _messenger;

  @override
  void show(FeedbackMessage message) {
    final state = _messenger.currentState;
    if (state == null) return;
    state
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message.message)));
  }
}

/// The spike shows no loading overlay.
class NoLoading implements ILoadingService {
  const NoLoading();

  @override
  void show() {}

  @override
  void hide() {}
}
