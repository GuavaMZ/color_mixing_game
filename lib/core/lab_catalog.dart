import 'package:flutter/material.dart';

class LabItem {
  final String id;
  final String name;
  final String description;
  final int price;
  final String category;
  final Color placeholderColor;
  final List<Color> gradientColors;
  final IconData? icon;

  const LabItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    required this.placeholderColor,
    this.gradientColors = const [],
    this.icon,
  });
}

class LabCatalog {
  static const List<LabItem> items = [
    // Surfaces
    LabItem(
      id: 'surface_steel',
      name: 'Basic Steel',
      description: 'Standard industrial-grade stainless steel surface',
      price: 0,
      category: 'surface',
      placeholderColor: Colors.grey,
      gradientColors: [Color(0xFF424242), Color(0xFF212121)],
      icon: Icons.grid_4x4,
    ),
    LabItem(
      id: 'surface_marble',
      name: 'Polished Marble',
      description: 'Luxurious white marble with gold veining',
      price: 1200,
      category: 'surface',
      placeholderColor: Colors.white,
      gradientColors: [Colors.white, Color(0xFFF0F0F0), Color(0xFFFFD700)],
      icon: Icons.diamond,
    ),
    LabItem(
      id: 'surface_titanium',
      name: 'Titanium Alloy',
      description: 'High-tech aerospace-grade titanium with brushed finish',
      price: 2400,
      category: 'surface',
      placeholderColor: Color(0xFFB0B0B0),
      gradientColors: [Color(0xFF9E9E9E), Color(0xFF757575)],
      icon: Icons.layers,
    ),
    LabItem(
      id: 'surface_cyber',
      name: 'Cyber-Grid Hex',
      description: 'Advanced hexagonal cyber-grid with reactive lighting',
      price: 3600,
      category: 'surface',
      placeholderColor: Colors.cyan,
      gradientColors: [Color(0xFF00FFCC), Color(0xFF0077FF)],
      icon: Icons.hexagon,
    ),
    LabItem(
      id: 'surface_crystal',
      name: 'Crystal Matrix',
      description: 'Crystalline surface with prismatic light refraction',
      price: 6000,
      category: 'surface',
      placeholderColor: Color(0xFFE1F5FE),
      gradientColors: [Color(0xFFE1F5FE), Color(0xFF81D4FA), Color(0xFF4FC3F7)],
      icon: Icons.auto_awesome,
    ),
    LabItem(
      id: 'surface_obsidian',
      name: 'Obsidian Slab',
      description: 'Volcanic obsidian glass with deep reflective sheen',
      price: 4800,
      category: 'surface',
      placeholderColor: Color(0xFF1A1A1A),
      gradientColors: [Color(0xFF1A1A1A), Color(0xFF3D0000), Color(0xFF1A1A1A)],
      icon: Icons.layers_outlined,
    ),
    LabItem(
      id: 'surface_aurora',
      name: 'Aurora Plate',
      description: 'Iridescent aurora-tinted surface that shifts with light',
      price: 8400,
      category: 'surface',
      placeholderColor: Color(0xFF00E5FF),
      gradientColors: [Color(0xFF00E5FF), Color(0xFF7C4DFF), Color(0xFF00E676)],
      icon: Icons.blur_circular,
    ),

    // Lighting
    LabItem(
      id: 'light_basic',
      name: 'Standard Fluorescent',
      description: 'Basic overhead fluorescent lighting',
      price: 0,
      category: 'lighting',
      placeholderColor: Colors.yellow,
      icon: Icons.wb_incandescent_outlined,
    ),
    LabItem(
      id: 'light_warm',
      name: 'Warm Amber',
      description: 'Cozy warm amber lighting for a relaxed atmosphere',
      price: 1500,
      category: 'lighting',
      placeholderColor: Colors.orange,
      gradientColors: [Colors.orange, Colors.amber],
      icon: Icons.wb_sunny,
    ),
    LabItem(
      id: 'light_neon_blue',
      name: 'Neon Blue & Purple',
      description: 'Dramatic neon lighting with color-shifting effects',
      price: 2100,
      category: 'lighting',
      placeholderColor: Colors.purpleAccent,
      gradientColors: [
        Colors.purpleAccent,
        Colors.blueAccent,
        Colors.cyanAccent,
      ],
      icon: Icons.lightbulb,
    ),
    LabItem(
      id: 'light_rgb',
      name: 'RGB Dynamic',
      description: 'Programmable RGB lighting that adapts to your experiments',
      price: 4500,
      category: 'lighting',
      placeholderColor: Color(0xFFFF00FF),
      gradientColors: [Colors.red, Colors.green, Colors.blue],
      icon: Icons.color_lens,
    ),
    LabItem(
      id: 'light_bio',
      name: 'Bioluminescent',
      description: 'Organic bioluminescent lighting with natural glow',
      price: 7500,
      category: 'lighting',
      placeholderColor: Color(0xFF00FF88),
      gradientColors: [Color(0xFF00FF88), Color(0xFF00CCAA)],
      icon: Icons.eco,
    ),
    LabItem(
      id: 'light_plasma',
      name: 'Plasma Arc',
      description: 'High-voltage plasma arc lighting with electric crackle',
      price: 6000,
      category: 'lighting',
      placeholderColor: Color(0xFFE040FB),
      gradientColors: [Color(0xFFE040FB), Color(0xFF7C4DFF), Color(0xFF40C4FF)],
      icon: Icons.electric_bolt,
    ),
    LabItem(
      id: 'light_solar',
      name: 'Solar Spectrum',
      description: 'Full-spectrum solar simulation for true color accuracy',
      price: 9000,
      category: 'lighting',
      placeholderColor: Color(0xFFFFD600),
      gradientColors: [Color(0xFFFFD600), Color(0xFFFF6D00), Color(0xFFFFFFFF)],
      icon: Icons.wb_sunny_rounded,
    ),

    // Backgrounds
    LabItem(
      id: 'bg_default',
      name: 'Standard Lab',
      description: 'Clean, professional laboratory environment',
      price: 0,
      category: 'background',
      placeholderColor: Colors.blueGrey,
      icon: Icons.science,
    ),
    LabItem(
      id: 'bg_nature',
      name: 'Botanical Garden',
      description: 'Serene greenhouse laboratory surrounded by nature',
      price: 3000,
      category: 'background',
      placeholderColor: Colors.green,
      gradientColors: [Color(0xFF1B5E20), Color(0xFF4CAF50)],
      icon: Icons.park,
    ),
    LabItem(
      id: 'bg_cyber',
      name: 'Cyberpunk City',
      description: 'Neon-lit urban skyline with holographic billboards',
      price: 3600,
      category: 'background',
      placeholderColor: Color(0xFFFF00FF),
      gradientColors: [Color(0xFF1A1A2E), Color(0xFFFF00FF), Color(0xFF00FFFF)],
      icon: Icons.location_city,
    ),
    LabItem(
      id: 'bg_futuristic',
      name: 'High-Tech Facility',
      description: 'Cutting-edge research facility with holographic displays',
      price: 5400,
      category: 'background',
      placeholderColor: Colors.black,
      gradientColors: [Colors.black, Color(0xFF1A237E), Color(0xFF00BCD4)],
      icon: Icons.computer,
    ),
    LabItem(
      id: 'bg_underwater',
      name: 'Deep Sea Research',
      description: 'Underwater laboratory with bioluminescent marine life',
      price: 7500,
      category: 'background',
      placeholderColor: Color(0xFF006064),
      gradientColors: [Color(0xFF006064), Color(0xFF00838F), Color(0xFF0097A7)],
      icon: Icons.water,
    ),
    LabItem(
      id: 'bg_volcano',
      name: 'Volcanic Observatory',
      description: 'Dramatic crater-side lab with molten lava flows below',
      price: 4500,
      category: 'background',
      placeholderColor: Color(0xFFBF360C),
      gradientColors: [Color(0xFF212121), Color(0xFFBF360C), Color(0xFFFF6D00)],
      icon: Icons.local_fire_department_rounded,
    ),
    LabItem(
      id: 'bg_space',
      name: 'Deep Space Station',
      description: 'Orbiting space station lab with nebula vistas',
      price: 9000,
      category: 'background',
      placeholderColor: Color(0xFF0D0D2B),
      gradientColors: [Color(0xFF0D0D2B), Color(0xFF1A0533), Color(0xFF00B0FF)],
      icon: Icons.rocket_launch_rounded,
    ),

    // Stands
    LabItem(
      id: 'stand_basic',
      name: 'Standard Stand',
      description: 'Basic metal laboratory stand',
      price: 0,
      category: 'stand',
      placeholderColor: Colors.grey,
      icon: Icons.table_chart,
    ),
    LabItem(
      id: 'stand_chrome',
      name: 'Chrome Finish',
      description: 'Polished chrome stand with modern aesthetic',
      price: 900,
      category: 'stand',
      placeholderColor: Color(0xFFE0E0E0),
      gradientColors: [Color(0xFFE0E0E0), Color(0xFFBDBDBD)],
      icon: Icons.brightness_7,
    ),
    LabItem(
      id: 'stand_wood',
      name: 'Wooden Artisan',
      description: 'Handcrafted wooden stand with natural grain',
      price: 1500,
      category: 'stand',
      placeholderColor: Color(0xFF8D6E63),
      gradientColors: [Color(0xFF8D6E63), Color(0xFF6D4C41)],
      icon: Icons.deck,
    ),
    LabItem(
      id: 'stand_holo',
      name: 'Holographic',
      description: 'Floating holographic projection stand',
      price: 3000,
      category: 'stand',
      placeholderColor: Color(0xFF00E5FF),
      gradientColors: [Color(0xFF00E5FF), Color(0xFF00B8D4)],
      icon: Icons.blur_on,
    ),
    LabItem(
      id: 'stand_levitate',
      name: 'Anti-Gravity',
      description: 'Magnetic levitation stand with zero contact',
      price: 6000,
      category: 'stand',
      placeholderColor: Color(0xFFAA00FF),
      gradientColors: [Color(0xFFAA00FF), Color(0xFF6200EA)],
      icon: Icons.flight_takeoff,
    ),
    LabItem(
      id: 'stand_crystal',
      name: 'Crystal Pedestal',
      description: 'Translucent crystal pedestal with prismatic glow',
      price: 4500,
      category: 'stand',
      placeholderColor: Color(0xFF80DEEA),
      gradientColors: [Color(0xFF80DEEA), Color(0xFFB2EBF2), Color(0xFF00BCD4)],
      icon: Icons.diamond_outlined,
    ),
    LabItem(
      id: 'stand_obsidian',
      name: 'Obsidian Throne',
      description: 'Imposing dark volcanic rock stand with ember veins',
      price: 7500,
      category: 'stand',
      placeholderColor: Color(0xFF212121),
      gradientColors: [Color(0xFF212121), Color(0xFF4E0000), Color(0xFF212121)],
      icon: Icons.chair_rounded,
    ),
  ];

  static LabItem getItem(String id) {
    return items.firstWhere((item) => item.id == id, orElse: () => items.first);
  }

  static LabItem? getItemByCategory(String category, String id) {
    try {
      return items.firstWhere(
        (item) => item.category == category && item.id == id,
      );
    } catch (e) {
      return null;
    }
  }
}
