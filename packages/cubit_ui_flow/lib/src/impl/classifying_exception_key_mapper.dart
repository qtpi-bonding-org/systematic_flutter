import 'package:systematic_failure/systematic_failure.dart';
import 'package:l10n_key_resolver/runtime.dart';

import '../contracts/all_contracts.dart';

/// Maps classified failures to stable localized keys.
class ClassifyingExceptionKeyMapper implements IExceptionKeyMapper {
  const ClassifyingExceptionKeyMapper({required this.generic});

  final L10nKey generic;

  @override
  MessageKey map(Object e) => MessageKey.error(classify(e).message ?? generic);
}
