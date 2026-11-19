// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Notes';

  @override
  String tabNumber(int number) {
    return 'Tab $number';
  }

  @override
  String get tabNew => 'New tab';

  @override
  String get noteRename => 'Rename';

  @override
  String get noteDelete => 'Delete';

  @override
  String get noteRenameTitle => 'Rename note';

  @override
  String get noteRenamed => 'Note renamed';

  @override
  String get noteDeleted => 'Note deleted';

  @override
  String get notesLoading => 'Loading notes';

  @override
  String get notesEmpty => 'No notes yet';

  @override
  String get notesRetry => 'Retry';

  @override
  String get notesUnavailable => 'Notes are unavailable right now';

  @override
  String get errorGeneric => 'Something went wrong';

  @override
  String confirmDeleteNote(String title) {
    return 'Delete \"$title\"?';
  }

  @override
  String get confirmYes => 'Yes';

  @override
  String get confirmNo => 'No';

  @override
  String get actionSave => 'Save';

  @override
  String get actionCancel => 'Cancel';

  @override
  String get actionNext => 'Next';

  @override
  String get actionBack => 'Back';

  @override
  String get searchHintEmpty => 'Type to search';

  @override
  String get searchHintActive => 'Searching notes';

  @override
  String get statusOnline => 'Online';

  @override
  String get statusOffline => 'Offline';

  @override
  String statusTick(int count) {
    return 'Tick $count';
  }

  @override
  String get startFlow => 'Start flow';

  @override
  String get startTitle => 'Start';

  @override
  String get reviewTitle => 'Review';

  @override
  String get nameLabel => 'Name';
}
