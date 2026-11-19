import 'package:flutter/widgets.dart';

import 'app.dart';
import 'infrastructure/error_capture.dart';

void main() {
  configureErrorCapture();
  runApp(const SpikeApp());
}
