# Color Lab - QA Action Items Tracker

**Priority Legend:** 🔴 Critical | 🟡 Medium | 🟢 Low | ✅ Completed

---

## Immediate Actions (This Week)

### 🟢 A1: Remove Debug Print Statements
- **File:** `bin/diag.dart` (lines 11, 17)
- **Issue:** Print statements in production code
- **Impact:** Info-level lint warning, potential data leakage
- **Fix:**
  ```dart
  // Replace:
  print('Diagnostic info');
  
  // With:
  if (kDebugMode) {
    debugPrint('Diagnostic info');
  }
  ```
- **Status:** ⏳ Pending

### 🟡 A2: Arabic RTL Layout Testing
- **Files:** All overlay widgets
- **Issue:** Arabic language requires RTL layout support
- **Impact:** Potential UI breakage for Arabic users
- **Test Plan:**
  1. Open Settings → Language → Arabic
  2. Verify all menus render correctly
  3. Check text alignment in:
     - Main Menu
     - Settings
     - Shop Overlay
     - Level Map
     - HUD elements
- **Status:** ⏳ Pending

### 🟢 A3: Document Chaos Lab Constants
- **File:** `lib/color_mixer_game.dart` (lines 428-445)
- **Issue:** Magic numbers in decay formula
- **Current Code:**
  ```dart
  double decayRate = 0.003 + chaosRound * 0.001 + (1.0 - chaosStability) * 0.008;
  ```
- **Recommended:**
  ```dart
  // Base decay per second (0.3% stability)
  const double _baseDecayRate = 0.003;
  // Round scaling factor (0.1% per round)
  const double _roundDecayFactor = 0.001;
  // Instability multiplier (0.8% per 1% stability lost)
  const double _instabilityMultiplier = 0.008;
  
  double decayRate = _baseDecayRate + 
                     (chaosRound * _roundDecayFactor) + 
                     ((1.0 - chaosStability) * _instabilityMultiplier);
  ```
- **Status:** ⏳ Pending

---

## Short-Term Actions (Month 1)

### 🟡 A4: Expand Test Coverage to 40%

#### 4.1: Widget Tests - Main Menu
- **File:** `test/widgets/main_menu_test.dart` (create)
- **Test Cases:**
  ```dart
  testWidgets('Main menu displays all buttons', (tester) async {
    // Verify Play, Settings, Shop buttons exist
  });
  
  testWidgets('Play button navigates to level map', (tester) async {
    // Tap play, verify LevelMap overlay appears
  });
  ```

#### 4.2: Widget Tests - Settings
- **File:** `test/widgets/settings_test.dart` (create)
- **Test Cases:**
  - Language selection works
  - Sound toggle persists
  - Reduced motion toggle works

#### 4.3: Integration Tests - Level Flow
- **File:** `test/integration/level_flow_test.dart` (create)
- **Test Cases:**
  ```dart
  testWidgets('Complete level with perfect match', (tester) async {
    // Start level → Add correct drops → Verify win screen
  });
  
  testWidgets('Level fails on time out', (tester) async {
    // Start level → Wait for timer → Verify game over
  });
  ```

#### 4.4: Unit Tests - Managers
- **File:** `test/managers/xp_manager_test.dart` (create)
- **Test Cases:**
  ```dart
  test('XP calculation is correct', () {
    expect(XpManager.xpForLevel(0), 100);
    expect(XpManager.xpForLevel(1), 115);
  });
  
  test('Level up bonus is correct', () {
    expect(_levelUpBonus(10), 500); // Milestone
    expect(_levelUpBonus(5), 150);  // Mini-milestone
    expect(_levelUpBonus(3), 50);   // Normal
  });
  ```

- **Status:** ⏳ Pending

### 🟡 A5: Performance Profiling Session

#### 5.1: Frame Rate Analysis
- **Tool:** Flutter DevTools
- **Scenarios to Profile:**
  1. Level start (all overlays loading)
  2. Chaos Lab with 5+ active effects
  3. Win celebration (particles + fireworks)
  4. Shop overlay with IAP products
- **Target:** Consistent 60 FPS
- **Status:** ⏳ Pending

#### 5.2: Memory Leak Detection
- **Tool:** Dart DevTools Memory tab
- **Focus Areas:**
  - Timer.periodic in LivesManager
  - Stream subscriptions in CoinStoreService
  - ValueNotifier listeners
- **Status:** ⏳ Pending

#### 5.3: Shader Compilation Impact
- **Tool:** Flutter DevTools GPU tab
- **Focus:** First-time beaker rendering
- **Metric:** Frame time spike on first render
- **Status:** ⏳ Pending

### 🟡 A6: Accessibility Audit

#### 6.1: Screen Reader Testing
- **Tool:** TalkBack (Android) / VoiceOver (iOS)
- **Test:** Navigate entire game without looking
- **Focus:**
  - Button labels are descriptive
  - Color values have text alternatives
  - Win/loss states are announced

#### 6.2: Color Blind Mode Verification
- **File:** `lib/components/gameplay/beaker.dart` (lines 416-447)
- **Test:** Complete levels using only symbols
- **Symbols:**
  - 🔵 Blue = Square
  - 🔴 Red = Triangle
  - 🟢 Green = Circle
  - 🔴+🟢 = Triangle + Circle (Yellow)
- **Status:** ⏳ Pending

#### 6.3: Touch Target Sizes
- **Requirement:** Minimum 48x48 dp
- **Check:** All buttons, sliders, toggles
- **Files:**
  - `lib/overlays/menus/settings_overlay.dart`
  - `lib/overlays/navigation/shop_overlay.dart`
  - `lib/overlays/hud/controls_overlay.dart`
- **Status:** ⏳ Pending

---

## Long-Term Actions (Quarter 1)

### 🟢 A7: Achieve 70% Test Coverage

#### Coverage Goals:
| Component | Target | Current |
|-----------|--------|---------|
| Core Logic | 90% | 60% |
| Managers | 80% | 20% |
| UI Widgets | 70% | 0% |
| Game Components | 60% | 0% |
| **Overall** | **70%** | **~15%** |

#### Tools:
```bash
# Generate coverage
flutter test --coverage

# View report
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

- **Status:** ⏳ Pending

### 🟡 A8: Add Root/Jailbreak Detection

#### Implementation:
- **File:** `lib/core/runtime_integrity_checker.dart`
- **Android:** Check for Superuser, Magisk, dangerous apps
- **iOS:** Check for Cydia, Sileo, jailbreak directories
- **Package:** `flutter_jailbreak_detection` (pub.dev)

#### Code Example:
```dart
import 'package:flutter_jailbreak_detection/flutter_jailbreak_detection.dart';

Future<bool> _checkJailbreak() async {
  try {
    return await FlutterJailbreakDetection.jailbroken;
  } catch (e) {
    return false;
  }
}
```

- **Status:** ⏳ Pending

### 🟡 A9: Automated Performance Regression Tests

#### Setup:
1. **Tool:** `benchmark_harness` package
2. **Metrics:**
   - Level load time (< 2 seconds)
   - Win animation FPS (> 55 FPS)
   - Memory usage (< 200 MB)
3. **CI Integration:** Run on every PR
4. **Thresholds:** Fail if > 10% regression

#### Example:
```dart
import 'package:benchmark_harness/benchmark_harness.dart';

class LevelLoadBenchmark extends BenchmarkBase {
  @override
  void run() {
    // Load level, measure time
  }
}
```

- **Status:** ⏳ Pending

### 🟡 A10: Crash Analytics Integration

#### Options:
1. **Firebase Crashlytics** (recommended)
2. Sentry
3. Bugsnag

#### Implementation:
```dart
// In main.dart
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

Future<void> main() async {
  // ... existing init code
  
  // Pass all errors to Crashlytics
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };
}
```

- **Status:** ⏳ Pending

---

## Testing Checklist

### Manual Testing - Each Release

#### Core Gameplay
- [ ] Complete Level 1 (tutorial)
- [ ] Complete Level 10 (phase 2)
- [ ] Complete Level 25 (phase 3)
- [ ] Time Attack mode (3 levels)
- [ ] Color Echo mode (5 rounds)
- [ ] Chaos Lab mode (stability < 20%)

#### Economy
- [ ] Earn coins from level completion
- [ ] Spend coins on hints
- [ ] Purchase coin bundle (test IAP)
- [ ] Unlock card from collection
- [ ] Season pass progression

#### Progression
- [ ] XP earned on win
- [ ] Level up bonus received
- [ ] Prestige at level 100
- [ ] Achievement unlocked
- [ ] Star rating saved

#### Settings
- [ ] Language change (all 4 languages)
- [ ] Sound toggle
- [ ] Reduced motion toggle
- [ ] Random events toggle
- [ ] Blind mode toggle

#### Edge Cases
- [ ] Play with 0 lives (should block)
- [ ] Play offline (should work)
- [ ] App background/foreground
- [ ] Phone call interruption
- [ ] Low storage warning

---

## Performance Benchmarks

### Target Metrics

| Metric | Target | Critical If |
|--------|--------|-------------|
| App Size (APK) | < 100 MB | > 150 MB |
| Cold Start Time | < 2s | > 4s |
| Level Load Time | < 1s | > 2s |
| Average FPS | 60 | < 45 |
| Memory Usage | < 200 MB | > 400 MB |
| Battery Drain | < 5%/hour | > 15%/hour |

### Testing Devices

#### Minimum Spec
- Android: Snapdragon 450, 3GB RAM
- iOS: iPhone 6s, iOS 15

#### Recommended Spec
- Android: Snapdragon 730, 6GB RAM
- iOS: iPhone 11, iOS 16

---

## Security Audit Schedule

### Monthly Audits
- [ ] Review SecurityService logs
- [ ] Check for new tampering attempts
- [ ] Validate encryption keys unchanged
- [ ] Test rate limiting effectiveness

### Quarterly Audits
- [ ] Full penetration testing
- [ ] Dependency vulnerability scan
- [ ] Code obfuscation review
- [ ] IAP receipt validation audit

---

## Sign-Off

### QA Lead Approval
- [ ] All critical issues resolved
- [ ] Test coverage > 40%
- [ ] Performance benchmarks met
- [ ] Security audit passed

### Product Owner Approval
- [ ] Feature completeness verified
- [ ] User acceptance testing passed
- [ ] Monetization flow tested
- [ ] Analytics tracking verified

### Engineering Lead Approval
- [ ] Code review completed
- [ ] Technical debt documented
- [ ] Architecture scalable
- [ ] Documentation updated

---

**Last Updated:** March 13, 2026  
**Next Review:** March 20, 2026
