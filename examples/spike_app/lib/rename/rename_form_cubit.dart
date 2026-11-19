import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

@immutable
class RenameFormState {
  const RenameFormState({required this.text});

  final String text;

  @override
  bool operator ==(Object other) =>
      other is RenameFormState && other.text == text;

  @override
  int get hashCode => text.hashCode;
}

abstract class RenameFormActions {
  void edit(String text);
}

class RenameFormCubit extends Cubit<RenameFormState>
    implements RenameFormActions {
  RenameFormCubit(String initial) : super(RenameFormState(text: initial));

  @override
  void edit(String text) => emit(RenameFormState(text: text));
}

@immutable
class RenameFormData {
  const RenameFormData({required this.valid});

  final bool valid;

  @override
  bool operator ==(Object other) =>
      other is RenameFormData && other.valid == valid;

  @override
  int get hashCode => valid.hashCode;
}

RenameFormData selectRenameForm(RenameFormState s) =>
    RenameFormData(valid: s.text.trim().isNotEmpty);
