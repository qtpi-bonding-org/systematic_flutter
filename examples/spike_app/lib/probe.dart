import 'package:flutter/widgets.dart';

/// Wraps a probed view. Tests replace [probe] to count builds.
typedef Probe = Widget Function(String id, Widget child);

Widget noProbe(String id, Widget child) => child;

Probe probe = noProbe;
