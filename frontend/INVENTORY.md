# Codebase Inventory — Plant Game Frontend

**Generated:** 2026-05-03  
**Root:** `frontend/`  
**Total Files:** 346

---

## Legend

- **Status Categories:** Active | Deprecated | Unused | Test | Config | Documentation | Other | Status Unknown
- **Last Relevance:** Integrated (part of build/runtime) | Isolated (generated / not used) | Unknown

---

## Overview

This Flutter mobile application is a plant-growing game with mini-games for resource collection (sun, water, compost). The main areas are:

- **Source code:** `lib/` (Dart/Flutter) — primary application logic
- **Assets:** `assets/` (images, audio, fonts) — UI and audio resources
- **Platforms:** `android/`, `ios/`, `macos/`, `linux/`, `windows/` — platform-specific builds
- **Config:** `pubspec.yaml`, `analysis_options.yaml` — Flutter and Dart configuration
- **Generated:** `build/` — build artifacts (safe to ignore/remove)

---

## Root Configuration Files

| File | Type | Status | Description | Relevance |
|------|------|--------|-------------|-----------|
| `pubspec.yaml` | yaml | Config | Flutter package manifest with dependencies and asset declarations | Integrated |
| `pubspec.lock` | lock | Other | Locked versions of dependencies | Integrated |
| `analysis_options.yaml` | yaml | Config | Dart linter and analyzer rules | Integrated |
| `README.md` | md | Documentation | Project readme | Isolated |
| `.gitignore` | text | Config | Git ignore rules | Integrated |
| `.metadata` | text | Other | Flutter metadata (auto-generated) | Isolated |

---

## Test Files

| File | Type | Status | Description | Relevance |
|------|------|--------|-------------|-----------|
| `test/widget_test.dart` | dart | Test | Example Flutter widget test | Build/CI |

---

## Web Platform

| File | Type | Status | Description | Relevance |
|------|------|--------|-------------|-----------|
| `web/index.html` | html | Active | Web entry point | Integrated (web builds) |
| `web/manifest.json` | json | Active | PWA manifest | Integrated (web builds) |
| `web/icons/Icon-*.png` | png | Active | Web app icons | Integrated (web builds) |
| `web/favicon.png` | png | Active | Favicon | Integrated (web builds) |

---

## Platform Folders (Brief Summary)

### Android (`android/`)
- **Status:** Active
- **Key files:**
  - `build.gradle.kts` — Gradle build config (Status: Config, Integrated)
  - `gradle.properties` — Gradle properties (Status: Config, Integrated)
  - `app/build.gradle.kts` — App-level Gradle (Status: Config, Integrated)
  - `app/src/main/kotlin/com/example/frontend/MainActivity.kt` — Dart activity wrapper (Status: Active, Integrated)
  - `app/src/main/AndroidManifest.xml` — App manifest (Status: Config, Integrated)
  - `app/src/main/res/**` — Launcher icons, themes, layouts, widget resources (Status: Active, Integrated)
  - `gradle/wrapper/gradle-wrapper.properties` — Gradle wrapper (Status: Config, Integrated)

### iOS (`ios/`)
- **Status:** Active
- **Key files:**
  - `Runner/Info.plist` — iOS app config (Status: Config, Integrated)
  - `Runner/AppDelegate.swift` — Swift entry point (Status: Active, Integrated)
  - `Runner/**/*.storyboard` — Storyboard UI files (Status: Active, Integrated)
  - `Runner.xcodeproj/**` — Xcode project files (Status: Config, Integrated)
  - Xcode assets and configurations (Status: Active/Config, Integrated)

### macOS (`macos/`)
- **Status:** Active
- **Key files:**
  - `Runner/AppDelegate.swift` — macOS app entry (Status: Active, Integrated)
  - `Runner.xcodeproj/**` — Xcode project (Status: Config, Integrated)
  - `Runner/Configs/**` — Debug/Release configs (Status: Config, Integrated)
  - Assets and entitlements (Status: Active/Config, Integrated)

### Linux (`linux/`)
- **Status:** Active
- **Key files:**
  - `runner/main.cc` — C++ entry point (Status: Active, Integrated)
  - `runner/my_application.cc/h` — Application class (Status: Active, Integrated)
  - `CMakeLists.txt` — CMake build config (Status: Config, Integrated)
  - `flutter/**` — Generated Flutter plugin registrant (Status: Other, Integrated)

### Windows (`windows/`)
- **Status:** Active
- **Key files:**
  - `runner/main.cpp` — C++ entry point (Status: Active, Integrated)
  - `runner/flutter_window.cpp/h` — Flutter window (Status: Active, Integrated)
  - `runner/CMakeLists.txt` — CMake build config (Status: Config, Integrated)
  - `runner/runner.exe.manifest` — Windows manifest (Status: Config, Integrated)
  - `runner/Runner.rc` — Resource file (Status: Config, Integrated)

### Generated Artifacts (`build/`)
- **Status:** Other
- **Description:** Build output directory containing compiled artifacts, generated code, and intermediate files
- **Relevance:** Isolated — safe to remove/regenerate
- **Note:** 346 files total includes many generated files from this directory

---

## Core Source (`lib/core/`)

| File | Type | Status | Description | Relevance |
|------|------|--------|-------------|-----------|
| `main.dart` | dart | Active | App entry point, MaterialApp/Router setup | Integrated |
| `audio.dart` | dart | Active | Audio management helpers (uses `flame_audio`) | Integrated |
| `router.dart` | dart | Active | GoRouter route definitions | Integrated |
| `text_styles.dart` | dart | Active | Text styling utilities | Integrated |

---

## Models (`lib/models/`)

| File | Type | Status | Description | Relevance | Notes |
|------|------|--------|-------------|-----------|-------|
| `models.dart` | dart | Active | Domain models: `PlantType`, `PlantStage`, `UserResources`, `PlantState`, `SourcesNextState`, `UserModel` with JSON serialization | Integrated | ⚠️ **Issue:** `PlantState.fromJson()` calls `DateTime.parse()` without null-check. Will throw if `last_interaction` field is missing/malformed. Recommend: add defensive parsing. |

---

## Services (`lib/services/`)

| File | Type | Status | Description | Relevance | Notes |
|------|------|--------|-------------|-----------|-------|
| `local_storage_service.dart` | dart | Active | SharedPreferences wrapper for user/session persistence | Integrated | |
| `auth_service.dart` | dart | Active | Register/login using UUID and local storage | Integrated | |
| `minigame_service.dart` | dart | Active | Minigame logic: `playSunMinigame()`, `playWaterMinigame()`, `playCompostMinigame()` with reward calculation | Integrated | |
| `plant_service.dart` | dart | Active | Plant resource application, evolution logic, `stageRequirements` map | Integrated | ⚠️ **Issue:** `stageRequirements` only populated for `PlantType.solar` (seed/bush/tree). Other plant types (xerofito, templado, montana, pasto, hidro) missing — evolution will not work. Recommend: complete requirements map or add error handling. |

---

## Modules

### Main Menu (`lib/modules/main_menu/`)

| File | Type | Status | Description | Relevance |
|------|------|--------|-------------|-----------|
| `main_menu.dart` | dart | Active | Main menu screen UI | Integrated |
| `login_screen.dart` | dart | Active | Login/register screen | Integrated |
| `login_logic.dart` | dart | Active | Login screen logic | Integrated |
| `login_controller.dart` | dart | Active | Login state/controller | Integrated |
| `components/ButtonEnter.dart` | dart | Active | Button component | Integrated |
| `components/PanelEnter.dart` | dart | Active | Panel component | Integrated |
| `components/PanelName.dart` | dart | Active | Panel component | Integrated |
| `components/loginComponent.dart` | dart | Active | Login form component | Integrated |

### Plant Game (`lib/modules/plant_game/`)

#### Screen/Logic/Controller

| File | Type | Status | Description | Relevance |
|------|------|--------|-------------|-----------|
| `plant_screen.dart` | dart | Active | Main plant game UI screen | Integrated |
| `plant_logic.dart` | dart | Active | Plant game game loop logic | Integrated |
| `plant_controller.dart` | dart | Active | Plant game controller/state | Integrated |

#### Components

| File | Type | Status | Description | Relevance |
|------|------|--------|-------------|-----------|
| `components/background.dart` | dart | Active | Background sprite/component | Integrated |
| `components/plant.dart` | dart | Active | Plant sprite display | Integrated |
| `components/panel_bar.dart` | dart | Active | Health/status bar panel | Integrated |
| `components/panel_resource.dart` | dart | Active | Resource display panel | Integrated |
| `components/panel_title.dart` | dart | Active | Title/plant name panel | Integrated |
| `components/Text_name.dart` | dart | Active | Plant name text | Integrated |
| `components/Button_game_sun.dart` | dart | Active | Sun minigame button | Integrated |
| `components/Button_game_water.dart` | dart | Active | Water minigame button | Integrated |
| `components/Button_game_compost.dart` | dart | Active | Compost minigame button | Integrated |
| `components/Button_game_3d.dart` | dart | Active | 3D interaction button | Integrated |
| `components/button_resource_sun.dart` | dart | Active | Direct sun resource button | Integrated |
| `components/button_resource_water.dart` | dart | Active | Direct water resource button | Integrated |
| `components/button_resource_compost.dart` | dart | Active | Direct compost resource button | Integrated |
| `components/Button_help.dart` | dart | Active | Help button | Integrated |
| `components/Button_Inventary.dart` | dart | Active | Inventory button | Integrated |
| `components/Animation_*.dart` (7 files) | dart | Active | Particle/animation components (sun, water, compost, evo, tombstone, danger, critical) | Integrated |

#### Mini-Games: Sun

| File | Type | Status | Description | Relevance | Notes |
|------|------|--------|-------------|-----------|-------|
| `mini_games/sun/sun_overlay.dart` | dart | Active | Flame overlay for sun minigame | Integrated | |
| `mini_games/sun/sun_logic.dart` | dart | Active | Sun minigame logic/state | Integrated | |
| `mini_games/sun/components/panel_sun.dart` | dart | Active | Panel sprite for sun minigame UI | Integrated | Uses `cambiarEstado()` to switch sprite states |

#### Mini-Games: Water

| File | Type | Status | Description | Relevance | Notes |
|------|------|--------|-------------|-----------|-------|
| `mini_games/water/water_overlay.dart` | dart | Active | Flame overlay for water minigame | Integrated | 🔴 **ISSUE:** Line calls `add(panelWater());` — likely typo; should be `add(PanelWater());`. Will cause runtime error. |
| `mini_games/water/water_logic.dart` | dart | Active | Water minigame logic (click counting, timer) | Integrated | |
| `mini_games/water/components/panel_water.dart` | dart | Active | Water panel UI component | Integrated | |
| `mini_games/water/components/text_water.dart` | dart | Active | Text display for water minigame (timer, clicks) | Integrated | |
| `mini_games/water/components/warning_water.dart` | dart | Active | Alert/result component | Integrated | |
| `mini_games/water/components/water.dart` | dart | Active | Water drop button sprite | Integrated | |

#### Mini-Games: Compost

| File | Type | Status | Description | Relevance |
|------|------|--------|-------------|-----------|
| `mini_games/compost/compost_overlay.dart` | dart | Active | Flame overlay for compost minigame | Integrated |
| `mini_games/compost/compost_logic.dart` | dart | Active | Compost minigame logic (organic vs inorganic sorting) | Integrated |
| `mini_games/compost/components/panel_compost.dart` | dart | Active | Panel component | Integrated |
| `mini_games/compost/components/text_compost.dart` | dart | Active | Text component for compost game | Integrated |
| `mini_games/compost/components/warning_compost.dart` | dart | Active | Alert component | Integrated |
| `mini_games/compost/components/compost.dart` | dart | Active | Compost/trash sprite button | Integrated |

### Inventory (`lib/modules/inventory/`)

| File | Type | Status | Description | Relevance |
|------|------|--------|-------------|-----------|
| `inventory_screen.dart` | dart | Active | Inventory screen UI | Integrated |
| `inventory_logic.dart` | dart | Active | Inventory logic | Integrated |
| `inventory_controller.dart` | dart | Active | Inventory controller/state | Integrated |

### Help (`lib/modules/help/`)

| File | Type | Status | Description | Relevance |
|------|------|--------|-------------|-----------|
| `help_screen.dart` | dart | Active | Help/tutorial screen | Integrated |
| `help_logic.dart` | dart | Active | Help logic | Integrated |
| `help_controller.dart` | dart | Active | Help controller/state | Integrated |

### Settings (`lib/modules/settings/`)

| File | Type | Status | Description | Relevance |
|------|------|--------|-------------|-----------|
| `settings_screen.dart` | dart | Active | Settings screen UI | Integrated |
| `settings_logic.dart` | dart | Active | Settings logic | Integrated |
| `settings_controller.dart` | dart | Active | Settings controller/state | Integrated |

---

## Assets

### Fonts

| File | Type | Status | Description | Relevance |
|------|------|--------|-------------|-----------|
| `assets/fonts/PressStart2P-Regular.ttf` | ttf | Active | Press Start 2P retro font, declared in `pubspec.yaml` | Integrated |

### Audio

All audio files in `assets/audios/` — Status: **Active** — Used by game and minigames (via `flame_audio`):

| File | Type | Description |
|------|------|-------------|
| `timer_minigames.mp3` | mp3 | Minigame timer/warning sound |
| `soles_recoleccion.mp3` | mp3 | Sun collection reward |
| `sol.mp3` | mp3 | Sun interaction |
| `regar.mp3` | mp3 | Water/watering sound |
| `principal.mp3` | mp3 | Main menu/ambient music |
| `inventario.mp3` | mp3 | Inventory open/interact |
| `composta_recoleccion.mp3` | mp3 | Compost collection |
| `click_general.mp3` | mp3 | General UI click |
| `agua_recoleccion.mp3` | mp3 | Water collection |
| `abono.mp3` | mp3 | Fertilizer/abono sound |

### Images

#### Animations (`assets/images/Animations/`)
- `Water.png`, `Sol.png`, `Evo.png`, `Critical Particles.png`, `Danger Particles.png`, `Abono.png`, `TombStone_P.png`
- Status: **Active** — Particle/animation sprites
- Relevance: Integrated

#### Buttons (`assets/images/Botones/`)
- ~45 button sprites (Boton_*.png)
- Status: **Active** — UI buttons
- Relevance: Integrated

#### Scenarios (`assets/images/Escenarios/`)
- `Escenario_Opcion_*.png` (multiple variants)
- Status: **Active** — Background scenarios
- Relevance: Integrated

#### Icons (`assets/images/Iconos/`)
- `Icono_*.png` (sun, water, compost, fertilizer, traffic light states, etc.)
- Status: **Active** — UI icons
- Relevance: Integrated

#### Inventory (`assets/images/Inventario/`)
- `Panel_InvEspacio_*.png` (inventory slot panels)
- Status: **Active** — Inventory UI
- Relevance: Integrated

#### Mini-Games (`assets/images/Minijuegos/`)
- ~30 assets (panels, items, buttons, icons, organic/inorganic compost, watering can, etc.)
- Status: **Active** — Minigame graphics
- Relevance: Integrated

#### Panels (`assets/images/Paneles/`)
- HUD panels, help panels, resource state panels
- Status: **Active** — UI panels
- Relevance: Integrated
- ⚠️ **Potential Duplicates:** `Panel_EstadoAgua_01.png`, `Panel_EstadoComposta_01.png`, `Panel_EstadoSol_01.png`, `Panel_EstadoAbono_*.png` appear in both `Paneles/` and `Paneles/PanelesEstado/` subdirectory. Check if these are truly duplicates or intentional variants.

#### Plant (`assets/images/Planta/`)
- `Planta_Maceta_01.png`, `pasto_semilla.png`, `pasto_fase_02.png`, `pasto_fase_03.png`, `pasto_ent.png`
- Status: **Active** — Plant sprites for different growth stages
- Relevance: Integrated

---

## Generated & Tooling Files

### Plugin Registrants (Auto-Generated)

| File | Type | Status | Platform | Description |
|------|------|--------|----------|-------------|
| `linux/flutter/generated_plugin_registrant.cc/.h` | c++/header | Other | Linux | Generated plugin registration |
| `macos/Flutter/GeneratedPluginRegistrant.swift` | swift | Other | macOS | Generated plugin registration |
| `windows/flutter/generated_plugin_registrant.*` | cc/header | Other | Windows | Generated plugin registration |

All of these files are **auto-generated** by `flutter pub get` and should not be manually edited. Status: **Other**, Relevance: **Isolated** (regenerated as needed).

### Gradle Wrapper

| File | Type | Status | Description |
|------|------|--------|-------------|
| `android/gradle/wrapper/gradle-wrapper.properties` | properties | Config | Gradle wrapper version/URL config |

---

## Problematic / Flagged Files

### 🔴 High Priority Issues

#### 1. `lib/modules/plant_game/mini_games/water/water_overlay.dart`
- **Issue:** In `onLoad()`, line calls `add(panelWater());` which is likely a typo.
- **Expected:** Should be `add(PanelWater());` (capitalized, as component class).
- **Impact:** Runtime error when water minigame overlay is loaded.
- **Risk Level:** **HIGH** — Breaks water minigame functionality.
- **Action:** Fix constructor call to correct class name.

#### 2. `lib/services/plant_service.dart`
- **Issue:** `stageRequirements` static map only defines entries for `PlantType.solar` at stages seed/bush/tree.
- **Missing entries:** `xerofito`, `templado`, `montana`, `pasto`, `hidro` plant types have no requirements defined.
- **Impact:** When `_checkEvolution()` is called for non-solar plants, `reqs` is `null`, plant evolution does not occur, and `getSourcesNextState()` returns incorrect zero values.
- **Risk Level:** **HIGH** — Breaks evolution mechanic for most plant types.
- **Action:** Complete `stageRequirements` map with all plant type entries or add explicit error handling for missing types.

### ⚠️ Medium Priority Issues

#### 3. `lib/models/models.dart`
- **Issue:** `PlantState.fromJson()` calls `DateTime.parse(json['last_interaction'])` without null-checking or try-catch.
- **Impact:** If JSON data is missing `last_interaction` field or contains malformed date string, `fromJson()` throws unhandled exception during user load.
- **Risk Level:** **MEDIUM** — Can cause app crash on corrupted/old save data.
- **Action:** Add defensive parsing (null-check with fallback to `DateTime.now()`, or wrap in try-catch).

### 📋 Inventory Issues

#### 4. Asset Duplicates (`assets/images/Paneles/`)
- **Issue:** Several panel assets appear in both `Paneles/` and `Paneles/PanelesEstado/` subdirectories:
  - `Panel_EstadoSol_01.png`
  - `Panel_EstadoAgua_01.png`
  - `Panel_EstadoComposta_01.png`
  - `Panel_EstadoAbono_01.png`
  - `Panel_EstadoAbono_02.png`
- **Impact:** Potential maintenance overhead; unclear which version is used.
- **Risk Level:** **LOW** — Asset duplication rather than code issue.
- **Action:** Audit asset references in code; consolidate or remove duplicates.

---

## Duplicate / Near-Duplicate Files

### Platform Plugin Registrants (Expected)
- `linux/flutter/generated_plugin_registrant.*`
- `macos/Flutter/GeneratedPluginRegistrant.swift`
- `windows/flutter/generated_plugin_registrant.*`
- Android equivalent generated during build

**Status:** Normal/Expected. These are auto-generated per platform during `flutter pub get`.

### Asset Duplicates
- See "Problematic Files" section above (`Paneles/` duplicate panels).

---

## Files Safe to Remove / Ignore

- **`build/` directory:** Generated build artifacts. Safe to clean; will be regenerated.
- **`.metadata`:** Flutter metadata; typically not needed in version control.
- **Generated plugin registrants:** Auto-generated; safe to regenerate.
- **Platform `.gitignore` files:** Leave as-is for repo management.
- **IDE workspace files (`.xcworkspace`, `.xcodeproj` metadata):** Platform-specific build artifacts; typically excluded from version control.

---

## Files with Status Unknown

Several UI component files could not be definitively confirmed as "Active" vs "Unused" through static file listing alone:
- Some small button or animation components may be declared but not directly imported in screens (deferred loading).
- Full import graph analysis recommended for 100% certainty.

**Recommendation:** Run Dart analyzer or custom import-tracking script to confirm all components are referenced.

---

## Actionable Summary

| Priority | Item | File(s) | Action |
|----------|------|---------|--------|
| 🔴 HIGH | Water minigame panel constructor typo | `water_overlay.dart` | Fix: `panelWater()` → `PanelWater()` |
| 🔴 HIGH | Missing plant type requirements | `plant_service.dart` | Add all plant types to `stageRequirements` map |
| ⚠️ MEDIUM | Unsafe date parsing | `models.dart` | Add null-check / try-catch around `DateTime.parse()` |
| 📋 LOW | Asset duplication | `assets/images/Paneles/` | Audit and consolidate duplicate panel images |
| 🔍 OPTIONAL | Static import verification | Entire `lib/` | Run Dart analyzer to confirm all files referenced |
| 🧪 OPTIONAL | Add tests | `test/` | Create tests for JSON serialization, minigame logic |

---

## Recommendations

1. **Immediate:** Fix the three code issues (HIGH/MEDIUM priority) before next build/release.
2. **Short-term:** Run minigame overlays (especially water) to verify fixes.
3. **Medium-term:** Deduplicate assets and consolidate references.
4. **Long-term:** Add comprehensive test suite for model serialization and plant evolution logic.
5. **Ongoing:** Use `flutter analyze` and `dart analyze` in CI/CD pipeline to catch similar issues early.

---

## Repository Stats

| Metric | Count |
|--------|-------|
| Total files | 346 |
| Dart source files (`lib/`) | ~80 |
| Asset files | ~120 |
| Platform-specific files | ~140 |
| Config/generated files | ~6 |

---

**End of Inventory**

Document version: 1.0  
Last updated: 2026-05-03
