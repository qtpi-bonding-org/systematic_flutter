import 'package:flutter_test/flutter_test.dart';
import 'package:nav_snapshot/nav_snapshot.dart';

void main() {
  test('package resolves and exports its library', () {
    expect(const PartLoading<int>().isLoading, isTrue);
  });
}
