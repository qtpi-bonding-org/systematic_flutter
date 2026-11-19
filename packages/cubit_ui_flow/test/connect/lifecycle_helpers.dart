import 'dart:async';

import 'package:cubit_ui_flow/cubit_ui_flow.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Cubit that counts live stream listeners.
class CountingCubit extends Cubit<int> {
  CountingCubit([super.initial = 0]);
  int listeners = 0;

  @override
  Stream<int> get stream => Stream<int>.multi((c) {
        listeners++;
        final sub = super.stream.listen(c.add);
        c.onCancel = () {
          listeners--;
          return sub.cancel();
        };
      }, isBroadcast: true);
}

class HolderScope extends AppScope {
  HolderScope(this.cubit);
  final CountingCubit cubit;
}

int ident(int s) => s;
int doubled(int s) => s * 2;
int sumAB(int a, int b) => a + b;
int prodAB(int a, int b) => a * b;
int plusArg(int s, int arg) => s + arg;
int timesArg(int s, int arg) => s * arg;
