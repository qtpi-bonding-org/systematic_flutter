// lib/src/storybook/storybook_app.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'device_preset.dart';
import 'palette_dart_serializer.dart';
import 'story.dart';
import 'theme_controller.dart';
import 'widgets/device_frame.dart';
import 'widgets/palette_editor.dart';

/// The app-agnostic Storybook shell. Chrome is plain Flutter; only the stage
/// (inside [DeviceFrame]) uses the app theme.
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

  // Storybook stage background — independent of the app palette.
  // Plain Color field updated via setState so Flutter's standard dirty-mark
  // pipeline guarantees the ColoredBox repaints on the same frame.
  Color _storybookColor = const Color(0xFF111318);

  // Fixed neutral chrome theme — never changes with the app palette.
  static final _chromeTheme = ThemeData.dark(useMaterial3: true);

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
    // AnimatedBuilder handles palette changes; storybook-color changes go
    // through setState() on this State directly.
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final appTheme = widget.themeBuilder(widget.controller);
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          // Chrome uses a fixed neutral dark theme so the sidebar and tools
          // panel are never affected by palette edits.
          theme: _chromeTheme,
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
                    color: _storybookColor,
                    child: DeviceFrame(
                      preset: widget.controller.devicePreset,
                      // Only the story content gets the live app theme.
                      child: Theme(
                        data: appTheme,
                        child: Builder(builder: _selected.builder),
                      ),
                    ),
                  ),
                ),
                _ToolsPanel(
                  controller: widget.controller,
                  storybookColor: _storybookColor,
                  onStorybookColorChanged: (c) =>
                      setState(() => _storybookColor = c),
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

  @override
  Widget build(BuildContext context) {
    final greyValue = HSLColor.fromColor(storybookColor).lightness;

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
            const SizedBox(height: 10),
            _GrayscaleSlider(
              value: greyValue,
              onChanged: (v) => onStorybookColorChanged(
                HSLColor.fromAHSL(1, 0, 0, v).toColor(),
              ),
            ),
            const SizedBox(height: 4),
            const Divider(),
            const Text('Palette'),
            SizedBox(height: 550, child: PaletteEditor(controller: controller)),
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
          ],
        ),
      ),
    );
  }
}

class _GrayscaleSlider extends StatelessWidget {
  const _GrayscaleSlider({required this.value, required this.onChanged});

  /// 0.0 = black, 1.0 = white.
  final double value;
  final ValueChanged<double> onChanged;

  void _update(double dx, double trackWidth) {
    const thumbSize = 20.0;
    onChanged(
        ((dx - thumbSize / 2) / (trackWidth - thumbSize)).clamp(0.0, 1.0));
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const thumbSize = 20.0;
        final trackWidth = constraints.maxWidth;
        final thumbX = value * (trackWidth - thumbSize);
        final grey = (value * 255).round();

        return Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: (e) => _update(e.localPosition.dx, trackWidth),
          onPointerMove: (e) => _update(e.localPosition.dx, trackWidth),
          child: SizedBox(
            height: 24,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Gradient track
                Positioned(
                  left: 0,
                  right: 0,
                  top: 7,
                  bottom: 7,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(5),
                    child: const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.black, Colors.white],
                        ),
                      ),
                    ),
                  ),
                ),
                // Thumb
                Positioned(
                  left: thumbX,
                  top: 2,
                  child: Container(
                    width: thumbSize,
                    height: thumbSize,
                    decoration: BoxDecoration(
                      color: Color.fromRGBO(grey, grey, grey, 1),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white70, width: 2),
                      boxShadow: const [
                        BoxShadow(blurRadius: 3, color: Colors.black54),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
