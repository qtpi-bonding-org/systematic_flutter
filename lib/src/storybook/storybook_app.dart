// lib/src/storybook/storybook_app.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  @override
  Widget build(BuildContext context) {
    final categories = groupStories(widget.stories);
    return AnimatedBuilder(
      animation: widget.controller,
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
                  child: Builder(
                    builder: (stageCtx) => Container(
                      color: Theme.of(stageCtx).scaffoldBackgroundColor,
                      child: DeviceFrame(
                        preset: widget.controller.devicePreset,
                        child: Builder(builder: _selected.builder),
                      ),
                    ),
                  ),
                ),
                _ToolsPanel(controller: widget.controller),
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
  const _ToolsPanel({required this.controller});

  final ThemeController controller;

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
