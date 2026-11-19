import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

@immutable
class FlowState {
  const FlowState({required this.name});

  final String name;

  @override
  bool operator ==(Object other) => other is FlowState && other.name == name;

  @override
  int get hashCode => name.hashCode;
}

abstract class FlowActions {
  void setName(String name);
}

class FlowCubit extends Cubit<FlowState> implements FlowActions {
  FlowCubit() : super(const FlowState(name: ''));

  @override
  void setName(String name) => emit(FlowState(name: name));
}

/// The name shown by the start and confirm steps.
@immutable
class FlowNameData {
  const FlowNameData({required this.name});

  final String name;

  static Map<String, FlowNameData> samples() => const {
        'empty': FlowNameData(name: ''),
        'short': FlowNameData(name: 'Ann'),
        'long': FlowNameData(name: 'Maximilian Alexander the Third'),
      };

  @override
  bool operator ==(Object other) =>
      other is FlowNameData && other.name == name;

  @override
  int get hashCode => name.hashCode;
}

FlowNameData selectFlowName(FlowState s) => FlowNameData(name: s.name);
