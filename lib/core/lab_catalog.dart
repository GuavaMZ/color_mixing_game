import 'package:flutter/material.dart';

// ─── Rarity Tier System ──────────────────────────────────────────────────────

enum LabRarity {
  common,
  rare,
  epic,
  legendary;

  String get label {
    switch (this) {
      case LabRarity.common:
        return 'COMMON';
      case LabRarity.rare:
        return 'RARE';
      case LabRarity.epic:
        return 'EPIC';
      case LabRarity.legendary:
        return 'LEGENDARY';
    }
  }

  Color get color {
    switch (this) {
      case LabRarity.common:
        return const Color(0xFF9E9E9E);
      case LabRarity.rare:
        return const Color(0xFF42A5F5);
      case LabRarity.epic:
        return const Color(0xFFAB47BC);
      case LabRarity.legendary:
        return const Color(0xFFFFD54F);
    }
  }

  Color get glowColor {
    switch (this) {
      case LabRarity.common:
        return const Color(0xFF757575);
      case LabRarity.rare:
        return const Color(0xFF1565C0);
      case LabRarity.epic:
        return const Color(0xFF7B1FA2);
      case LabRarity.legendary:
        return const Color(0xFFFF8F00);
    }
  }

  List<Color> get gradient {
    switch (this) {
      case LabRarity.common:
        return [const Color(0xFF616161), const Color(0xFF9E9E9E)];
      case LabRarity.rare:
        return [const Color(0xFF1565C0), const Color(0xFF42A5F5)];
      case LabRarity.epic:
        return [const Color(0xFF7B1FA2), const Color(0xFFCE93D8)];
      case LabRarity.legendary:
        return [
          const Color(0xFFFF8F00),
          const Color(0xFFFFD54F),
          const Color(0xFFFF8F00),
        ];
    }
  }

  String get icon {
    switch (this) {
      case LabRarity.common:
        return '●';
      case LabRarity.rare:
        return '◆';
      case LabRarity.epic:
        return '★';
      case LabRarity.legendary:
        return '✦';
    }
  }
}

// ─── Lab Item Model ──────────────────────────────────────────────────────────

class LabItem {
  final String id;
  final String name;
  final String description;
  final String lore;
  final int price;
  final String category;
  final Color placeholderColor;
  final List<Color> gradientColors;
  final IconData? icon;
  final LabRarity rarity;
  final int unlockLevel;

  const LabItem({
    required this.id,
    required this.name,
    required this.description,
    this.lore = '',
    required this.price,
    required this.category,
    required this.placeholderColor,
    this.gradientColors = const [],
    this.icon,
    this.rarity = LabRarity.common,
    this.unlockLevel = 0,
  });
}

// ─── Lab Catalog ─────────────────────────────────────────────────────────────

class LabCatalog {
  static const List<LabItem> items = [
    // ═══════════════════════════════════════════════════════════════════════════
    // SURFACES
    // ═══════════════════════════════════════════════════════════════════════════
    LabItem(
      id: 'surface_steel',
      name: 'Cryo-Steel Plate',
      description: 'Ultra-chilled industrial steel with micro-grooved texture',
      lore:
          'Standard-issue across all Tier-1 research stations. The micro-grooves channel spilled reagents away from sensitive equipment.',
      price: 0,
      category: 'surface',
      placeholderColor: Colors.grey,
      gradientColors: [Color(0xFF2C3E50), Color(0xFF000000)],
      icon: Icons.grid_4x4,
      rarity: LabRarity.common,
    ),
    LabItem(
      id: 'surface_marble',
      name: 'Ionic Marble Slab',
      description: 'Molecularly-bonded marble with conductive gold veins',
      lore:
          'Quarried from the deep mines of Carinthia-7. The gold veins are not decorative — they form a natural Faraday cage against spectral interference.',
      price: 1200,
      category: 'surface',
      placeholderColor: Colors.white,
      gradientColors: [Color(0xFFE0E0E0), Color(0xFFFFFFFF), Color(0xFFFFD700)],
      icon: Icons.diamond,
      rarity: LabRarity.rare,
    ),
    LabItem(
      id: 'surface_titanium',
      name: 'Fusion Titanium',
      description: 'Aura-forged titanium alloy with heat-shielded coating',
      lore:
          'Forged in the plasma cores of orbital foundries. Withstands temperatures exceeding 3,000°K without deformation.',
      price: 2400,
      category: 'surface',
      placeholderColor: Color(0xFFB0B0B0),
      gradientColors: [Color(0xFF606c88), Color(0xFF3f4c6b)],
      icon: Icons.layers,
      rarity: LabRarity.rare,
      unlockLevel: 5,
    ),
    LabItem(
      id: 'surface_cyber',
      name: 'Vector-Grid Hex',
      description: 'Quantum-synced hexagonal lattice with reactive pulses',
      lore:
          'Each hexagonal cell contains a miniature quantum processor. The lattice reacts to chromatic anomalies before they become visible to the naked eye.',
      price: 3600,
      category: 'surface',
      placeholderColor: Colors.cyan,
      gradientColors: [Color(0xFF00FFCC), Color(0xFF0077FF), Color(0xFF003366)],
      icon: Icons.hexagon,
      rarity: LabRarity.epic,
      unlockLevel: 10,
    ),
    LabItem(
      id: 'surface_obsidian',
      name: 'Void-Glass Slab',
      description:
          'Zero-reflection obsidian forged in a volcanic pressure-chamber',
      lore:
          'Created in the caldera of Mount Erebus under 40,000 atmospheres. Absorbs 99.97% of all light — the closest thing to a portable void.',
      price: 4800,
      category: 'surface',
      placeholderColor: Color(0xFF1A1A1A),
      gradientColors: [Color(0xFF0F0F0F), Color(0xFF2C0000), Color(0xFF0F0F0F)],
      icon: Icons.layers_outlined,
      rarity: LabRarity.epic,
      unlockLevel: 15,
    ),
    LabItem(
      id: 'surface_crystal',
      name: 'Prism-Matrix Glass',
      description:
          'High-refractive crystal lattice for light-purity experiments',
      lore:
          'Grown over 200 years in zero-gravity crystallization chambers. Each facet refracts light into its 147 constituent wavelengths.',
      price: 6000,
      category: 'surface',
      placeholderColor: Color(0xFFE1F5FE),
      gradientColors: [Color(0xFFE1F5FE), Color(0xFF81D4FA), Color(0xFFE1F5FE)],
      icon: Icons.auto_awesome,
      rarity: LabRarity.epic,
      unlockLevel: 20,
    ),
    LabItem(
      id: 'surface_aurora',
      name: 'Spectral Aurora Plate',
      description: 'Photonic-reactive surface that mimics the northern lights',
      lore:
          'Embedded with captured aurora borealis particles from the Svalbard Rift. The surface shifts through the entire visible spectrum in real time.',
      price: 8400,
      category: 'surface',
      placeholderColor: Color(0xFF00E5FF),
      gradientColors: [Color(0xFF00C9FF), Color(0xFF92FE9D), Color(0xFF00C9FF)],
      icon: Icons.blur_circular,
      rarity: LabRarity.legendary,
      unlockLevel: 30,
    ),

    // ═══════════════════════════════════════════════════════════════════════════
    // LIGHTING
    // ═══════════════════════════════════════════════════════════════════════════
    LabItem(
      id: 'light_basic',
      name: 'Standard Fluorescent',
      description: 'Basic overhead fluorescent lighting',
      lore:
          'The humble workhorse of every research facility. Reliable, if uninspiring.',
      price: 0,
      category: 'lighting',
      placeholderColor: Colors.yellow,
      icon: Icons.wb_incandescent_outlined,
      rarity: LabRarity.common,
    ),
    LabItem(
      id: 'light_warm',
      name: 'Warm Amber',
      description: 'Cozy warm amber lighting for a relaxed atmosphere',
      lore:
          'Calibrated to 2700K color temperature. Studies show chemists working under amber light achieve 12% higher accuracy.',
      price: 1500,
      category: 'lighting',
      placeholderColor: Colors.orange,
      gradientColors: [Colors.orange, Colors.amber],
      icon: Icons.wb_sunny,
      rarity: LabRarity.rare,
    ),
    LabItem(
      id: 'light_neon_blue',
      name: 'Neon Blue & Purple',
      description: 'Dramatic neon lighting with color-shifting effects',
      lore:
          'Originally developed for deep-sea research stations where natural light never reaches. The shifting wavelengths keep the mind alert.',
      price: 2100,
      category: 'lighting',
      placeholderColor: Colors.purpleAccent,
      gradientColors: [
        Colors.purpleAccent,
        Colors.blueAccent,
        Colors.cyanAccent,
      ],
      icon: Icons.lightbulb,
      rarity: LabRarity.rare,
      unlockLevel: 3,
    ),
    LabItem(
      id: 'light_rgb',
      name: 'RGB Dynamic',
      description: 'Programmable RGB lighting that adapts to your experiments',
      lore:
          'AI-driven adaptive illumination that auto-calibrates based on the chromatic profile of the active experiment.',
      price: 4500,
      category: 'lighting',
      placeholderColor: Color(0xFFFF00FF),
      gradientColors: [Colors.red, Colors.green, Colors.blue],
      icon: Icons.color_lens,
      rarity: LabRarity.epic,
      unlockLevel: 12,
    ),
    LabItem(
      id: 'light_plasma',
      name: 'Plasma Arc',
      description: 'High-voltage plasma arc lighting with electric crackle',
      lore:
          'Channeling 50,000 volts through argon gas produces the purest white light known to science. Also looks incredible.',
      price: 6000,
      category: 'lighting',
      placeholderColor: Color(0xFFE040FB),
      gradientColors: [Color(0xFFE040FB), Color(0xFF7C4DFF), Color(0xFF40C4FF)],
      icon: Icons.electric_bolt,
      rarity: LabRarity.epic,
      unlockLevel: 18,
    ),
    LabItem(
      id: 'light_bio',
      name: 'Bioluminescent',
      description: 'Organic bioluminescent lighting with natural glow',
      lore:
          'Cultivated from deep-ocean jellyfish DNA spliced with firefly luciferase. A living light source that breathes with your lab.',
      price: 7500,
      category: 'lighting',
      placeholderColor: Color(0xFF00FF88),
      gradientColors: [Color(0xFF00FF88), Color(0xFF00CCAA)],
      icon: Icons.eco,
      rarity: LabRarity.legendary,
      unlockLevel: 25,
    ),
    LabItem(
      id: 'light_solar',
      name: 'Solar Spectrum',
      description: 'Full-spectrum solar simulation for true color accuracy',
      lore:
          'Replicates the exact photon distribution of Sol at high noon. The gold standard for chromatic research, literally.',
      price: 9000,
      category: 'lighting',
      placeholderColor: Color(0xFFFFD600),
      gradientColors: [Color(0xFFFFD600), Color(0xFFFF6D00), Color(0xFFFFFFFF)],
      icon: Icons.wb_sunny_rounded,
      rarity: LabRarity.legendary,
      unlockLevel: 35,
    ),

    // ═══════════════════════════════════════════════════════════════════════════
    // BACKGROUNDS
    // ═══════════════════════════════════════════════════════════════════════════
    LabItem(
      id: 'bg_default',
      name: 'Standard Lab',
      description: 'Clean, professional laboratory environment',
      lore: 'Where every great experiment begins. Simple, functional, proven.',
      price: 0,
      category: 'background',
      placeholderColor: Colors.blueGrey,
      icon: Icons.science,
      rarity: LabRarity.common,
    ),
    LabItem(
      id: 'bg_nature',
      name: 'Botanical Garden',
      description: 'Serene greenhouse laboratory surrounded by nature',
      lore:
          'Built within the canopy of the Amazonian Bio-Reserve. Over 300 plant species contribute to natural air purification.',
      price: 3000,
      category: 'background',
      placeholderColor: Colors.green,
      gradientColors: [Color(0xFF1B5E20), Color(0xFF4CAF50)],
      icon: Icons.park,
      rarity: LabRarity.epic,
      unlockLevel: 8,
    ),
    LabItem(
      id: 'bg_cyber',
      name: 'Cyberpunk City',
      description: 'Neon-lit urban skyline with holographic billboards',
      lore:
          'Perched atop the Neo-Shanghai Arcology. The holographic advertisements outside make for surprisingly effective spectral calibration targets.',
      price: 3600,
      category: 'background',
      placeholderColor: Color(0xFFFF00FF),
      gradientColors: [Color(0xFF1A1A2E), Color(0xFFFF00FF), Color(0xFF00FFFF)],
      icon: Icons.location_city,
      rarity: LabRarity.epic,
      unlockLevel: 10,
    ),
    LabItem(
      id: 'bg_volcano',
      name: 'Volcanic Observatory',
      description: 'Dramatic crater-side lab with molten lava flows below',
      lore:
          'The extreme heat gradient creates unique optical phenomena. Colors behave differently here — every experiment is an adventure.',
      price: 4500,
      category: 'background',
      placeholderColor: Color(0xFFBF360C),
      gradientColors: [Color(0xFF212121), Color(0xFFBF360C), Color(0xFFFF6D00)],
      icon: Icons.local_fire_department_rounded,
      rarity: LabRarity.epic,
      unlockLevel: 15,
    ),
    LabItem(
      id: 'bg_futuristic',
      name: 'High-Tech Facility',
      description: 'Cutting-edge research facility with holographic displays',
      lore:
          'The Prometheus Initiative\'s flagship laboratory. Every surface is a potential display, every wall a window into data.',
      price: 5400,
      category: 'background',
      placeholderColor: Colors.black,
      gradientColors: [Colors.black, Color(0xFF1A237E), Color(0xFF00BCD4)],
      icon: Icons.computer,
      rarity: LabRarity.epic,
      unlockLevel: 20,
    ),
    LabItem(
      id: 'bg_underwater',
      name: 'Deep Sea Research',
      description: 'Underwater laboratory with bioluminescent marine life',
      lore:
          'Located at the Mariana Trench\'s Edge. Bioluminescent creatures drift past the reinforced viewports, casting ever-changing colored light.',
      price: 7500,
      category: 'background',
      placeholderColor: Color(0xFF006064),
      gradientColors: [Color(0xFF006064), Color(0xFF00838F), Color(0xFF0097A7)],
      icon: Icons.water,
      rarity: LabRarity.legendary,
      unlockLevel: 25,
    ),
    LabItem(
      id: 'bg_space',
      name: 'Deep Space Station',
      description: 'Orbiting space station lab with nebula vistas',
      lore:
          'Station Kepler-442b orbits a dying star. The nebula outside provides a natural prism, splitting starlight into colors that don\'t exist on Earth.',
      price: 9000,
      category: 'background',
      placeholderColor: Color(0xFF0D0D2B),
      gradientColors: [Color(0xFF0D0D2B), Color(0xFF1A0533), Color(0xFF00B0FF)],
      icon: Icons.rocket_launch_rounded,
      rarity: LabRarity.legendary,
      unlockLevel: 40,
    ),

    // ═══════════════════════════════════════════════════════════════════════════
    // STANDS
    // ═══════════════════════════════════════════════════════════════════════════
    LabItem(
      id: 'stand_basic',
      name: 'Standard Stand',
      description: 'Basic metal laboratory stand',
      lore:
          'Functional. Reliable. Nothing fancy — and that\'s exactly the point.',
      price: 0,
      category: 'stand',
      placeholderColor: Colors.grey,
      icon: Icons.table_chart,
      rarity: LabRarity.common,
    ),
    LabItem(
      id: 'stand_chrome',
      name: 'Chrome Finish',
      description: 'Polished chrome stand with modern aesthetic',
      lore:
          'Triple-electroplated chromium finish. Reflects the beaker\'s contents with mirror-like clarity.',
      price: 900,
      category: 'stand',
      placeholderColor: Color(0xFFE0E0E0),
      gradientColors: [Color(0xFFE0E0E0), Color(0xFFBDBDBD)],
      icon: Icons.brightness_7,
      rarity: LabRarity.rare,
    ),
    LabItem(
      id: 'stand_wood',
      name: 'Wooden Artisan',
      description: 'Handcrafted wooden stand with natural grain',
      lore:
          'Carved from 500-year-old Sequoia heartwood by master craftsman Elias Vorn. No two are exactly alike.',
      price: 1500,
      category: 'stand',
      placeholderColor: Color(0xFF8D6E63),
      gradientColors: [Color(0xFF8D6E63), Color(0xFF6D4C41)],
      icon: Icons.deck,
      rarity: LabRarity.rare,
      unlockLevel: 5,
    ),
    LabItem(
      id: 'stand_holo',
      name: 'Holographic',
      description: 'Floating holographic projection stand',
      lore:
          'The beaker appears to float within a hard-light holographic cradle. The projection field also acts as a secondary containment system.',
      price: 3000,
      category: 'stand',
      placeholderColor: Color(0xFF00E5FF),
      gradientColors: [Color(0xFF00E5FF), Color(0xFF00B8D4)],
      icon: Icons.blur_on,
      rarity: LabRarity.epic,
      unlockLevel: 12,
    ),
    LabItem(
      id: 'stand_crystal',
      name: 'Crystal Pedestal',
      description: 'Translucent crystal pedestal with prismatic glow',
      lore:
          'A single flawless crystal, laser-cut along its natural cleavage planes. Internal inclusions refract light into miniature rainbows.',
      price: 4500,
      category: 'stand',
      placeholderColor: Color(0xFF80DEEA),
      gradientColors: [Color(0xFF80DEEA), Color(0xFFB2EBF2), Color(0xFF00BCD4)],
      icon: Icons.diamond_outlined,
      rarity: LabRarity.epic,
      unlockLevel: 18,
    ),
    LabItem(
      id: 'stand_levitate',
      name: 'Anti-Gravity',
      description: 'Magnetic levitation stand with zero contact',
      lore:
          'Superconducting magnets cooled to near absolute zero create a stable levitation field. The beaker floats, untouched by anything.',
      price: 6000,
      category: 'stand',
      placeholderColor: Color(0xFFAA00FF),
      gradientColors: [Color(0xFFAA00FF), Color(0xFF6200EA)],
      icon: Icons.flight_takeoff,
      rarity: LabRarity.epic,
      unlockLevel: 22,
    ),
    LabItem(
      id: 'stand_obsidian',
      name: 'Obsidian Throne',
      description: 'Imposing dark volcanic rock stand with ember veins',
      lore:
          'Carved from a single block of volcanic glass from the summit of Olympus Mons. Ember veins pulse with geothermal energy from within.',
      price: 7500,
      category: 'stand',
      placeholderColor: Color(0xFF212121),
      gradientColors: [Color(0xFF212121), Color(0xFF4E0000), Color(0xFF212121)],
      icon: Icons.chair_rounded,
      rarity: LabRarity.legendary,
      unlockLevel: 30,
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
