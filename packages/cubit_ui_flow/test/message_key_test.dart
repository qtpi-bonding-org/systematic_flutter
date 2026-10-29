import 'package:cubit_ui_flow/cubit_ui_flow.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n_key_resolver/runtime.dart';

class _Feedback implements IFeedbackService {
  final shown = <FeedbackMessage>[];
  @override
  void show(FeedbackMessage message) => shown.add(message);
}

class _Loading implements ILoadingService {
  int shows = 0, hides = 0;
  @override
  void show() => shows++;
  @override
  void hide() => hides++;
}

/// Resolves keys to "<key>|<args>" so the test sees what reached it.
class _Resolver implements LabelResolver {
  @override
  String resolve(Label label) => switch (label) {
        L10nKey(:final key, :final args) => '$key|$args',
        DataText(:final value) => value,
      };
}

void main() {
  const saved = L10nKey.generated('settings.saved');

  group('MessageKey', () {
    test('each constructor carries the label and its type', () {
      expect(const MessageKey.info(saved).type, MessageType.info);
      expect(const MessageKey.success(saved).type, MessageType.success);
      expect(const MessageKey.warning(saved).type, MessageType.warning);
      expect(const MessageKey.error(saved).type, MessageType.error);
      expect(const MessageKey.loading(saved).type, MessageType.loading);
      expect(const MessageKey.success(saved).label, saved);
    });

    test('equal label and type are equal', () {
      final a = MessageKey.success(L10nKey.generated('n', {'count': 2}));
      final b = MessageKey.success(L10nKey.generated('n', {'count': 2}));
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(MessageKey.error(L10nKey.generated('n', {'count': 2}))));
    });

    test('a DataText label is allowed and explicit', () {
      expect(const MessageKey.error(DataText('server said no')).label,
          const DataText('server said no'));
    });
  });

  group('UiFlowService', () {
    late _Feedback feedback;
    late _Loading loading;
    late UiFlowService service;

    setUp(() {
      feedback = _Feedback();
      loading = _Loading();
      service = UiFlowService(
        resolver: _Resolver(),
        feedback: feedback,
        loading: loading,
      );
    });

    test('resolves the label through the LabelResolver', () {
      service.handleMessage(
        MessageKey.success(L10nKey.generated('n', {'count': 2})),
      );
      expect(feedback.shown.single.message, 'n|{count: 2}');
      expect(feedback.shown.single.type, MessageType.success);
      expect(loading.hides, 1);
    });

    test('loading shows the overlay and no feedback', () {
      service.handleMessage(const MessageKey.loading(saved));
      expect(loading.shows, 1);
      expect(feedback.shown, isEmpty);
    });
  });
}
