import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

@immutable
class StatusState {
  const StatusState({required this.tick, required this.online});

  final int tick;
  final bool online;

  @override
  bool operator ==(Object other) =>
      other is StatusState && other.tick == tick && other.online == online;

  @override
  int get hashCode => Object.hash(tick, online);
}

class StatusCubit extends Cubit<StatusState> {
  StatusCubit({Duration interval = const Duration(seconds: 1)})
      : super(const StatusState(tick: 0, online: true)) {
    _ticker = Stream<int>.periodic(interval, (i) => i).listen((_) {
      emit(StatusState(tick: state.tick + 1, online: state.online));
    });
  }

  late final StreamSubscription<int> _ticker;

  Future<void> setOnline(bool online) async {
    emit(StatusState(tick: state.tick, online: online));
  }

  @override
  Future<void> close() async {
    await _ticker.cancel();
    await super.close();
  }
}

/// What the status line shows.
@immutable
class StatusData {
  const StatusData({required this.tick});

  final int tick;

  static Map<String, StatusData> samples() => const {
        'tick 0': StatusData(tick: 0),
        'tick 42': StatusData(tick: 42),
        'tick big': StatusData(tick: 1234),
      };

  @override
  bool operator ==(Object other) =>
      other is StatusData && other.tick == tick;

  @override
  int get hashCode => tick.hashCode;
}

int selectTick(StatusState s) => s.tick;
