import 'dart:math';
import 'package:color_mixing_deductive/helpers/string_manager.dart';

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
  final String labelKey; // Localization key for display name
  final String icon; // Emoji icon shown in the alert

  const EventConfig({
    required this.id,
    required this.rarity,
    required this.baseDuration,
    this.isPositive = false,
    required this.labelKey,
    required this.icon,
  });

  /// Human-readable rarity label key
  String get rarityKey {
    switch (rarity) {
      case EventRarity.common:
        return AppStrings.rarityCommon;
      case EventRarity.uncommon:
        return AppStrings.rarityUncommon;
      case EventRarity.rare:
        return AppStrings.rarityRare;
      case EventRarity.epic:
        return AppStrings.rarityEpic;
    }
  }
}

/// Manages random event selection with weighted probabilities
class EventRaritySystem {
  static final Random _random = Random();

  /// All available events with their configurations
  static const List<EventConfig> events = [
    // Common Events (50% total, ~6.25% each)
    EventConfig(
      id: 'glitch',
      rarity: EventRarity.common,
      baseDuration: 6.0,
      labelKey: AppStrings.eventGlitch,
      icon: '⚡',
    ),
    EventConfig(
      id: 'unstable',
      rarity: EventRarity.common,
      baseDuration: 6.0,
      labelKey: AppStrings.eventUnstable,
      icon: '🧪',
    ),
    EventConfig(
      id: 'earthquake',
      rarity: EventRarity.common,
      baseDuration: 5.0,
      labelKey: AppStrings.eventEarthquake,
      icon: '🌍',
    ),
    EventConfig(
      id: 'ui_glitch',
      rarity: EventRarity.common,
      baseDuration: 7.0,
      labelKey: AppStrings.eventUiGlitch,
      icon: '💻',
    ),
    EventConfig(
      id: 'evaporation_short',
      rarity: EventRarity.common,
      baseDuration: 5.0,
      labelKey: AppStrings.eventEvaporationShort,
      icon: '💨',
    ),
    EventConfig(
      id: 'inverted_short',
      rarity: EventRarity.common,
      baseDuration: 6.0,
      labelKey: AppStrings.eventInvertedShort,
      icon: '🔄',
    ),
    EventConfig(
      id: 'color_blind_short',
      rarity: EventRarity.common,
      baseDuration: 6.0,
      labelKey: AppStrings.eventColorBlindShort,
      icon: '👁',
    ),
    EventConfig(
      id: 'gravity_flux',
      rarity: EventRarity.common,
      baseDuration: 7.0,
      labelKey: AppStrings.eventGravityFlux,
      icon: '🌀',
    ),

    // Uncommon Events (30% total, ~6% each)
    EventConfig(
      id: 'blackout',
      rarity: EventRarity.uncommon,
      baseDuration: 10.0,
      labelKey: AppStrings.eventBlackout,
      icon: '🔦',
    ),
    EventConfig(
      id: 'mirror',
      rarity: EventRarity.uncommon,
      baseDuration: 10.0,
      labelKey: AppStrings.eventMirror,
      icon: '🪞',
    ),
    EventConfig(
      id: 'wind',
      rarity: EventRarity.uncommon,
      baseDuration: 10.0,
      labelKey: AppStrings.eventWind,
      icon: '🌬',
    ),
    EventConfig(
      id: 'leak',
      rarity: EventRarity.uncommon,
      baseDuration: 12.0,
      labelKey: AppStrings.eventLeak,
      icon: '💧',
    ),
    EventConfig(
      id: 'digital_spike',
      rarity: EventRarity.uncommon,
      baseDuration: 8.0,
      labelKey: AppStrings.eventDigitalSpike,
      icon: '⚡',
    ),
    EventConfig(
      id: 'evaporation_long',
      rarity: EventRarity.uncommon,
      baseDuration: 10.0,
      labelKey: AppStrings.eventEvaporationLong,
      icon: '☁',
    ),

    // Rare Events (15% total, ~7.5% each)
    EventConfig(
      id: 'time_freeze',
      rarity: EventRarity.rare,
      baseDuration: 12.0,
      isPositive: true,
      labelKey: AppStrings.eventTimeFreeze,
      icon: '❄',
    ),
    EventConfig(
      id: 'double_coins',
      rarity: EventRarity.rare,
      baseDuration: 15.0,
      isPositive: true,
      labelKey: AppStrings.eventDoubleCoins,
      icon: '💰',
    ),

    // Epic Events (5% total)
    EventConfig(
      id: 'chaos_cascade',
      rarity: EventRarity.epic,
      baseDuration: 18.0,
      labelKey: AppStrings.eventChaosCascade,
      icon: '☠',
    ),
    EventConfig(
      id: 'system_meltdown',
      rarity: EventRarity.epic,
      baseDuration: 20.0,
      labelKey: AppStrings.eventSystemMeltdown,
      icon: '🔥',
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
