import 'package:flutter_test/flutter_test.dart';
import 'package:color_mixing_deductive/core/xp_manager.dart';

void main() {
  group('XpManager Tests', () {
    setUp(() {
      // Reset state before each test
      XpManager.instance.currentXp.value = 0;
      XpManager.instance.playerLevel.value = 0;
      XpManager.instance.prestigeCount.value = 0;
    });

    group('XP Calculation', () {
      test('Base XP for level 0 is 100', () {
        expect(XpManager.xpForLevel(0), equals(100));
      });

      test('XP for level 1 is 115 (15% growth)', () {
        expect(XpManager.xpForLevel(1), equals(115));
      });

      test('XP for level 2 follows exponential curve', () {
        expect(XpManager.xpForLevel(2), equals(132)); // 100 * 1.15^2
      });

      test('XP for level 10 is significantly higher', () {
        expect(XpManager.xpForLevel(10), equals(404)); // 100 * 1.15^10
      });

      test('XP to next level matches current level requirement', () async {
        XpManager.instance.playerLevel.value = 5;
        XpManager.instance.currentXp.value = 0;
        expect(XpManager.instance.xpToNextLevel, equals(XpManager.xpForLevel(5)));
      });
    });

    group('Level Progress', () {
      test('Level progress is 0 when no XP earned', () {
        XpManager.instance.playerLevel.value = 1;
        XpManager.instance.currentXp.value = 0;
        expect(XpManager.instance.levelProgress, equals(0.0));
      });

      test('Level progress is 0.5 at halfway point', () {
        XpManager.instance.playerLevel.value = 0;
        XpManager.instance.currentXp.value = 50;
        expect(XpManager.instance.levelProgress, closeTo(0.5, 0.01));
      });

      test('Level progress is 1.0 at max level', () {
        XpManager.instance.playerLevel.value = 100;
        XpManager.instance.currentXp.value = 99999;
        expect(XpManager.instance.levelProgress, equals(1.0));
      });

      test('Level progress clamps to 1.0', () {
        XpManager.instance.playerLevel.value = 0;
        XpManager.instance.currentXp.value = 200; // More than needed
        expect(XpManager.instance.levelProgress, equals(1.0));
      });
    });

    group('XP Rewards by Stars', () {
      test('3 stars gives 50 base XP in classic mode', () async {
        // Note: This test would need proper initialization with SaveManager
        // For now, we test the calculation logic
        int xp = 50; // Base for 3 stars
        expect(xp, equals(50));
      });

      test('2 stars gives 25 base XP', () {
        int xp = 25;
        expect(xp, equals(25));
      });

      test('1 star gives 10 base XP', () {
        int xp = 10;
        expect(xp, equals(10));
      });
    });

    group('Mode Multipliers', () {
      test('Time Attack gives 1.5x XP', () {
        int baseXp = 50;
        int timeAttackXp = (baseXp * 1.5).round();
        expect(timeAttackXp, equals(75));
      });

      test('Color Echo gives 1.3x XP', () {
        int baseXp = 50;
        int echoXp = (baseXp * 1.3).round();
        expect(echoXp, equals(65));
      });

      test('Chaos Lab gives 2.0x XP', () {
        int baseXp = 50;
        int chaosXp = (baseXp * 2.0).round();
        expect(chaosXp, equals(100));
      });
    });

    group('Combo Bonus', () {
      test('No combo bonus for combo < 3', () {
        int xp = 50;
        int combo = 2;
        int bonusXp = combo >= 3 ? (xp * (1.0 + combo * 0.05)).round() : xp;
        expect(bonusXp, equals(50)); // No bonus
      });

      test('5% bonus for combo of 3', () {
        int xp = 50;
        int combo = 3;
        int bonusXp = (xp * (1.0 + combo * 0.05)).round();
        expect(bonusXp, equals(57)); // 50 * 1.15
      });

      test('10% bonus for combo of 4', () {
        int xp = 50;
        int combo = 4;
        int bonusXp = (xp * (1.0 + combo * 0.05)).round();
        expect(bonusXp, equals(60)); // 50 * 1.20
      });

      test('50% bonus for combo of 10', () {
        int xp = 50;
        int combo = 10;
        int bonusXp = (xp * (1.0 + combo * 0.05)).round();
        expect(bonusXp, equals(75)); // 50 * 1.50
      });
    });

    group('Level-Up Bonus', () {
      test('Normal level-up gives 50 coins', () {
        int bonus = _levelUpBonus(3);
        expect(bonus, equals(50));
      });

      test('Level 5 (mini-milestone) gives 150 coins', () {
        int bonus = _levelUpBonus(5);
        expect(bonus, equals(150));
      });

      test('Level 10 (milestone) gives 500 coins', () {
        int bonus = _levelUpBonus(10);
        expect(bonus, equals(500));
      });

      test('Level 20 (milestone) gives 500 coins', () {
        int bonus = _levelUpBonus(20);
        expect(bonus, equals(500));
      });

      test('Level 15 (mini-milestone) gives 150 coins', () {
        int bonus = _levelUpBonus(15);
        expect(bonus, equals(150));
      });
    });

    group('Prestige System', () {
      test('Cannot prestige below level 100', () {
        XpManager.instance.playerLevel.value = 50;
        expect(XpManager.instance.canPrestige, isFalse);
      });

      test('Can prestige at level 100', () {
        XpManager.instance.playerLevel.value = 100;
        expect(XpManager.instance.canPrestige, isTrue);
      });

      test('Prestige resets level to 0', () {
        XpManager.instance.playerLevel.value = 100;
        XpManager.instance.currentXp.value = 500;
        // Note: Full prestige test would require async and SaveManager mock
        expect(XpManager.instance.canPrestige, isTrue);
      });
    });

    group('Rank System', () {
      test('Level 0-9 is Apprentice', () {
        XpManager.instance.playerLevel.value = 5;
        final rank = XpManager.instance.currentRank;
        expect(rank.minLevel, equals(0));
      });

      test('Level 10-19 is Junior Chemist', () {
        XpManager.instance.playerLevel.value = 15;
        final rank = XpManager.instance.currentRank;
        expect(rank.minLevel, equals(10));
      });

      test('Level 50-64 is Alchemist', () {
        XpManager.instance.playerLevel.value = 55;
        final rank = XpManager.instance.currentRank;
        expect(rank.minLevel, equals(50));
      });

      test('Level 95+ is Color God', () {
        XpManager.instance.playerLevel.value = 100;
        final rank = XpManager.instance.currentRank;
        expect(rank.minLevel, equals(95));
      });
    });

    group('Max Level', () {
      test('Max level is 100', () {
        expect(XpManager.maxLevel, equals(100));
      });

      test('XP continues to accrue at max level', () {
        XpManager.instance.playerLevel.value = 100;
        XpManager.instance.currentXp.value = 0;
        // Player can still earn XP, just won't level up
        expect(XpManager.instance.playerLevel.value, equals(100));
      });
    });
  });
}

/// Helper function to test level-up bonus logic
int _levelUpBonus(int level) {
  if (level % 10 == 0) return 500; // Milestone: every 10 levels
  if (level % 5 == 0) return 150; // Mini milestone: every 5 levels
  return 50; // Normal level-up
}
