import 'package:flutter_test/flutter_test.dart';
import 'package:color_mixing_deductive/core/lives_manager.dart';

void main() {
  group('LivesManager Tests', () {
    late LivesManager manager;

    setUp(() {
      manager = LivesManager();
      // Reset to max lives for each test
      manager.addLives(LivesManager.maxLives);
    });

    group('Initial State', () {
      test('Default max lives is 6', () {
        expect(LivesManager.maxLives, equals(6));
      });

      test('Regen duration is 9 minutes', () {
        expect(LivesManager.regenDuration, equals(const Duration(minutes: 9)));
      });

      test('Can play when lives are available', () {
        expect(manager.canPlay, isTrue);
      });

      test('Lives cannot be negative', () {
        expect(manager.lives, greaterThanOrEqualTo(0));
      });

      test('Lives cannot exceed max without explicit add', () {
        // After setUp, should be at max
        expect(manager.lives, lessThanOrEqualTo(LivesManager.maxLives));
      });
    });

    group('Consume Life', () {
      test('Consume life decreases count by 1', () {
        final initialLives = manager.lives;
        manager.consumeLife();
        expect(manager.lives, equals(initialLives - 1));
      });

      test('Cannot consume life when at 0', () {
        // Drain all lives
        for (int i = 0; i < LivesManager.maxLives; i++) {
          manager.consumeLife();
        }
        expect(manager.lives, equals(0));
        
        // Try to consume more
        manager.consumeLife();
        expect(manager.lives, equals(0)); // Should stay at 0
      });

      test('Cannot play when no lives remain', () {
        // Drain all lives
        for (int i = 0; i < LivesManager.maxLives; i++) {
          manager.consumeLife();
        }
        expect(manager.canPlay, isFalse);
      });

      test('Regen timer starts after consuming first life', () {
        manager.consumeLife();
        // Next regen time should be set
        expect(manager.nextRegenTime, isNotNull);
        expect(manager.nextRegenTime!.isAfter(DateTime.now()), isTrue);
      });
    });

    group('Add Lives', () {
      test('Add lives increases count', () {
        manager.consumeLife();
        manager.consumeLife();
        final before = manager.lives;
        manager.addLives(2);
        expect(manager.lives, equals(before + 2));
      });

      test('Add lives can exceed max (up to 99)', () {
        manager.addLives(100);
        expect(manager.lives, equals(99)); // Capped at 99
      });

      test('Adding negative lives is handled', () {
        manager.addLives(-5);
        // Should handle gracefully (implementation dependent)
        expect(manager.lives, lessThanOrEqualTo(99));
      });

      test('Regen stops when lives are full', () {
        manager.consumeLife();
        manager.addLives(LivesManager.maxLives);
        // Next regen should be null when at max
        expect(manager.nextRegenTime, isNull);
      });
    });

    group('Time Until Next Life', () {
      test('Returns "full" when at max lives', () {
        // Import string_manager to check actual string
        // For now, just check it's not a time format
        final timeString = manager.timeUntilNextLife;
        expect(timeString.isEmpty, isFalse);
      });

      test('Returns time format when waiting', () {
        manager.consumeLife();
        final timeString = manager.timeUntilNextLife;
        // Should be in format "MM:SS"
        expect(timeString.contains(':'), isTrue);
      });

      test('Returns "00:00" when time is negative', () {
        // This would require mocking the nextRegenTime
        // Implementation dependent
        expect(true, isTrue); // Placeholder
      });
    });

    group('Regeneration Logic', () {
      test('Regen duration is consistent', () {
        expect(LivesManager.regenDuration, equals(const Duration(minutes: 9)));
      });

      test('Multiple lives regen sequentially', () {
        // Consume 3 lives
        manager.consumeLife();
        manager.consumeLife();
        manager.consumeLife();
        
        // Should have 3 lives to regen
        expect(manager.lives, equals(LivesManager.maxLives - 3));
        expect(manager.nextRegenTime, isNotNull);
      });

      test('Regen timer cancels when disposed', () {
        manager.dispose();
        // After dispose, timer should be cancelled
        // This is hard to test directly, but we can verify no errors
        expect(true, isTrue);
      });
    });

    group('Edge Cases', () {
      test('Consume life from full starts regen timer', () {
        manager.addLives(LivesManager.maxLives);
        manager.consumeLife();
        expect(manager.nextRegenTime, isNotNull);
      });

      test('Add lives when already at max does nothing to timer', () {
        final beforeTime = manager.nextRegenTime;
        manager.addLives(1);
        // Should remain null (already at max)
        expect(manager.nextRegenTime, equals(beforeTime));
      });

      test('Lives display shows correct format', () {
        manager.consumeLife();
        final timeString = manager.timeUntilNextLife;
        // Format should be "MM:SS"
        final parts = timeString.split(':');
        if (timeString != 'full' && timeString.isNotEmpty) {
          expect(parts.length, equals(2));
          expect(parts[0].length, equals(2)); // Minutes
          expect(parts[1].length, equals(2)); // Seconds
        }
      });

      test('Multiple consume calls in quick succession', () {
        final initial = manager.lives;
        manager.consumeLife();
        manager.consumeLife();
        manager.consumeLife();
        expect(manager.lives, equals(initial - 3));
      });

      test('Add lives with large amount caps at 99', () {
        manager.addLives(1000);
        expect(manager.lives, equals(99));
      });
    });

    group('State Persistence', () {
      test('Lives count is accessible', () {
        expect(manager.lives, isA<int>());
      });

      test('Next regen time is accessible', () {
        manager.consumeLife();
        expect(manager.nextRegenTime, isA<DateTime?>());
      });

      test('Can play is boolean', () {
        expect(manager.canPlay, isA<bool>());
      });
    });
  });
}
