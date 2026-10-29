import 'package:cubit_ui_flow/cubit_ui_flow.dart';

/// The text kept in an error report for [messageKey].
///
/// Only the localization key is stored. A [DataText] label carries user
/// content, which a privacy-preserving report must not keep.
String? messageText(MessageKey? messageKey) => switch (messageKey?.label) {
  L10nKey(:final key) => key,
  DataText() || null => null,
};
