// lib/src/storybook/widgets/device_frame.dart
import 'package:flutter/material.dart';
import 'package:qtpi_ui/qtpi_ui.dart';
import '../device_preset.dart';

/// Frames the stage at a simulated device width and points [UiScaler] at that
/// same width, so token-sized widgets follow the preview. When [preset] is
/// null, falls back to the real window. Re-init happens here (not in the
/// controller) because this widget owns a BuildContext.
class DeviceFrame extends StatelessWidget {
  const DeviceFrame({super.key, this.preset, required this.child});

  final DevicePreset? preset;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final p = preset;
    if (p == null) {
      UiScaler.instance.init(context);
      return child;
    }
    UiScaler.instance.initFrom(FixedScreenMetrics(p.width));
    final media = MediaQuery.of(context);
    return Center(
      child: Container(
        width: p.width,
        decoration: BoxDecoration(border: Border.all(color: Colors.black26)),
        child: MediaQuery(
          data: media.copyWith(size: Size(p.width, media.size.height)),
          child: child,
        ),
      ),
    );
  }
}
