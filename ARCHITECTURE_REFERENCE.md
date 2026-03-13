# Color Lab - Architecture Quick Reference

## System Overview

```
┌─────────────────────────────────────────────────────────────────────────┐
│                            Flutter Framework                             │
├─────────────────────────────────────────────────────────────────────────┤
│  main.dart                                                               │
│  ┌────────────────────────────────────────────────────────────────┐     │
│  │ MaterialApp                                                     │     │
│  │  ┌──────────────────────────────────────────────────────────┐  │     │
│  │  │ _GameSection (Stack)                                      │  │     │
│  │  │  ┌────────────────────────────────────────────────────┐  │  │     │
│  │  │  │ TransitionOverlay (Top Layer)                      │  │  │     │
│  │  │  └────────────────────────────────────────────────────┘  │  │     │
│  │  │  ┌────────────────────────────────────────────────────┐  │  │     │
│  │  │  │ GameWidget<ColorMixerGame>                         │  │  │     │
│  │  │  │  ┌──────────────────────────────────────────────┐  │  │  │     │
│  │  │  │  │ FlameGame Engine                             │  │  │  │     │
│  │  │  │  │  - Game Loop (update/render)                 │  │  │  │     │
│  │  │  │  │  - Component Tree                            │  │  │  │     │
│  │  │  │  │  - Overlay Manager                           │  │  │  │     │
│  │  │  │  └──────────────────────────────────────────────┘  │  │  │     │
│  │  │  │  ┌──────────────────────────────────────────────┐  │  │  │     │
│  │  │  │  │ 40+ Flutter Overlays                         │  │  │  │     │
│  │  │  │  │  - Menus (MainMenu, Settings, Shop)          │  │  │  │     │
│  │  │  │  │  - HUDs (Controls, ChaosLab, ColorEcho)      │  │  │  │     │
│  │  │  │  │  - Systems (Tutorial, Loading, Transition)   │  │  │  │     │
│  │  │  │  └──────────────────────────────────────────────┘  │  │  │     │
│  │  │  └────────────────────────────────────────────────────┘  │  │     │
│  │  └──────────────────────────────────────────────────────────┘  │     │
│  └────────────────────────────────────────────────────────────────┘     │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## ColorMixerGame Class - State Machine

```
┌──────────────────────────────────────────────────────────────────────┐
│                         ColorMixerGame                                │
│  Extends: FlameGame with ChangeNotifier                              │
├──────────────────────────────────────────────────────────────────────┤
│  Game State                                                           │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐               │
│  │  _hasWon     │  │  _hasLost    │  │ currentMode  │               │
│  │  (bool)      │  │  (bool)      │  │  (GameMode)  │               │
│  └──────────────┘  └──────────────┘  └──────────────┘               │
│                                                                       │
│  Mode States                                                          │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐               │
│  │  timeLeft    │  │  echoRound   │  │  chaosRound  │               │
│  │  (double)    │  │  (int)       │  │  (int)       │               │
│  │  isTimeUp    │  │  echoScore   │  │ chaosStab.  │               │
│  └──────────────┘  └──────────────┘  └──────────────┘               │
│                                                                       │
│  Random Event States (14 types)                                       │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐               │
│  │  isBlackout  │  │  isEarthquake│  │  isMirrored  │               │
│  │  isEvaporat. │  │  hasWind     │  │  isLeaking   │               │
│  │  isControls.. │  │  isUiGlitch. │  │  isGravity.. │               │
│  └──────────────┘  └──────────────┘  └──────────────┘               │
│                                                                       │
│  Progression States                                                   │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐               │
│  │  comboCount  │  │  match%      │  │  totalDrops  │               │
│  │  highestCombo│  │  (ValueNot.) │  │  (ValueNot.) │               │
│  └──────────────┘  └──────────────┘  └──────────────┘               │
│                                                                       │
│  Economy States                                                       │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐               │
│  │  totalCoins  │  │  helperCounts│  │  lastEarned..│               │
│  │  (ValueNot.) │  │  (ValueNot.) │  │  (int)       │               │
│  └──────────────┘  └──────────────┘  └──────────────┘               │
└──────────────────────────────────────────────────────────────────────┘
```

---

## Manager Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                        Manager Layer                                 │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  Core Progression Managers                                          │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐              │
│  │ LevelManager │  │  XpManager   │  │ LivesManager │              │
│  │  - levels    │  │  - currentXp │  │  - lives     │              │
│  │  - stars     │  │  - playerLvl │  │  - regen     │              │
│  │  - phases    │  │  - prestige  │  │  - timer     │              │
│  └──────────────┘  └──────────────┘  └──────────────┘              │
│                                                                      │
│  Economy Managers                                                    │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐              │
│  │ CoinStore... │  │  CardCollect │  │ SeasonPass.. │              │
│  │  - bundles   │  │  - unlocked  │  │  - progress  │              │
│  │  - IAP       │  │  - rarity    │  │  - rewards   │              │
│  │  - receipts  │  │  - drop      │  │  - tiers     │              │
│  └──────────────┘  └──────────────┘  └──────────────┘              │
│                                                                      │
│  Meta-Progression Managers                                           │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐              │
│  │Achievement.. │  │  Statistics  │  │  Tournament  │              │
│  │  - unlocked  │  │  - stats     │  │  - PB score  │              │
│  │  - engine    │  │  - tracking  │  │  - weekly    │              │
│  └──────────────┘  └──────────────┘  └──────────────┘              │
│                                                                      │
│  Support Managers                                                    │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐              │
│  │ AudioManager │  │  AdManager   │  │ VipManager   │              │
│  │  - BGM       │  │  - ads       │  │  - perks     │              │
│  │  - SFX       │  │  - rewards   │  │  - tiers     │              │
│  └──────────────┘  └──────────────┘  └──────────────┘              │
│                                                                      │
│  Security Managers                                                   │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐              │
│  │ Security...  │  │ RuntimeInt.. │  │ SaveManager  │              │
│  │  - encrypt   │  │  - checks    │  │  - persist   │              │
│  │  - HMAC      │  │  - debugger  │  │  - rate lim. │              │
│  └──────────────┘  └──────────────┘  └──────────────┘              │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Data Flow - Level Completion

```
┌─────────────────────────────────────────────────────────────────────┐
│                    Level Completion Flow                              │
└─────────────────────────────────────────────────────────────────────┘

1. Player mixes color
   │
   ▼
2. ColorMixerGame.update() checks match
   │
   ▼
3. Match >= 93% → _hasWon = true
   │
   ▼
4. showWinEffect() called
   │
   ├─► Play win sound
   ├─► Spawn particles
   ├─► Calculate stars (1-3)
   ├─► Update combo counter
   │
   ▼
5. Award XP (XpManager.addXpForWin)
   │
   ├─► Base XP by stars
   ├─► Mode multiplier
   ├─► Combo bonus
   ├─► Check level-up
   │   │
   │   ├─► Award coins (50-500)
   │   └─► Fire levelUpEvent
   │
   ▼
6. Award coins (ColorMixerGame.addCoins)
   │
   ├─► Base coins by stars
   ├─► Mode multiplier
   ├─► Random event bonus
   └─► Save to SecurityService
   │
   ▼
7. Check achievements (AchievementEngine.check)
   │
   ├─► Build AchievementContext
   ├─► Evaluate 63 achievements
   ├─► Unlock new achievements
   └─► Queue achievement notifications
   │
   ▼
8. Update statistics (StatisticsManager)
   │
   ├─► incrementLevelsCompleted
   ├─► incrementPerfectMatches (if 3 stars)
   ├─► updateHighestCombo
   └─► addDropsUsed
   │
   ▼
9. Save progress (LevelManager.unlockNextLevel)
   │
   ├─► Update star count
   ├─► Unlock next level
   └─► SaveManager.saveProgress
   │
   ▼
10. Show WinMenu overlay
    │
    ├─► Display stars
    ├─► Display XP gained
    ├─► Display coins earned
    ├─► Show next level button
    └─► Trigger card drop (if applicable)
```

---

## Component Tree - Gameplay Scene

```
ColorMixerGame (FlameGame)
│
├─► BackgroundGradient (Component)
│   └─► Shader: Linear gradient (cosmic theme)
│
├─► PatternBackground (Component)
│   └─► Surface texture (lab table)
│
├─► AmbientParticles (Component)
│   └─► Floating particles (atmosphere)
│
├─► StringLights (Component)
│   └─► Decorative lights (customizable)
│
├─► BeakerStand (Component)
│   └─► Stand model (customizable)
│
├─► Beaker (PositionComponent) ⭐ CORE
│   ├─► _glassBackPaint (shader)
│   ├─► _liquidVolPaint (gradient shader)
│   ├─► _liquidSurfacePaint (meniscus)
│   ├─► BubbleParticles (manual render)
│   ├─► _glassFrontPaint (shader)
│   ├─► _rimPaint (stroke)
│   ├─► _leftGleamShader (specular)
│   ├─► _rightGleamShader (reflection)
│   └─► _topRimShader (catch-light)
│
├─► [Active Effects] (dynamic)
│   ├─► BlackoutEffect (overlay)
│   ├─► GlitchEffect (post-process)
│   ├─► EarthquakeVisualEffect (camera)
│   ├─► GravityFluxEffect (beaker child)
│   ├─► WindForceEffect (particles)
│   └─► [More effects...]
│
└─► [Win Effects] (on win)
    ├─► WinningParticles (explosion)
    ├─► ShimmerEffect (perfect match)
    └─► Fireworks (celebration)
```

---

## Security Layer Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                      Security Stack                                   │
└─────────────────────────────────────────────────────────────────────┘

Application Layer
│
├─► RuntimeIntegrityChecker
│   ├─► Debugger detection (kDebugMode)
│   ├─► Emulator detection (Android SDK)
│   └─► Periodic checks (5 min interval)
│
├─► SecurityAuditLogger
│   ├─► Event logging (last 100)
│   ├─► Severity levels (info/warn/error/critical)
│   └─► Timestamp tracking
│
└─► SecurityService
    │
    ├─► Key Derivation Layer
    │   ├─► 5-part obfuscated key
    │   ├─► 16-byte salt
    │   └─► XOR combination
    │
    ├─► Encryption Layer
    │   ├─► XOR cipher (session key)
    │   ├─► Base64 encoding
    │   └─► Constant-time comparison
    │
    ├─► Integrity Layer
    │   ├─► HMAC-SHA256
    │   ├─► Verification on read
    │   └─► Tamper detection
    │
    ├─► Anti-Replay Layer
    │   ├─► Sequence numbers
    │   ├─► Window validation (±100)
    │   └─► Timestamp checks
    │
    └─► Storage Layer
        ├─► FlutterSecureStorage
        ├─► Encrypted SharedPreferences
        └─► Secure deletion (overwrite)
```

---

## Save Data Schema

```
┌─────────────────────────────────────────────────────────────────────┐
│                    Persisted Data Structure                           │
└─────────────────────────────────────────────────────────────────────┘

SecurityService (Encrypted Storage)
│
├─► player_progress_classic (JSON)
│   └─► {"1": 3, "2": 2, "3": -1, ...}  // levelId: stars
│
├─► player_progress_timeAttack (JSON)
│   └─► {"1": 3, "2": 0, "3": -1, ...}
│
├─► total_stars (int)
│   └─► "150"
│
├─► total_coins (int)
│   └─► "5000"
│
├─► player_xp (int)
│   └─► "2500"
│
├─► player_level (int)
│   └─► "25"
│
├─► player_prestige (int)
│   └─► "0"
│
├─► collected_cards_v1 (JSON array)
│   └─► ["c_vantablack", "c_ylnmn_blue", ...]
│
├─► unlocked_achievements (JSON array)
│   └─► ["first_win", "first_perfect", ...]
│
├─► helper_counts (JSON)
│   └─► {"extra_drops": 3, "help_drop": 2, ...}
│
├─► lab_configuration (JSON)
│   └─► {"surface": "surface_steel", "lighting": "light_basic", ...}
│
├─► purchased_skins (JSON array)
│   └─► ["BeakerType.classic", "BeakerType.laboratory", ...]
│
├─► lives_count (int)
│   └─► "5"
│
├─► next_regen_time (ISO8601)
│   └─► "2026-03-13T15:30:00Z"
│
├─► discovered_colors (JSON array)
│   └─► ["123456", "789ABC", ...]  // RGB int values
│
└─► [Metadata for each key]
    ├─► ${key}_hmac (HMAC signature)
    ├─► ${key}_ts (timestamp)
    └─► ${key}_seq (sequence number)
```

---

## Event System - ValueNotifier Network

```
┌─────────────────────────────────────────────────────────────────────┐
│                  Reactive State Updates                               │
└─────────────────────────────────────────────────────────────────────┘

ColorMixerGame ValueNotifiers (30+)
│
├─► matchPercentage (double) ──► Controls Overlay (progress bar)
│
├─► totalDrops (int) ──► Controls Overlay (drop counter)
│
├─► currentHint (String?) ──► Controls Overlay (hint display)
│
├─► comboCount (int) ──► Controls Overlay (combo badge)
│
├─► totalCoins (int) ──► Coins Widget (currency display)
│                      └─► Shop Overlay (spending)
│
├─► dropCooldownProgress (double) ──► Controls Overlay (button UI)
│
├─► chaosPhase (String) ──► ChaosLabHUD (phase indicator)
│
├─► chaosStability (double) ──► ChaosLabHUD (stability bar)
│
├─► activeEventLabel (String?) ──► ChaosLabHUD (event badge)
│
├─► activeEventProgress (double) ──► ChaosLabHUD (timer)
│
├─► echoAlmostSync (bool) ──► ColorEchoHUD (sync indicator)
│
├─► rewardNotification (String?) ──► Main Widget (toast)
│
└─► helperCounts (Map) ──► Controls Overlay (helper buttons)

External Manager ValueNotifiers
│
├─► XpManager
│   ├─► currentXp (int) ──► Level Up Overlay
│   ├─► playerLevel (int) ──► Profile Widget
│   └─► levelUpEvent (int?) ──► Level Up Overlay (trigger)
│
├─► CardCollectionManager
│   └─► newlyUnlockedCard (CardDef?) ──► Card Unlock Overlay
│
├─► TournamentManager
│   └─► scoreNotifier (int) ──► Tournament HUD
│
└─► LivesManager (ChangeNotifier)
    └─► notifyListeners() ──► Lives Widget (regen countdown)
```

---

## Build & Release Checklist

```
Pre-Release Verification
│
├─► Static Analysis
│   └─► flutter analyze --no-fatal-infos --no-fatal-warnings
│       Expected: 0 issues (excluding info)
│
├─► Test Suite
│   └─► flutter test
│       Expected: All tests pass
│
├─► Build Verification
│   ├─► flutter build apk --release
│   ├─► flutter build ios --release
│   └─► Verify no compile errors
│
├─► Security Audit
│   ├─► Check SecurityService initialization
│   ├─► Verify encryption keys unchanged
│   └─► Test tamper detection
│
├─► Performance Check
│   ├─► App size < 100 MB
│   ├─► Cold start < 2s
│   └─► FPS > 55 on target devices
│
└─► Manual Smoke Test
    ├─► Complete 5 levels
    ├─► Open all menus
    ├─► Test all game modes
    └─► Verify IAP (test environment)
```

---

**Document Version:** 1.0  
**Last Updated:** March 13, 2026  
**Maintained By:** Engineering Team
