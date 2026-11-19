import 'package:cubit_ui_flow/cubit_ui_flow.dart';
import 'package:flutter_test/flutter_test.dart';

@adapterHelper
String helper() => 'ok';

void main() {
  test('adapterHelper is exported as a const AdapterHelper', () {
    expect(adapterHelper, isA<AdapterHelper>());
    expect(helper(), 'ok');
  });
}
