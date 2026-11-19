import 'package:cubit_ui_flow/cubit_ui_flow.dart';
import 'package:flutter_test/flutter_test.dart';

import 'lifecycle_helpers.dart';

void main() {
  group('AdapterScopeImpl.release', () {
    test('cancels a superseded field and combine', () async {
      final scope = AdapterScopeImpl();
      final a = CountingCubit(), b = CountingCubit();
      final fa = scope.cubitField<int, int>(a, ident);
      final fb = scope.cubitField<int, int>(b, ident);
      final comb = scope.combine2<int, int, int>(fa, fb, sumAB);
      expect(a.listeners + b.listeners, 2);
      scope.release((fa, fb, sumAB));
      scope.release((a, ident));
      scope.release((b, ident));
      expect(a.listeners + b.listeners, 0);
      // releasing again, or an unknown key, is a no-op
      scope.release((a, ident));
      expect(() => comb.value, returnsNormally);
      // a fresh request creates a fresh field
      scope.cubitField<int, int>(a, ident);
      expect(a.listeners, 1);
      scope.dispose();
      expect(a.listeners, 0);
    });
  });
}
