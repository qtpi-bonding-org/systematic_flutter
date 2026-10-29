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

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    // Create a comprehensive demo palette
    final demoPalette = AppColorPalette.enumerated(
      colors: [
        const Color(0xFF1976D2), // Blue - primary
        const Color(0xFF388E3C), // Green - success
        const Color(0xFFF57C00), // Orange - warning
        const Color(0xFFD32F2F), // Red - error
        const Color(0xFF7B1FA2), // Purple - insights
        const Color(0xFF00796B), // Teal - wellness
      ],
      neutrals: [
        const Color(0xFF212121), // Dark text
        const Color(0xFF424242), // Medium dark
        const Color(0xFF757575), // Medium
        const Color(0xFFBDBDBD), // Light medium
        const Color(0xFFF5F5F5), // Light background
        const Color(0xFFFFFFFF), // Pure white
      ],
      name: 'Flutter Color Palette Demo',
      description: 'Interactive demonstration of pure color enumeration, mathematical symmetry, and scientific accessibility testing',
      tags: ['demo', 'interactive', 'accessibility', 'colorblind'],
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: demoPalette.getColor('color1'),
        foregroundColor: Colors.white,
      ),
      body: PaletteDemoWidget(
        initialPalette: demoPalette,
        title: 'Flutter Color Palette System',
        description: 'A comprehensive demonstration of pure color enumeration, automatic dark mode generation, and scientific colorblind simulation. Edit any color to see real-time updates throughout the entire system.',
      ),
    );
  }
}