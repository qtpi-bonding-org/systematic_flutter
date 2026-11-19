import 'package:flutter_test/flutter_test.dart';
import 'package:spike_app/flow/flow_cubit.dart';
import 'package:spike_app/notes/notes_cubit.dart';
import 'package:spike_app/rename/rename_form_cubit.dart';
import 'package:spike_app/search/search_cubit.dart';
import 'package:spike_app/status/status_cubit.dart';
import 'package:spike_app/tabs/tabs_cubit.dart';
import 'package:spike_app/views/confirm_dialog_view.dart';
import 'package:spike_app/views/tag_chip.dart';
import 'package:spike_app/views/workspace_switch_view.dart';

/// Exhaustive: adding a variant to [NoteListData] stops this compiling until
/// the new variant is named here (and then added to [allNoteListVariants]).
String noteListVariant(NoteListData d) => switch (d) {
      NoteListLoading() => 'loading',
      NoteListFailed() => 'failed',
      NoteListLoaded() => 'loaded',
    };

const allNoteListVariants = {'loading', 'failed', 'loaded'};

void main() {
  test('NoteListData.samples covers every status variant', () {
    final covered = {
      for (final s in NoteListData.samples().values) noteListVariant(s),
    };
    expect(covered, allNoteListVariants);
  });

  test('NoteListData.samples names loading, error, empty and full', () {
    expect(NoteListData.samples().keys,
        containsAll(['loading', 'error', 'empty', 'full']));
    expect(noteListVariant(NoteListData.samples()['empty']!), 'loaded');
  });

  test('every ViewData has non-empty samples with a default or named states',
      () {
    final all = <String, Map<String, Object>>{
      'NoteTileData': NoteTileData.samples(),
      'NoteListData': NoteListData.samples(),
      'TabStripData': TabStripData.samples(),
      'SearchPanelData': SearchPanelData.samples(),
      'StatusData': StatusData.samples(),
      'WorkspaceSwitchData': WorkspaceSwitchData.samples(),
      'RenameFormData': RenameFormData.samples(),
      'FlowNameData': FlowNameData.samples(),
      'ConfirmDialogData': ConfirmDialogData.samples(),
      'TagChipData': TagChipData.samples(),
    };
    for (final e in all.entries) {
      expect(e.value, isNotEmpty, reason: e.key);
    }
  });

  test('NoteTileData.samples include default, selected and long title', () {
    final s = NoteTileData.samples();
    expect(s.keys, containsAll(['default', 'selected', 'long title']));
    expect(s['selected']!.selected, isTrue);
    expect(s['default']!.selected, isFalse);
    expect(s['long title']!.title.length,
        greaterThan(s['default']!.title.length * 3));
  });

  test('flat ViewData samples differ from each other', () {
    for (final samples in <Map<String, Object>>[
      SearchPanelData.samples(),
      RenameFormData.samples(),
      TabStripData.samples(),
    ]) {
      expect(samples.values.toSet().length, samples.length);
    }
  });
}
