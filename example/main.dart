import 'package:flutter/material.dart';
import 'package:flutter_color_palette/flutter_color_palette.dart';
import 'package:flutter_color_palette/widgets.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Color Palette Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Color Palette Demo'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late IColorPalette palette;

  @override
  void initState() {
    super.initState();
    
    // Create a basic palette
    palette = AppColorPalette.basic(
      name: 'Demo Palette',
      description: 'A demonstration of the color palette system',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Palette info
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      palette.name ?? 'Unnamed Palette',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    if (palette.description != null) ...[
                      const SizedBox(height: 8),
                      Text(palette.description!),
                    ],
                    const SizedBox(height: 16),
                    
                    // Color swatches
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: palette.colorIdentifiers.map((id) {
                        final color = palette.getColor(id)!;
                        return Column(
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: color,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Center(
                                child: Text(
                                  id,
                                  style: TextStyle(
                                    color: color.computeLuminance() > 0.5 
                                        ? Colors.black 
                                        : Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              id,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Interactive Contrast Matrix with Colorblind Modes
            Text(
              'Interactive Contrast Matrix',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Test your palette across different vision types and themes',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 16),
            ContrastMatrixWidget(
              lightPalette: palette,
              cellSize: 50,
              showColorblindModes: true,
              showAccessibilityGrades: true,
            ),
            
            const SizedBox(height: 24),
            
            // Colorblind Simulation
            Text(
              'Colorblind Simulation',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            ColorblindMatrixWidget(
              palette: palette,
              cellSize: 40,
            ),
          ],
        ),
      ),
    );
  }
}