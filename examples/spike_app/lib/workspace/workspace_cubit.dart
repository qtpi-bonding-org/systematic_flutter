import 'package:flutter_bloc/flutter_bloc.dart';

abstract class WorkspaceActions {
  void switchTo(String id);
}

class WorkspaceCubit extends Cubit<String> implements WorkspaceActions {
  WorkspaceCubit() : super('A');

  @override
  void switchTo(String id) => emit(id);
}

String selectWorkspaceId(String s) => s;
