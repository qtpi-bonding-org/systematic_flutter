// GENERATED CODE - DO NOT MODIFY BY HAND
// Generator: l10n_generator

import 'package:l10n_key_resolver/runtime.dart';
import 'app_localizations.dart';

/// Resolves [Label]s to text for the locale of the wrapped
/// [AppLocalizations].
///
/// An unknown key calls [onUnknownKey]; debug builds and tests
/// then throw, release builds show the key text.
class L10nKeyResolver implements LabelResolver {
  final AppLocalizations _l10n;
  final UnknownKeyHandler? onUnknownKey;

  const L10nKeyResolver(this._l10n, {this.onUnknownKey});

  @override
  String resolve(Label label) => switch (label) {
        DataText(:final value) => value,
        L10nKey(:final key, :final args) => _byKey(key, args),
      };

  String _byKey(String key, Map<String, Object> args) {
    return switch (key) {
      'action.back' => _l10n.actionBack,
      'action.cancel' => _l10n.actionCancel,
      'action.next' => _l10n.actionNext,
      'action.save' => _l10n.actionSave,
      'app.title' => _l10n.appTitle,
      'confirm.delete.note' => _l10n.confirmDeleteNote(args['title'] as String),
      'confirm.no' => _l10n.confirmNo,
      'confirm.yes' => _l10n.confirmYes,
      'error.generic' => _l10n.errorGeneric,
      'name.label' => _l10n.nameLabel,
      'note.delete' => _l10n.noteDelete,
      'note.deleted' => _l10n.noteDeleted,
      'note.rename' => _l10n.noteRename,
      'note.rename.title' => _l10n.noteRenameTitle,
      'note.renamed' => _l10n.noteRenamed,
      'notes.empty' => _l10n.notesEmpty,
      'notes.loading' => _l10n.notesLoading,
      'notes.retry' => _l10n.notesRetry,
      'notes.unavailable' => _l10n.notesUnavailable,
      'review.title' => _l10n.reviewTitle,
      'search.hint.active' => _l10n.searchHintActive,
      'search.hint.empty' => _l10n.searchHintEmpty,
      'start.flow' => _l10n.startFlow,
      'start.title' => _l10n.startTitle,
      'status.offline' => _l10n.statusOffline,
      'status.online' => _l10n.statusOnline,
      'status.tick' => _l10n.statusTick(args['count'] as int),
      'tab.new' => _l10n.tabNew,
      'tab.number' => _l10n.tabNumber(args['number'] as int),
      _ => _unknown(key),
    };
  }

  String _unknown(String key) {
    onUnknownKey?.call(key);
    var isDebug = false;
    assert(isDebug = true);
    if (isDebug) throw StateError('Unknown l10n key: $key');
    return key;
  }

  /// Every key this resolver knows.
  static const knownKeys = <String>{
    'action.back',
    'action.cancel',
    'action.next',
    'action.save',
    'app.title',
    'confirm.delete.note',
    'confirm.no',
    'confirm.yes',
    'error.generic',
    'name.label',
    'note.delete',
    'note.deleted',
    'note.rename',
    'note.rename.title',
    'note.renamed',
    'notes.empty',
    'notes.loading',
    'notes.retry',
    'notes.unavailable',
    'review.title',
    'search.hint.active',
    'search.hint.empty',
    'start.flow',
    'start.title',
    'status.offline',
    'status.online',
    'status.tick',
    'tab.new',
    'tab.number',
  };

  static bool hasKey(String key) => knownKeys.contains(key);

  /// ARB camelCase key to dot-notation key.
  static const arbToDotKey = <String, String>{
    'actionBack': 'action.back',
    'actionCancel': 'action.cancel',
    'actionNext': 'action.next',
    'actionSave': 'action.save',
    'appTitle': 'app.title',
    'confirmDeleteNote': 'confirm.delete.note',
    'confirmNo': 'confirm.no',
    'confirmYes': 'confirm.yes',
    'errorGeneric': 'error.generic',
    'nameLabel': 'name.label',
    'noteDelete': 'note.delete',
    'noteDeleted': 'note.deleted',
    'noteRename': 'note.rename',
    'noteRenameTitle': 'note.rename.title',
    'noteRenamed': 'note.renamed',
    'notesEmpty': 'notes.empty',
    'notesLoading': 'notes.loading',
    'notesRetry': 'notes.retry',
    'notesUnavailable': 'notes.unavailable',
    'reviewTitle': 'review.title',
    'searchHintActive': 'search.hint.active',
    'searchHintEmpty': 'search.hint.empty',
    'startFlow': 'start.flow',
    'startTitle': 'start.title',
    'statusOffline': 'status.offline',
    'statusOnline': 'status.online',
    'statusTick': 'status.tick',
    'tabNew': 'tab.new',
    'tabNumber': 'tab.number',
  };

  /// Dot-notation key to ARB camelCase key.
  static const dotToArbKey = <String, String>{
    'action.back': 'actionBack',
    'action.cancel': 'actionCancel',
    'action.next': 'actionNext',
    'action.save': 'actionSave',
    'app.title': 'appTitle',
    'confirm.delete.note': 'confirmDeleteNote',
    'confirm.no': 'confirmNo',
    'confirm.yes': 'confirmYes',
    'error.generic': 'errorGeneric',
    'name.label': 'nameLabel',
    'note.delete': 'noteDelete',
    'note.deleted': 'noteDeleted',
    'note.rename': 'noteRename',
    'note.rename.title': 'noteRenameTitle',
    'note.renamed': 'noteRenamed',
    'notes.empty': 'notesEmpty',
    'notes.loading': 'notesLoading',
    'notes.retry': 'notesRetry',
    'notes.unavailable': 'notesUnavailable',
    'review.title': 'reviewTitle',
    'search.hint.active': 'searchHintActive',
    'search.hint.empty': 'searchHintEmpty',
    'start.flow': 'startFlow',
    'start.title': 'startTitle',
    'status.offline': 'statusOffline',
    'status.online': 'statusOnline',
    'status.tick': 'statusTick',
    'tab.new': 'tabNew',
    'tab.number': 'tabNumber',
  };
}

/// The only source of [L10nKey]s.
///
/// Plain keys are const; parameterized keys are methods, so they
/// cannot be used in a const context.
abstract final class L10nKeys {
  static const actionBack = L10nKey.generated('action.back');
  static const actionCancel = L10nKey.generated('action.cancel');
  static const actionNext = L10nKey.generated('action.next');
  static const actionSave = L10nKey.generated('action.save');
  static const appTitle = L10nKey.generated('app.title');
  static L10nKey confirmDeleteNote({required String title}) => L10nKey.generated('confirm.delete.note', {'title': title});
  static const confirmNo = L10nKey.generated('confirm.no');
  static const confirmYes = L10nKey.generated('confirm.yes');
  static const errorGeneric = L10nKey.generated('error.generic');
  static const nameLabel = L10nKey.generated('name.label');
  static const noteDelete = L10nKey.generated('note.delete');
  static const noteDeleted = L10nKey.generated('note.deleted');
  static const noteRename = L10nKey.generated('note.rename');
  static const noteRenameTitle = L10nKey.generated('note.rename.title');
  static const noteRenamed = L10nKey.generated('note.renamed');
  static const notesEmpty = L10nKey.generated('notes.empty');
  static const notesLoading = L10nKey.generated('notes.loading');
  static const notesRetry = L10nKey.generated('notes.retry');
  static const notesUnavailable = L10nKey.generated('notes.unavailable');
  static const reviewTitle = L10nKey.generated('review.title');
  static const searchHintActive = L10nKey.generated('search.hint.active');
  static const searchHintEmpty = L10nKey.generated('search.hint.empty');
  static const startFlow = L10nKey.generated('start.flow');
  static const startTitle = L10nKey.generated('start.title');
  static const statusOffline = L10nKey.generated('status.offline');
  static const statusOnline = L10nKey.generated('status.online');
  static L10nKey statusTick({required int count}) => L10nKey.generated('status.tick', {'count': count});
  static const tabNew = L10nKey.generated('tab.new');
  static L10nKey tabNumber({required int number}) => L10nKey.generated('tab.number', {'number': number});
}
