import 'package:cubit_ui_flow/cubit_ui_flow.dart';
import 'package:flutter_error_privserver/src/utils/message_text.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('keeps the key of a localized label', () {
    expect(
      messageText(const MessageKey.error(L10nKey.generated('error.acp.failed'))),
      'error.acp.failed',
    );
  });

  test('drops the text of a data label, which may hold user content', () {
    expect(messageText(const MessageKey.error(DataText('My diary'))), isNull);
  });

  test('is null without a message', () {
    expect(messageText(null), isNull);
  });
}
