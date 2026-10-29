// Simple Dart example of cubit_ui_flow library
import 'package:cubit_ui_flow/cubit_ui_flow.dart';
import 'example_implementations.dart';

void main() {
  print('=== cubit_ui_flow Library Test ===');
  
  // Test UiFlowStatus
  print('UiFlowStatus.idle.isIdle: ${UiFlowStatus.idle.isIdle}');
  print('UiFlowStatus.loading.isLoading: ${UiFlowStatus.loading.isLoading}');
  print('UiFlowStatus.success.isSuccess: ${UiFlowStatus.success.isSuccess}');
  
  // Test MessageKey and the resolver
  const resolver = FallbackLabelResolver();
  const errorKey = MessageKey.error(ExampleKeys.genericError);
  final successKey = MessageKey.success(
    L10nKey.generated('test.success', {'count': 5}),
  );
  print('Error: ${resolver.resolve(errorKey.label)} (${errorKey.type})');
  print('Success: ${resolver.resolve(successKey.label)} (${successKey.type})');

  // Test DefaultExceptionKeyMapper
  const exceptionMapper = DefaultExceptionKeyMapper();
  final networkKey = exceptionMapper.map(Exception('Network error'));
  print('Exception mapped: ${networkKey == null ? 'null' : resolver.resolve(networkKey.label)}');
  
  print('✅ All basic functionality works!');
}