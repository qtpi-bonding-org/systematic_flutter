import 'package:flutter_test/flutter_test.dart';
import 'package:systematic_catalog/systematic_catalog.dart';

abstract class _Actions {
  void tick();
  Future<void> save(String id);
  void rename(String id, {required String title});
}

class _Fake extends NoOpActions implements _Actions {}

void main() {
  test('void method on a NoOpActions fake returns normally', () {
    final _Actions a = _Fake();
    a.tick();
    a.rename('x', title: 'y');
  });

  test('Future<void> method returns a completed future', () async {
    final _Actions a = _Fake();
    await a.save('x');
  });
}
