// lib/src/storybook/storybook_app.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'device_preset.dart';
import 'palette_dart_serializer.dart';
import 'story.dart';
import 'theme_controller.dart';
import 'widgets/contrast_calculator.dart';
import 'widgets/device_frame.dart';
import 'widgets/palette_editor.dart';

/// The app-agnostic Storybook shell. Chrome is plain Flutter; only the stage
/// (inside [DeviceFrame]) uses UiScaler.
class StorybookApp extends StatefulWidget {
  const StorybookApp({
    super.key,
    required this.stories,
    required this.controller,
    required this.themeBuilder,
  });

  final List<Story> stories;
  final ThemeController controller;
  final ThemeData Function(ThemeController) themeBuilder;

  @override
  State<StorybookApp> createState() => _StorybookAppState();
}

class _StorybookAppState extends State<StorybookApp> {
  late Story _selected = widget.stories.first;

  // Storybook stage background — independent of the app palette so you can
  // check components on a neutral surface without touching design tokens.
  final _storybookColor = ValueNotifier<Color>(const Color(0xFF111318));

  @override
  void dispose() {
    _storybookColor.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(StorybookApp oldWidget) {
    super.didUpdateWidget(oldWidget);
    // On hot reload the stories list is replaced. Re-match by name so the
    // currently-viewed story picks up any code changes; fall back to first.
    if (!identical(widget.stories, oldWidget.stories)) {
      final name = _selected.name;
      final cat = _selected.category;
      _selected = widget.stories.firstWhere(
        (s) => s.name == name && s.category == cat,
        orElse: () => widget.stories.first,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = groupStories(widget.stories);
    return AnimatedBuilder(
      // Merge the palette controller + shell-color notifier so any change
      // to either immediately re-runs the stage builder.
      animation: Listenable.merge([widget.controller, _storybookColor]),
      builder: (context, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: widget.themeBuilder(widget.controller),
          home: Scaffold(
            body: Row(
              children: [
                _Sidebar(
                  categories: categories,
                  selected: _selected,
                  onSelect: (s) => setState(() => _selected = s),
                ),
                Expanded(
                  child: ColoredBox(
                    color: _storybookColor.value,
                    child: DeviceFrame(
                      preset: widget.controller.devicePreset,
                      child: Builder(builder: _selected.builder),
                    ),
                  ),
                ),
                _ToolsPanel(
                  controller: widget.controller,
                  storybookColor: _storybookColor.value,
                  onStorybookColorChanged: (c) => _storybookColor.value = c,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.categories,
    required this.selected,
    required this.onSelect,
  });

  final List<StoryCategory> categories;
  final Story selected;
  final ValueChanged<Story> onSelect;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 240,
      child: Material(
        color: Colors.black12,
        child: ListView(
          children: [
            for (final cat in categories) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                child: Text(cat.name,
                    style: Theme.of(context).textTheme.titleSmall),
              ),
              for (final story in cat.stories)
                ListTile(
                  dense: true,
                  selected: identical(story, selected),
                  title: Text(story.name),
                  onTap: () => onSelect(story),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ToolsPanel extends StatelessWidget {
  const _ToolsPanel({
    required this.controller,
    required this.storybookColor,
    required this.onStorybookColorChanged,
  });

  final ThemeController controller;
  final Color storybookColor;
  final ValueChanged<Color> onStorybookColorChanged;

  static const _shellPresets = [
    Color(0xFF000000),
    Color(0xFF111318),
    Color(0xFF1C1F26),
    Color(0xFF2C2C2C),
    Color(0xFF555555),
    Color(0xFFAAAAAA),
    Color(0xFFEEEEEE),
    Color(0xFFFFFFFF),
  ];

  Future<void> _openShellPicker(BuildContext context) async {
    double h = HSLColor.fromColor(storybookColor).hue;
    double s = HSLColor.fromColor(storybookColor).saturation;
    double l = HSLColor.fromColor(storybookColor).lightness;
    Color current = storybookColor;

    await showDialog<void>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          title: const Text('Storybook background'),
          contentPadding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                HueRingPicker(
                  pickerColor: current,
                  onColorChanged: (c) {
                    final hsl = HSLColor.fromColor(c);
                    setSt(() {
                      if (hsl.saturation > 0.001 &&
                          hsl.lightness > 0.001 &&
                          hsl.lightness < 0.999) {
                        h = hsl.hue;
                      }
                      s = hsl.saturation;
                      l = hsl.lightness;
                      current = HSLColor.fromAHSL(1, h, s, l).toColor();
                    });
                  },
                  enableAlpha: false,
                  displayThumbColor: true,
                ),
                const SizedBox(height: 8),
                _buildSlider(ctx, setSt, 'L', l * 100, 0, 100, (v) {
                  l = v / 100;
                  current = HSLColor.fromAHSL(1, h, s, l).toColor();
                }),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                onStorybookColorChanged(current);
                Navigator.pop(ctx);
              },
              child: const Text('Apply'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlider(
    BuildContext ctx,
    StateSetter setSt,
    String label,
    double value,
    double min,
    double max,
    ValueChanged<double> onChanged,
  ) {
    return Row(
      children: [
        SizedBox(
          width: 16,
          child: Text(label,
              style:
                  const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
        ),
        Expanded(
          child: Slider(
            value: value,
            min: min,
            max: max,
            onChanged: (v) => setSt(() => onChanged(v)),
          ),
        ),
        SizedBox(
          width: 36,
          child: Text(value.toStringAsFixed(0),
              style: const TextStyle(fontSize: 11), textAlign: TextAlign.right),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 320,
      child: Material(
        color: Colors.black12,
        child: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            const Text('Device'),
            DropdownButton<DevicePreset?>(
              value: controller.devicePreset,
              hint: const Text('Fit window'),
              isExpanded: true,
              onChanged: (v) => controller.devicePreset = v,
              items: [
                const DropdownMenuItem(value: null, child: Text('Fit window')),
                for (final p in DevicePreset.defaults)
                  DropdownMenuItem(
                      value: p, child: Text('${p.name} (${p.width.toInt()})')),
              ],
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Dark mode'),
              value: controller.isDark,
              onChanged: (v) => controller.isDark = v,
            ),
            const Divider(),
            const Text('Storybook background'),
            const SizedBox(height: 6),
            Row(
              children: [
                for (final c in _shellPresets)
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: GestureDetector(
                      onTap: () => onStorybookColorChanged(c),
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: c,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: storybookColor == c
                                ? Colors.white
                                : Colors.white24,
                            width: storybookColor == c ? 2 : 1,
                          ),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: () => _openShellPicker(context),
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: storybookColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white54, width: 1.5),
                    ),
                    child: const Icon(Icons.colorize,
                        size: 12, color: Colors.white70),
                  ),
                ),
              ],
            ),
            const Divider(),
            const Text('Palette'),
            SizedBox(height: 300, child: PaletteEditor(controller: controller)),
            TextButton(
              onPressed: () {
                final dart = paletteToDart(controller.tokens,
                    name: controller.paletteName);
                Clipboard.setData(ClipboardData(text: dart));
              },
              child: const Text('Copy palette as Dart'),
            ),
            TextButton(
              onPressed: controller.reset,
              child: const Text('Reset overrides'),
            ),
            const Divider(),
            const Text('Contrast'),
            ContrastCalculator(tokens: controller.tokens),
          ],
        ),
      ),
    );
  }
}
