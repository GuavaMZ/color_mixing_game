# Color Mixer Game: Project Structure

This document provides a detailed overview of the project's directory structure and the responsibilities of each file.

## Root Directory
- `analysis_options.yaml`: Linting rules for Dart.
- `pubspec.yaml`: Project metadata, dependencies, and asset definitions.
- `README.md`: Basic project information.
- `assets/`: Contains external resources.
  - `audio/`: Sound effects and background music.
  - `images/`: Static images and textures.
  - `levels.json`: Data defining the game levels.

## Library (`lib/`)
The core source code of the application.

### Entry Point
- [main.dart](file:///d:/Work/color_mixing_deductive/lib/main.dart): Initialized the app, localization, audio, and sets up the `GameWidget` with all overlays.

### Core Game Logic
- [color_mixer_game.dart](file:///d:/Work/color_mixing_deductive/lib/color_mixer_game.dart): The main `FlameGame` class. Manages game state, level transitions, drop logic, and random events.

### Subdirectories

#### `components/`
Modular Flame components that appear in the game world, grouped by purpose.
- `effects/`: Visual feedback and environmental effects (e.g., `acid_splatter.dart`, `glitch_effect.dart`).
- `environment/`: Background and atmospheric elements (e.g., `background_gradient.dart`, `surface_steam.dart`).
- `gameplay/`: Primary interactive elements (e.g., `beaker.dart`, `pouring_effect.dart`).
- `particles/`: Reusable particle systems (e.g., `ambient_particles.dart`, `mix_particles.dart`).

#### `core/`
Fundamental logic and state management.
- `color_logic.dart`: Handles color mixing mathematics and matching percentages.
- `level_manager.dart`: Manages level progression and loading from JSON.
- `save_manager.dart`: Persists game data (coins, stars, achievements) via `shared_preferences`.
- `lives_manager.dart`: Manages the player's life count.

#### `helpers/`
Utility classes and managers.
- `audio_manager.dart`: Centralized audio control.
- `string_manager.dart`: Localization strings and keys.
- `statistics_manager.dart`: Tracks player performance data.
- `theme_constants.dart`: UI styling tokens (colors, gradients, etc.).

#### `overlays/`
Flutter widgets used as UI layers over the game canvas, grouped by context.
- `hud/`: In-game information displays (e.g., `controls_overlay.dart`, `chaos_lab_hud.dart`).
- `menus/`: Navigation and modal menus (e.g., `main_menu_overlay.dart`, `win_menu_overlay.dart`).
- `navigation/`: Large-scale selection and browsing screens (e.g., `level_map_overlay.dart`, `shop_overlay.dart`).
- `system/`: Infrastructure and utility overlays (e.g., `loading_overlay.dart`, `tutorial_overlay.dart`).
