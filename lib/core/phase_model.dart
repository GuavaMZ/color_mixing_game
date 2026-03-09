import 'package:flutter/material.dart';
import '../helpers/string_manager.dart';

// ─── Phase Model ──────────────────────────────────────────────────────────────

/// Represents a phase in the classic mode level progression.
/// Phases are organized by the number of colors used in each level:
///   Phase 1 → 1 color  → C(5,1) = 5  combos
///   Phase 2 → 2 colors → C(5,2) = 10 combos
///   Phase 3 → 3 colors → C(5,3) = 10 combos
///   Phase 4 → 4 colors → C(5,4) = 5  combos
///   Phase 5 → 5 colors → C(5,5) = 1  combo (variants)
class PhaseModel {
  /// 1-based phase number
  final int id;

  /// Human-readable display name key (localization key)
  final String nameKey;

  /// Short description key (localization key)
  final String descKey;

  /// Icon representing the phase
  final IconData icon;

  /// Brand color for this phase's UI
  final Color color;

  /// Number of colors involved in each level of this phase
  final int colorCount;

  const PhaseModel({
    required this.id,
    required this.nameKey,
    required this.descKey,
    required this.icon,
    required this.color,
    required this.colorCount,
  });
}

// ─── Phase Catalog ────────────────────────────────────────────────────────────

class PhaseCatalog {
  static const List<PhaseModel> all = [
    PhaseModel(
      id: 1,
      nameKey: AppStrings.phase1Name,
      descKey: AppStrings.phase1Desc,
      icon: Icons.circle_rounded,
      color: Color(0xFF64B5F6), // Light blue
      colorCount: 1,
    ),
    PhaseModel(
      id: 2,
      nameKey: AppStrings.phase2Name,
      descKey: AppStrings.phase2Desc,
      icon: Icons.merge_rounded,
      color: Color(0xFF81C784), // Light green
      colorCount: 2,
    ),
    PhaseModel(
      id: 3,
      nameKey: AppStrings.phase3Name,
      descKey: AppStrings.phase3Desc,
      icon: Icons.blur_on_rounded,
      color: Color(0xFFFFD54F), // Amber
      colorCount: 3,
    ),
    PhaseModel(
      id: 4,
      nameKey: AppStrings.phase4Name,
      descKey: AppStrings.phase4Desc,
      icon: Icons.auto_awesome_rounded,
      color: Color(0xFFFF8A65), // Deep orange
      colorCount: 4,
    ),
    PhaseModel(
      id: 5,
      nameKey: AppStrings.phase5Name,
      descKey: AppStrings.phase5Desc,
      icon: Icons.science_rounded,
      color: Color(0xFFCE93D8), // Purple
      colorCount: 5,
    ),
  ];

  static PhaseModel byId(int id) => all.firstWhere((p) => p.id == id);
}
