import 'dart:math';

/// Event rarity levels for random events
enum EventRarity {
  common, // 50% probability
  uncommon, // 30% probability
  rare, // 15% probability
  epic, // 5% probability
}

/// Configuration for a random event
class EventConfig {
  final String id;
  final EventRarity rarity;
  final double baseDuration; // Base duration in seconds
  final bool isPositive; // Whether this is a beneficial event

  const EventConfig({
    required this.id,
    required this.rarity,
    required this.baseDuration,
    this.isPositive = false,
  });
}

/// Manages random event selection with weighted probabilities
class EventRaritySystem {
  static final Random _random = Random();

  /// All available events with their configurations
  static const List<EventConfig> events = [
    // Common Events (50% total, ~6.25% each)
    EventConfig(id: 'glitch', rarity: EventRarity.common, baseDuration: 6.0),
    EventConfig(id: 'unstable', rarity: EventRarity.common, baseDuration: 6.0),
    EventConfig(
      id: 'earthquake',
      rarity: EventRarity.common,
      baseDuration: 5.0,
    ),
    EventConfig(id: 'ui_glitch', rarity: EventRarity.common, baseDuration: 7.0),
    EventConfig(
      id: 'evaporation_short',
      rarity: EventRarity.common,
      baseDuration: 5.0,
    ),
    EventConfig(
      id: 'inverted_short',
      rarity: EventRarity.common,
      baseDuration: 6.0,
    ),
    EventConfig(
      id: 'color_blind_short',
      rarity: EventRarity.common,
      baseDuration: 6.0,
    ),
    EventConfig(
      id: 'gravity_flux',
      rarity: EventRarity.common,
      baseDuration: 7.0,
    ),

    // Uncommon Events (30% total, ~6% each)
    EventConfig(
      id: 'blackout',
      rarity: EventRarity.uncommon,
      baseDuration: 10.0,
    ),
    EventConfig(id: 'mirror', rarity: EventRarity.uncommon, baseDuration: 10.0),
    EventConfig(id: 'wind', rarity: EventRarity.uncommon, baseDuration: 10.0),
    EventConfig(id: 'leak', rarity: EventRarity.uncommon, baseDuration: 12.0),
    EventConfig(
      id: 'evaporation_long',
      rarity: EventRarity.uncommon,
      baseDuration: 10.0,
    ),

    // Rare Events (15% total, ~7.5% each)
    EventConfig(
      id: 'time_freeze',
      rarity: EventRarity.rare,
      baseDuration: 12.0,
      isPositive: true,
    ),
    EventConfig(
      id: 'double_coins',
      rarity: EventRarity.rare,
      baseDuration: 15.0,
      isPositive: true,
    ),

    // Epic Events (5% total)
    EventConfig(
      id: 'chaos_cascade',
      rarity: EventRarity.epic,
      baseDuration: 18.0,
    ),
  ];

  /// Get weighted random event based on rarity
  static EventConfig getRandomEvent() {
    // Calculate total weight
    final weights = <EventRarity, double>{
      EventRarity.common: 50.0,
      EventRarity.uncommon: 30.0,
      EventRarity.rare: 15.0,
      EventRarity.epic: 5.0,
    };

    // First, select rarity tier
    double roll = _random.nextDouble() * 100;
    EventRarity selectedRarity;

    if (roll < weights[EventRarity.common]!) {
      selectedRarity = EventRarity.common;
    } else if (roll <
        weights[EventRarity.common]! + weights[EventRarity.uncommon]!) {
      selectedRarity = EventRarity.uncommon;
    } else if (roll <
        weights[EventRarity.common]! +
            weights[EventRarity.uncommon]! +
            weights[EventRarity.rare]!) {
      selectedRarity = EventRarity.rare;
    } else {
      selectedRarity = EventRarity.epic;
    }

    // Get all events of selected rarity
    final eventsOfRarity = events
        .where((e) => e.rarity == selectedRarity)
        .toList();

    // Return random event from that rarity tier
    return eventsOfRarity[_random.nextInt(eventsOfRarity.length)];
  }

  /// Calculate duration based on game mode
  static double getDuration(EventConfig event, String gameMode) {
    double duration = event.baseDuration;

    // Mode modifiers
    switch (gameMode) {
      case 'chaosLab':
        duration *= 0.7; // 30% shorter in Chaos Lab
        break;
      case 'timeAttack':
        duration *= 1.2; // 20% longer in Time Attack
        break;
      default:
        // Classic mode uses base duration
        break;
    }

    return duration;
  }
}
