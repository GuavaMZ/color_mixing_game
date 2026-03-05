import 'dart:math';
import 'package:flutter/material.dart';
import 'package:color_mixing_deductive/core/save_manager.dart';

enum CardRarity { common, rare, epic, legendary }

class CardDef {
  final String id;
  final String name;
  final String hexColor;
  final CardRarity rarity;
  final String description;

  const CardDef({
    required this.id,
    required this.name,
    required this.hexColor,
    required this.rarity,
    required this.description,
  });

  Color get color => Color(int.parse(hexColor.replaceFirst('#', '0xFF')));
}

class CardCollectionManager {
  // Singleton
  CardCollectionManager._();
  static final CardCollectionManager instance = CardCollectionManager._();

  static const String _saveKey = 'collected_cards_v1';

  // State
  final Set<String> _unlockedCardIds = {};

  /// Expose the unlocked IDs
  Set<String> get unlockedIds => Set.unmodifiable(_unlockedCardIds);

  /// Fires when a new card is unlocked
  final ValueNotifier<CardDef?> newlyUnlockedCard = ValueNotifier(null);

  Future<void> init() async {
    final list = await SaveManager.getStringList(_saveKey) ?? [];
    _unlockedCardIds.clear();
    _unlockedCardIds.addAll(list);
  }

  bool isUnlocked(String id) => _unlockedCardIds.contains(id);

  /// Unlocks a card and saves it. Returns true if it was newly unlocked.
  Future<bool> unlockCard(String id) async {
    if (_unlockedCardIds.contains(id)) return false;

    // Validate it exists
    final def = CardCatalog.getById(id);
    if (def == null) return false;

    _unlockedCardIds.add(id);
    await SaveManager.saveStringList(_saveKey, _unlockedCardIds.toList());

    // Trigger event
    newlyUnlockedCard.value = def;
    // reset null so the event can fire again for the exact same card in worst case (though it won't be new)
    Future.microtask(() => newlyUnlockedCard.value = null);

    return true;
  }

  /// RNG unlock for a random missing card.
  /// If [guaranteeRarity] is provided, attempts to find a missing card of that rarity.
  Future<CardDef?> dropRandomCard({CardRarity? guaranteeRarity}) async {
    List<CardDef> available = [];

    if (guaranteeRarity != null) {
      available = CardCatalog.allCards
          .where(
            (c) =>
                c.rarity == guaranteeRarity && !_unlockedCardIds.contains(c.id),
          )
          .toList();
    }

    // Fallback if no specific rarity requested or none available of that rarity
    if (available.isEmpty) {
      available = CardCatalog.allCards
          .where((c) => !_unlockedCardIds.contains(c.id))
          .toList();
    }

    if (available.isEmpty) return null; // All cards collected

    // Apply weighted drop logic if no specific guarantee
    if (guaranteeRarity == null) {
      double chance = Random().nextDouble();
      CardRarity targetRarity = CardRarity.common;

      if (chance > 0.95) {
        targetRarity = CardRarity.legendary; // 5%
      } else if (chance > 0.85) {
        targetRarity = CardRarity.epic; // 10%
      } else if (chance > 0.55) {
        targetRarity = CardRarity.rare; // 30%
      }

      // Try to find missing of the target rarity
      var subset = available.where((c) => c.rarity == targetRarity).toList();
      if (subset.isNotEmpty) {
        available = subset;
      }
    }

    final rolled = available[Random().nextInt(available.length)];
    await unlockCard(rolled.id);
    return rolled;
  }
}

class CardCatalog {
  static CardDef? getById(String id) {
    try {
      return allCards.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  static const List<CardDef> allCards = [
    // ─── LEGENDARY (5) ──────────────────────────────────────────────────────────
    CardDef(
      id: 'c_vantablack',
      name: 'Vantablack',
      hexColor: '#000000',
      rarity: CardRarity.legendary,
      description:
          'Absorbs 99.96% of visible light. The closest thing to staring into a black hole on Earth.',
    ),
    CardDef(
      id: 'c_ylnmn_blue',
      name: 'YInMn Blue',
      hexColor: '#2E5090',
      rarity: CardRarity.legendary,
      description:
          'Discovered accidentally in 2009 by heating chemicals to 2000°F. The first new blue pigment in 200 years.',
    ),
    CardDef(
      id: 'c_tyrian_purple',
      name: 'Tyrian Purple',
      hexColor: '#66023C',
      rarity: CardRarity.legendary,
      description:
          'Extracted from rotting sea snails. In ancient Rome, it was worth its weight in silver and reserved only for emperors.',
    ),
    CardDef(
      id: 'c_lapis_lazuli',
      name: 'Lapis Lazuli',
      hexColor: '#26619C',
      rarity: CardRarity.legendary,
      description:
          'Ground from semi-precious stone. During the Renaissance, it was more expensive than gold and used only for the robes of angels and the Virgin Mary.',
    ),
    CardDef(
      id: 'c_mummy_brown',
      name: 'Mummy Brown',
      hexColor: '#8F4B28',
      rarity: CardRarity.legendary,
      description:
          'A rich pigment made from actual ground-up Egyptian mummies. Its use declined in the 19th century when artists realized what it was made of.',
    ),

    // ─── EPIC (10) ──────────────────────────────────────────────────────────────
    CardDef(
      id: 'c_scheeles_green',
      name: 'Scheele\'s Green',
      hexColor: '#3A7D18',
      rarity: CardRarity.epic,
      description:
          'A vibrant green invented in 1775, laced with deadly arsenic. Suspected to have poisoned Napoleon Bonaparte in his wallpaper.',
    ),
    CardDef(
      id: 'c_dragon_blood',
      name: 'Dragon\'s Blood',
      hexColor: '#8A0303',
      rarity: CardRarity.epic,
      description:
          'A bright red resin obtained from the Daemonorops draco tree. Romans believed it was the actual blood of dragons slain by elephants.',
    ),
    CardDef(
      id: 'c_indian_yellow',
      name: 'Indian Yellow',
      hexColor: '#E3A857',
      rarity: CardRarity.epic,
      description:
          'A luminescent yellow made in India by feeding cows only mango leaves and collecting their urine.',
    ),
    CardDef(
      id: 'c_lead_white',
      name: 'Lead White',
      hexColor: '#F5F5F5',
      rarity: CardRarity.epic,
      description:
          'The most opaque white pigment for centuries, though heavily toxic. Caused "painter\'s colic" and lead poisoning in countless artists.',
    ),
    CardDef(
      id: 'c_smalt',
      name: 'Smalt',
      hexColor: '#003399',
      rarity: CardRarity.epic,
      description:
          'Ground blue cobalt glass. Used as a cheaper alternative to ultramarine, but notoriously fades to a dull grey over centuries.',
    ),
    CardDef(
      id: 'c_orsel',
      name: 'Orchil',
      hexColor: '#9B3D92',
      rarity: CardRarity.epic,
      description:
          'A purple dye extracted from lichens mixed with stale ammonia. Used extensively in medieval illuminated manuscripts.',
    ),
    CardDef(
      id: 'c_gamboge',
      name: 'Gamboge',
      hexColor: '#E49B0F',
      rarity: CardRarity.epic,
      description:
          'A brilliant yellow resin from Cambodia. Beautiful but so poisonous it was sometimes used as a harsh purgative in medicine.',
    ),
    CardDef(
      id: 'c_cinnabar',
      name: 'Cinnabar',
      hexColor: '#E34234',
      rarity: CardRarity.epic,
      description:
          'A toxic mercury sulfide ore. Used to make vermilion, the vibrant red seen in ancient Chinese lacquerware.',
    ),
    CardDef(
      id: 'c_maya_blue',
      name: 'Maya Blue',
      hexColor: '#73C2FB',
      rarity: CardRarity.epic,
      description:
          'An incredibly resilient azure blue pigment created by the Maya, able to survive centuries of harsh jungle climate without fading.',
    ),
    CardDef(
      id: 'c_carmine',
      name: 'Carmine',
      hexColor: '#960018',
      rarity: CardRarity.epic,
      description:
          'A deep red derived from crushed cochineal insects. It takes about 70,000 insects to make just one pound of dye.',
    ),

    // ─── RARE (15) ──────────────────────────────────────────────────────────────
    CardDef(
      id: 'c_cobalt_blue',
      name: 'Cobalt Blue',
      hexColor: '#0047AB',
      rarity: CardRarity.rare,
      description:
          'A pure, brilliant blue famously used by Vincent van Gogh in "The Starry Night".',
    ),
    CardDef(
      id: 'c_viridian',
      name: 'Viridian',
      hexColor: '#40826D',
      rarity: CardRarity.rare,
      description:
          'A dark shade of spring green. Replaced the highly toxic emerald green in the 19th century.',
    ),
    CardDef(
      id: 'c_burnt_sienna',
      name: 'Burnt Sienna',
      hexColor: '#E97451',
      rarity: CardRarity.rare,
      description:
          'Earth pigment containing iron oxide. Heating raw sienna drives off water, turning it this rich reddish-brown.',
    ),
    CardDef(
      id: 'c_caput_mortuum',
      name: 'Caput Mortuum',
      hexColor: '#592720',
      rarity: CardRarity.rare,
      description:
          'Literally "Dead Head" in Latin. An iron oxide pigment resembling dried blood, favored for painting shadows.',
    ),
    CardDef(
      id: 'c_han_purple',
      name: 'Han Purple',
      hexColor: '#5218FA',
      rarity: CardRarity.rare,
      description:
          'A synthetic purple pigment created in ancient China over 2,500 years ago, used on the Terracotta Army.',
    ),
    CardDef(
      id: 'c_naples_yellow',
      name: 'Naples Yellow',
      hexColor: '#FADA5E',
      rarity: CardRarity.rare,
      description:
          'One of the oldest synthetic pigments, containing toxic lead and antimony. Used extensively in landscape painting.',
    ),
    CardDef(
      id: 'c_rose_madder',
      name: 'Rose Madder',
      hexColor: '#E32636',
      rarity: CardRarity.rare,
      description:
          'A delicate organic red lake pigment extracted from the root of the madder plant.',
    ),
    CardDef(
      id: 'c_cerulean',
      name: 'Cerulean',
      hexColor: '#007BA7',
      rarity: CardRarity.rare,
      description:
          'A sky-blue pigment highly valued for its stability and resistance to light. Loved by the Impressionists.',
    ),
    CardDef(
      id: 'c_phthalocyanine',
      name: 'Phthalo Blue',
      hexColor: '#000F89',
      rarity: CardRarity.rare,
      description:
          'A synthetic blue pigment with extreme tinting strength. A tiny drop can overpower an entire palette.',
    ),
    CardDef(
      id: 'c_aureolin',
      name: 'Aureolin',
      hexColor: '#FDEE00',
      rarity: CardRarity.rare,
      description:
          'Also known as Cobalt Yellow. A transparent yellow prized by watercolorists, though prone to turning brown over time.',
    ),
    CardDef(
      id: 'c_malachite',
      name: 'Malachite',
      hexColor: '#0BDA51',
      rarity: CardRarity.rare,
      description:
          'The oldest known green pigment. Ground from the beautiful banded copper carbonate mineral.',
    ),
    CardDef(
      id: 'c_realgar',
      name: 'Realgar',
      hexColor: '#E44D2E',
      rarity: CardRarity.rare,
      description:
          'An arsenic sulfide mineral providing a brilliant orange-red. Highly toxic and degrades into a yellow powder when exposed to light.',
    ),
    CardDef(
      id: 'c_bone_black',
      name: 'Bone Black',
      hexColor: '#28282B',
      rarity: CardRarity.rare,
      description:
          'The deepest black available to historical painters, created by charring animal bones in an airless furnace.',
    ),
    CardDef(
      id: 'c_sap_green',
      name: 'Sap Green',
      hexColor: '#507D2A',
      rarity: CardRarity.rare,
      description:
          'Originally made from the juice of ripe buckthorn berries. A fugitive (fading) color loved by landscape painters for foliage.',
    ),
    CardDef(
      id: 'c_alizarin',
      name: 'Alizarin Crimson',
      hexColor: '#E32636',
      rarity: CardRarity.rare,
      description:
          'The first naturally occurring dye to be synthesized in a lab (1868), revolutionizing the textile industry.',
    ),

    // ─── COMMON (30) ────────────────────────────────────────────────────────────
    CardDef(
      id: 'c_ultramarine',
      name: 'Ultramarine',
      hexColor: '#120A8F',
      rarity: CardRarity.common,
      description:
          'A deep blue, formerly made of ground lapis lazuli but synthetically mass-produced today.',
    ),
    CardDef(
      id: 'c_ochre',
      name: 'Yellow Ochre',
      hexColor: '#CB9D06',
      rarity: CardRarity.common,
      description:
          'One of humanity\'s oldest pigments, used in cave paintings dating back over 300,000 years.',
    ),
    CardDef(
      id: 'c_umber',
      name: 'Raw Umber',
      hexColor: '#734A12',
      rarity: CardRarity.common,
      description:
          'A natural brown earth pigment containing iron and manganese. Dries very quickly in oil paint.',
    ),
    CardDef(
      id: 'c_crimson',
      name: 'Crimson',
      hexColor: '#DC143C',
      rarity: CardRarity.common,
      description:
          'A strong, bright, deep red color combined with some blue, resulting in a slightly purple hue.',
    ),
    CardDef(
      id: 'c_cyan',
      name: 'Cyan',
      hexColor: '#00FFFF',
      rarity: CardRarity.common,
      description:
          'One of the three subtractive primary colors. The name comes from the Greek "kyanos", meaning dark blue enamel.',
    ),
    CardDef(
      id: 'c_magenta',
      name: 'Magenta',
      hexColor: '#FF00FF',
      rarity: CardRarity.common,
      description:
          'An extra-spectral color, meaning it doesn\'t exist on the visible spectrum of light. It\'s an illusion created by our brains.',
    ),
    CardDef(
      id: 'c_chartreuse',
      name: 'Chartreuse',
      hexColor: '#7FFF00',
      rarity: CardRarity.common,
      description:
          'A yellow-green color named after a French liqueur created by Carthusian monks in 1605.',
    ),
    CardDef(
      id: 'c_vermilion',
      name: 'Vermilion',
      hexColor: '#E34234',
      rarity: CardRarity.common,
      description:
          'A brilliant red or scarlet pigment originally made from the powdered mineral cinnabar.',
    ),
    CardDef(
      id: 'c_indigo',
      name: 'Indigo',
      hexColor: '#4B0082',
      rarity: CardRarity.common,
      description:
          'A deep midnight blue dye originally sourced from Indigofera plants. The color of classic blue jeans.',
    ),
    CardDef(
      id: 'c_teal',
      name: 'Teal',
      hexColor: '#008080',
      rarity: CardRarity.common,
      description:
          'A deep blue-green color named after the colored area around the eye of the common teal bird.',
    ),
    CardDef(
      id: 'c_sepia',
      name: 'Sepia',
      hexColor: '#704214',
      rarity: CardRarity.common,
      description:
          'A reddish-brown color, named after the rich brown pigment derived from the ink sac of the common cuttlefish.',
    ),
    CardDef(
      id: 'c_sienna',
      name: 'Raw Sienna',
      hexColor: '#D28140',
      rarity: CardRarity.common,
      description:
          'A yellowish-brown earth pigment, named after the city-state of Siena where it was produced during the Renaissance.',
    ),
    CardDef(
      id: 'c_titanium_white',
      name: 'Titanium White',
      hexColor: '#FFFFFF',
      rarity: CardRarity.common,
      description:
          'The most widely used white pigment today. Extremely opaque, brilliant, and non-toxic unlike its lead predecessor.',
    ),
    CardDef(
      id: 'c_prussian_blue',
      name: 'Prussian Blue',
      hexColor: '#003153',
      rarity: CardRarity.common,
      description:
          'The first modern synthetic pigment, discovered by accident in 1704. Used in blueprints and cyanotypes.',
    ),
    CardDef(
      id: 'c_zinc_white',
      name: 'Zinc White',
      hexColor: '#FDFFF5',
      rarity: CardRarity.common,
      description:
          'A transparent white pigment that is excellent for mixing tints without overpowering other colors.',
    ),
    CardDef(
      id: 'c_cadmium_red',
      name: 'Cadmium Red',
      hexColor: '#E30022',
      rarity: CardRarity.common,
      description:
          'A brilliant, warm red pigment that is highly opaque and permanent, though environmentally toxic.',
    ),
    CardDef(
      id: 'c_cadmium_yellow',
      name: 'Cadmium Yellow',
      hexColor: '#FFF600',
      rarity: CardRarity.common,
      description:
          'A vibrant yellow pigment favored by modernists like Matisse for its striking intensity.',
    ),
    CardDef(
      id: 'c_maroon',
      name: 'Maroon',
      hexColor: '#800000',
      rarity: CardRarity.common,
      description:
          'A dark brownish red color taking its name from the French word for chestnut.',
    ),
    CardDef(
      id: 'c_olive',
      name: 'Olive Green',
      hexColor: '#808000',
      rarity: CardRarity.common,
      description:
          'A dark yellowish-green color, akin to that of unripe or green olives.',
    ),
    CardDef(
      id: 'c_periwinkle',
      name: 'Periwinkle',
      hexColor: '#CCCCFF',
      rarity: CardRarity.common,
      description:
          'A pale indigo color that takes its name from the flower of the same name.',
    ),
    CardDef(
      id: 'c_turquoise',
      name: 'Turquoise',
      hexColor: '#40E0D0',
      rarity: CardRarity.common,
      description:
          'An opaque, blue-to-green mineral. The word comes from the French for "Turkish".',
    ),
    CardDef(
      id: 'c_amber',
      name: 'Amber',
      hexColor: '#FFBF00',
      rarity: CardRarity.common,
      description:
          'A pure chroma color located on the color wheel midway between the colors of yellow and orange.',
    ),
    CardDef(
      id: 'c_amethyst',
      name: 'Amethyst',
      hexColor: '#9966CC',
      rarity: CardRarity.common,
      description:
          'A transparent purple color matching the violet variety of quartz.',
    ),
    CardDef(
      id: 'c_emerald',
      name: 'Emerald',
      hexColor: '#50C878',
      rarity: CardRarity.common,
      description:
          'A bright, vivid shade of green resembling the precious gemstone.',
    ),
    CardDef(
      id: 'c_sapphire',
      name: 'Sapphire',
      hexColor: '#0F52BA',
      rarity: CardRarity.common,
      description: 'A deep, brilliant blue matching the corundum gemstone.',
    ),
    CardDef(
      id: 'c_ruby',
      name: 'Ruby',
      hexColor: '#E0115F',
      rarity: CardRarity.common,
      description:
          'A pink to blood-red colored hue representing the ruby gemstone.',
    ),
    CardDef(
      id: 'c_jade',
      name: 'Jade',
      hexColor: '#00A86B',
      rarity: CardRarity.common,
      description:
          'A slightly bluish green. The color of the ornamental mineral jade.',
    ),
    CardDef(
      id: 'c_coral',
      name: 'Coral',
      hexColor: '#FF7F50',
      rarity: CardRarity.common,
      description:
          'A pinkish-orange color deriving its name from the marine invertebrates.',
    ),
    CardDef(
      id: 'c_fuchsia',
      name: 'Fuchsia',
      hexColor: '#FF00FF',
      rarity: CardRarity.common,
      description:
          'A vivid purplish red color, named after the flower of the fuchsia plant.',
    ),
    CardDef(
      id: 'c_lavender',
      name: 'Lavender',
      hexColor: '#E6E6FA',
      rarity: CardRarity.common,
      description:
          'A light, pale purple color matching the flowers of the lavender plant.',
    ),
  ];
}
