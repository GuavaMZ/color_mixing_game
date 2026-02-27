import 'package:flutter/material.dart';
import '../helpers/string_manager.dart';

// ─── Rarity Tier System ──────────────────────────────────────────────────────

enum LabRarity {
  common,
  rare,
  epic,
  legendary;

  String get label {
    switch (this) {
      case LabRarity.common:
        return AppStrings.rarityCommon;
      case LabRarity.rare:
        return AppStrings.rarityRare;
      case LabRarity.epic:
        return AppStrings.rarityEpic;
      case LabRarity.legendary:
        return AppStrings.rarityLegendary;
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
      name: AppStrings.itemSteelName,
      description: AppStrings.itemSteelDesc,
      lore: AppStrings.itemSteelLore,
      price: 0,
      category: 'surface',
      placeholderColor: Colors.grey,
      gradientColors: [Color(0xFF2C3E50), Color(0xFF000000)],
      icon: Icons.grid_4x4,
      rarity: LabRarity.common,
    ),
    LabItem(
      id: 'surface_marble',
      name: AppStrings.itemMarbleName,
      description: AppStrings.itemMarbleDesc,
      lore: AppStrings.itemMarbleLore,
      price: 1200,
      category: 'surface',
      placeholderColor: Colors.white,
      gradientColors: [Color(0xFFE0E0E0), Color(0xFFFFFFFF), Color(0xFFFFD700)],
      icon: Icons.diamond,
      rarity: LabRarity.rare,
    ),
    LabItem(
      id: 'surface_titanium',
      name: AppStrings.itemTitaniumName,
      description: AppStrings.itemTitaniumDesc,
      lore: AppStrings.itemTitaniumLore,
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
      name: AppStrings.itemCyberName,
      description: AppStrings.itemCyberDesc,
      lore: AppStrings.itemCyberLore,
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
      name: AppStrings.itemObsidianName,
      description: AppStrings.itemObsidianDesc,
      lore: AppStrings.itemObsidianLore,
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
      name: AppStrings.itemCrystalName,
      description: AppStrings.itemCrystalDesc,
      lore: AppStrings.itemCrystalLore,
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
      name: AppStrings.itemAuroraName,
      description: AppStrings.itemAuroraDesc,
      lore: AppStrings.itemAuroraLore,
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
      name: AppStrings.itemLightBasicName,
      description: AppStrings.itemLightBasicDesc,
      lore: AppStrings.itemLightBasicLore,
      price: 0,
      category: 'lighting',
      placeholderColor: Colors.yellow,
      icon: Icons.wb_incandescent_outlined,
      rarity: LabRarity.common,
    ),
    LabItem(
      id: 'light_warm',
      name: AppStrings.itemLightWarmName,
      description: AppStrings.itemLightWarmDesc,
      lore: AppStrings.itemLightWarmLore,
      price: 1500,
      category: 'lighting',
      placeholderColor: Colors.orange,
      gradientColors: [Colors.orange, Colors.amber],
      icon: Icons.wb_sunny,
      rarity: LabRarity.rare,
    ),
    LabItem(
      id: 'light_neon_blue',
      name: AppStrings.itemLightNeonName,
      description: AppStrings.itemLightNeonDesc,
      lore: AppStrings.itemLightNeonLore,
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
      name: AppStrings.itemLightRgbName,
      description: AppStrings.itemLightRgbDesc,
      lore: AppStrings.itemLightRgbLore,
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
      name: AppStrings.itemLightPlasmaName,
      description: AppStrings.itemLightPlasmaDesc,
      lore: AppStrings.itemLightPlasmaLore,
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
      name: AppStrings.itemLightBioName,
      description: AppStrings.itemLightBioDesc,
      lore: AppStrings.itemLightBioLore,
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
      name: AppStrings.itemLightSolarName,
      description: AppStrings.itemLightSolarDesc,
      lore: AppStrings.itemLightSolarLore,
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
      name: AppStrings.itemBgDefaultName,
      description: AppStrings.itemBgDefaultDesc,
      lore: AppStrings.itemBgDefaultLore,
      price: 0,
      category: 'background',
      placeholderColor: Colors.blueGrey,
      icon: Icons.science,
      rarity: LabRarity.common,
    ),
    LabItem(
      id: 'bg_nature',
      name: AppStrings.itemBgNatureName,
      description: AppStrings.itemBgNatureDesc,
      lore: AppStrings.itemBgNatureLore,
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
      name: AppStrings.itemBgCyberName,
      description: AppStrings.itemBgCyberDesc,
      lore: AppStrings.itemBgCyberLore,
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
      name: AppStrings.itemBgVolcanoName,
      description: AppStrings.itemBgVolcanoDesc,
      lore: AppStrings.itemBgVolcanoLore,
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
      name: AppStrings.itemBgFuturisticName,
      description: AppStrings.itemBgFuturisticDesc,
      lore: AppStrings.itemBgFuturisticLore,
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
      name: AppStrings.itemBgUnderwaterName,
      description: AppStrings.itemBgUnderwaterDesc,
      lore: AppStrings.itemBgUnderwaterLore,
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
      name: AppStrings.itemBgSpaceName,
      description: AppStrings.itemBgSpaceDesc,
      lore: AppStrings.itemBgSpaceLore,
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
      name: AppStrings.itemStandBasicName,
      description: AppStrings.itemStandBasicDesc,
      lore: AppStrings.itemStandBasicLore,
      price: 0,
      category: 'stand',
      placeholderColor: Colors.grey,
      icon: Icons.table_chart,
      rarity: LabRarity.common,
    ),
    LabItem(
      id: 'stand_chrome',
      name: AppStrings.itemStandChromeName,
      description: AppStrings.itemStandChromeDesc,
      lore: AppStrings.itemStandChromeLore,
      price: 900,
      category: 'stand',
      placeholderColor: Color(0xFFE0E0E0),
      gradientColors: [Color(0xFFE0E0E0), Color(0xFFBDBDBD)],
      icon: Icons.brightness_7,
      rarity: LabRarity.rare,
    ),
    LabItem(
      id: 'stand_wood',
      name: AppStrings.itemStandWoodName,
      description: AppStrings.itemStandWoodDesc,
      lore: AppStrings.itemStandWoodLore,
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
      name: AppStrings.itemStandHoloName,
      description: AppStrings.itemStandHoloDesc,
      lore: AppStrings.itemStandHoloLore,
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
      name: AppStrings.itemStandCrystalName,
      description: AppStrings.itemStandCrystalDesc,
      lore: AppStrings.itemStandCrystalLore,
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
      name: AppStrings.itemStandLevitateName,
      description: AppStrings.itemStandLevitateDesc,
      lore: AppStrings.itemStandLevitateLore,
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
      name: AppStrings.itemStandObsidianName,
      description: AppStrings.itemStandObsidianDesc,
      lore: AppStrings.itemStandObsidianLore,
      price: 7500,
      category: 'stand',
      placeholderColor: Color(0xFF212121),
      gradientColors: [Color(0xFF212121), Color(0xFF4E0000), Color(0xFF212121)],
      icon: Icons.chair_rounded,
      rarity: LabRarity.legendary,
      unlockLevel: 30,
    ),

    // ═══════════════════════════════════════════════════════════════════════════
    // STRING LIGHTS
    // ═══════════════════════════════════════════════════════════════════════════
    LabItem(
      id: 'lights_none',
      name: AppStrings.itemLNoneName,
      description: AppStrings.itemLNoneDesc,
      lore: AppStrings.itemLNoneLore,
      price: 0,
      category: 'string_lights',
      placeholderColor: Colors.transparent,
      icon: Icons.highlight_remove,
      rarity: LabRarity.common,
    ),
    LabItem(
      id: 'lights_warm',
      name: AppStrings.itemLWarmName,
      description: AppStrings.itemLWarmDesc,
      lore: AppStrings.itemLWarmLore,
      price: 1500,
      category: 'string_lights',
      placeholderColor: Color(0xFFFFD54F),
      gradientColors: [Color(0xFFFFA000), Color(0xFFFFD54F)],
      icon: Icons.lightbulb,
      rarity: LabRarity.common,
    ),
    LabItem(
      id: 'lights_neon',
      name: AppStrings.itemLNeonName,
      description: AppStrings.itemLNeonDesc,
      lore: AppStrings.itemLNeonLore,
      price: 3200,
      category: 'string_lights',
      placeholderColor: Color(0xFF00FFFF),
      gradientColors: [Color(0xFF00FFFF), Color(0xFFFF00FF)],
      icon: Icons.wb_twilight,
      rarity: LabRarity.rare,
      unlockLevel: 8,
    ),
    LabItem(
      id: 'lights_bio',
      name: AppStrings.itemLBioName,
      description: AppStrings.itemLBioDesc,
      lore: AppStrings.itemLBioLore,
      price: 5500,
      category: 'string_lights',
      placeholderColor: Color(0xFF00FF00),
      gradientColors: [Color(0xFF00FF00), Color(0xFFB2FF59)],
      icon: Icons.stream,
      rarity: LabRarity.epic,
      unlockLevel: 16,
    ),
    LabItem(
      id: 'lights_starlight',
      name: AppStrings.itemLStarlightName,
      description: AppStrings.itemLStarlightDesc,
      lore: AppStrings.itemLStarlightLore,
      price: 8500,
      category: 'string_lights',
      placeholderColor: Colors.white,
      gradientColors: [Color(0xFFFFFFFF), Color(0xFFE3F2FD)],
      icon: Icons.auto_awesome,
      rarity: LabRarity.legendary,
      unlockLevel: 25,
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
