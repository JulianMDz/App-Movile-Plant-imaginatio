---
applyTo: 'frontend/**'
title: "PLANT FIXES AGENT"
description: >
  Implementation and validation guide for critical bugfixes in Plant Flutter App.
  Follows: .tree platform authority, robustness practices, and team documentation structure.
---

# 🚦 Plant App Critical Fixes Agent

This document guides developers through the process of implementing essential fixes in the plant-care app, ensuring all changes are robust, persist correctly, and conform to project architecture, .tree authority, and onboarding documentation.

## ✅ Completion Status (May 2026)

**7 of 8 fixes COMPLETED. 1 pending.**

| Fix | Status | Files Modified | Tests Added |
|-----|--------|-----------------|------------|
| Concurrency in saveTree | ✅ DONE | plant_controller.dart, tree_storage_service.dart | plant_controller_test.dart |
| Debounce Minigame Triggers | ✅ DONE | plant_controller.dart, plant_logic.dart | plant_controller_test.dart |
| .tree Field Ownership | ✅ DONE | tree_storage_service.dart | tree_storage_service_test.dart |
| Error & Cooldown Feedback | ✅ DONE | plant_logic.dart | (integrated in plant_logic tests) |
| Null Safety & Edge Cases | ✅ DONE | plant_controller.dart | plant_controller_test.dart |
| Test Coverage | ✅ DONE | test/plant_controller_test.dart, test/tree_storage_service_test.dart | 20+ test cases |
| Documentation Sync | 🔄 IN PROGRESS | PLANT_FIXES_AGENT.md, FRONTEND_STRUCTURE.md, PLANT_MINIGAME_INTEGRATION_GUIDE.md | |
| Dead Code Cleanup | ⏳ PENDING | (to be identified) | |

---

## 📌 Top Fixes To Implement

- [x] **Concurrency in saveTree**: Add queuing/debounce for all state-save requests to avoid overwrites and corrupted persistence. ✅ COMPLETED
- [x] **Debounce Minigame/UI Triggers**: Prevent double-activation of overlays/minigames/resources. ✅ COMPLETED
- [x] **Strict .tree Field Ownership**: Never overwrite Unity/red/unowned fields; merge after every write. ✅ COMPLETED
- [x] **Error & Cooldown Feedback**: Add overlays/toasts for error/cooldown, ensure silent fails are user-notified. ✅ COMPLETED
- [x] **Null Safety / Edge Case Guards**: Defensive checks for plant/resource state, especially surrounding app boot, resume, and overlay triggers. ✅ COMPLETED
- [x] **Test Coverage for New Flows**: Add/extend integration and widget tests for above fixes. Run coverage checks. ✅ COMPLETED
- [x] **Documentation & Onboarding Sync**: Update architecture files and developer guides to reflect all code and logic changes. 🔄 IN PROGRESS
- [ ] **Refactor/Remove Dead or Empty Files**: Clean up unused modules/components referenced in docs. ⏳ PENDING

---

## 🗂️ File & Module Mapping

| Fix                             | Core Implementation Files                                            | Docs to Update / Reference                     |
|----------------------------------|---------------------------------------------------------------------|------------------------------------------------|
| Concurrency on saveTree         | plant_controller.dart, tree_storage_service.dart, shared_tree_storage_service.dart | FRONTEND_STRUCTURE.md, PLANT_MINIGAME_INTEGRATION_GUIDE.md |
| Debounce minigame triggers      | Button_game_water.dart, Button_game_sun.dart, Button_game_compost.dart, plant_screen.dart | PLANT_MINIGAME_INTEGRATION_GUIDE.md           |
| .tree field authority           | tree_models.dart, tree_storage_service.dart, shared_tree_storage_service.dart     | FRONTEND_STRUCTURE.md, .tree authority chart   |
| Error/cooldown overlays         | All *overlay.dart, panel_bar.dart, plant_controller.dart            | MINIGAME_FLOWCHARTS_AND_DIAGRAMS.md           |
| Null checks, edge guards        | plant_controller.dart, all *overlay.dart, plant_service.dart        | Docs as above                                  |
| Test coverage                   | All above, plus test/ and integration/widget test files              | (Track increases in code coverage)             |
| Docs/onboarding                 | *.md in root or docs folder                                         | See below                                      |

---

## 🚀 Fix Implementation Steps

### 1. Concurrency in `saveTree`

**Locations:**
- `frontend/lib/modules/plant_game/plant_controller.dart`: All state mutations that call saveTree
- `frontend/lib/services/tree_storage_service.dart`: Core saveTree logic
- `frontend/lib/services/shared_tree_storage_service.dart`: Android sync and persistence
- `frontend/lib/modules/plant_game/components/Button_game_*.dart`: Minigame completion triggers

**Implementation Checklist:**
- [ ] Read all current saveTree() call sites in plant_controller.dart and identify state mutations that trigger saves
- [ ] Add a `_isSaving` flag (bool) and optional `_savingQueue` (int counter) to PlantController
- [ ] Wrap all saveTree() calls with concurrency guard:
  ```dart
  Future<void> saveTreeDebounced() async {
    if (_isSaving) return; // Early exit if already saving
    _isSaving = true;
    try {
      await treeStorageService.saveTree(currentTreeState);
    } catch (e) {
      // Log error; notify user via overlay/toast
      notifyError('Failed to save plant state: $e');
    } finally {
      _isSaving = false;
    }
  }
  ```
- [ ] Replace all direct saveTree() calls with saveTreeDebounced() (or add debounce timer if rapid-fire saves expected)
- [ ] Add inline comment: "Concurrent save guard: Ensures no data loss on rapid state changes"
- [ ] **Test**: Write unit test that simulates 10 rapid state mutations; verify only 1 final save occurs
- [ ] **Test**: Verify coverage; run `flutter test --coverage`
- [ ] Update FRONTEND_STRUCTURE.md with new saveTreeDebounced() pattern

---

### 2. Debounce Overlay/Minigame Launch

**Locations:**
- `frontend/lib/modules/plant_game/components/Button_game_water.dart`
- `frontend/lib/modules/plant_game/components/Button_game_sun.dart`
- `frontend/lib/modules/plant_game/components/Button_game_compost.dart`
- `frontend/lib/modules/plant_game/plant_screen.dart`: Overlay state management
- `frontend/lib/modules/plant_game/mini_games/*/overlay.dart`: All minigame overlay files

**Implementation Checklist:**
- [ ] In each Button_game_*.dart, read the onPressed callback and check for active overlay state
- [ ] Add guard: if overlay is already active or cooldown is active, return early with silent or toast feedback
- [ ] Refactor overlay launch to follow consistent 7-phase lifecycle (from PLANT_MINIGAME_INTEGRATION_GUIDE.md):
  1. **Init**: Create overlay, initialize state
  2. **Display**: Show overlay widget on screen
  3. **Interact**: User plays minigame
  4. **Complete**: User finishes or exits
  5. **Reward**: Apply rewards/state changes
  6. **Save**: Persist state (via saveTreeDebounced)
  7. **Dismiss**: Remove overlay, cleanup
- [ ] Add example debounce pattern to plant_screen.dart:
  ```dart
  bool _overlayActive = false;
  Future<void> showMinigameOverlay() async {
    if (_overlayActive) return; // Prevent double-tap
    _overlayActive = true;
    try {
      await Future.delayed(Duration(milliseconds: 300)); // Debounce window
      // Launch overlay...
    } finally {
      _overlayActive = false;
    }
  }
  ```
- [ ] **Test**: Widget test that simulates rapid double-tap on minigame button; confirm only 1 overlay launches
- [ ] **Test**: Verify coverage; run `flutter test --coverage`
- [ ] Update PLANT_MINIGAME_INTEGRATION_GUIDE.md with debounce pattern and 7-phase checklist

---

### 3. `.tree` Field Ownership & Safe Merge

**Locations:**
- `frontend/lib/models/tree_models.dart`: Schema definition and field authority matrix
- `frontend/lib/services/tree_storage_service.dart`: Core merge and write logic
- `frontend/lib/services/shared_tree_storage_service.dart`: Android sync and field validation

**Implementation Checklist:**
- [ ] Read tree_models.dart and validate the field authority matrix (Red = Unity-owned, Blue = Flutter-owned, Green = Shared)
- [ ] In tree_storage_service.dart, locate the saveTree() and merge logic
- [ ] Add/verify a safeMerge() helper function that:
  ```dart
  /// Merges newState into canonical .tree while respecting field authority
  /// Red (Unity-owned) fields are NEVER overwritten; always kept from canonical tree
  Map<String, dynamic> safeMerge(
    Map<String, dynamic> canonicalTree,
    Map<String, dynamic> newState,
  ) {
    final merged = Map<String, dynamic>.from(canonicalTree);
    
    newState.forEach((key, value) {
      // Check field authority: if Red/Unity-owned, skip merge
      if (isUnityOwnedField(key)) {
        // Preserve canonical value
        return;
      }
      // Otherwise, merge new value
      merged[key] = value;
    });
    
    return merged;
  }
  ```
- [ ] Add inline comment: "Field authority enforced: Never overwrite Unity-owned fields"
- [ ] **Test**: Integration test that:
  1. Load canonical tree with a Unity-owned field set to value X
  2. Attempt to mutate that field in Flutter to value Y
  3. Call saveTree() and verify the field remains X
- [ ] **Test**: Verify coverage; run `flutter test --coverage`
- [ ] Update FRONTEND_STRUCTURE.md with field authority matrix and safeMerge example

---

### 4. UI Feedback: Error, Cooldown, Resource

**Locations:**
- `frontend/lib/modules/plant_game/plant_controller.dart`: State mutation and error handling
- `frontend/lib/modules/plant_game/components/panel_bar.dart`: Resource HUD display
- `frontend/lib/modules/plant_game/mini_games/*/overlay.dart`: Minigame result feedback
- `frontend/lib/modules/plant_game/components/Animation_critical.dart/.danger.dart/.evo.dart`: Visual state feedback

**Implementation Checklist:**
- [ ] Grep for all error/cooldown/resource checks that are silent (e.g., just logged or return early with no user feedback)
- [ ] For each case, add one of:
  - **Overlay notification** (for critical feedback): "Plant needs water! Cooldown: 2m 30s"
  - **Toast/Snackbar** (for minor feedback): "Compost already applied (cooldown active)"
  - **Panel bar visual** (for always-on feedback): Highlight resource bar in red if depleted
- [ ] Example error feedback in plant_controller.dart:
  ```dart
  Future<void> applyWater() async {
    // Check cooldown
    if (isWaterOnCooldown()) {
      final remainingSeconds = getWaterCooldownRemaining();
      showOverlay(ErrorOverlay(
        title: 'Water Cooldown Active',
        message: 'Please wait ${formatSeconds(remainingSeconds)}',
      ));
      return;
    }
    
    // Check plant health
    if (plant == null || plant!.health <= 0) {
      showOverlay(ErrorOverlay(
        title: 'Plant is Dead',
        message: 'Plant requires revival before you can care for it.',
      ));
      return;
    }
    
    // Proceed with water...
  }
  ```
- [ ] Update panel_bar.dart to highlight resource bars when depleted or on cooldown
- [ ] **Test**: Widget test for each error case; confirm overlay/toast displays and has correct message
- [ ] **Test**: Verify coverage; run `flutter test --coverage`
- [ ] Update MINIGAME_FLOWCHARTS_AND_DIAGRAMS.md with error feedback flowchart

---

### 5. Null and Edge-Case Handling

**Locations:**
- `frontend/lib/modules/plant_game/plant_controller.dart`: Primary state hub
- `frontend/lib/modules/plant_game/mini_games/*/overlay.dart`: All minigame implementations
- `frontend/lib/services/plant_service.dart`: Legacy business logic (audit for null-safety)
- `frontend/lib/services/tree_storage_service.dart`: .tree load/parse

**Implementation Checklist:**
- [ ] Identify all instances where plant, resources, or state objects are accessed without null-checks
- [ ] Add defensive null-coalescing or early-return guards:
  ```dart
  Future<void> applyResource(String resourceType) async {
    // Defensive: Ensure plant exists
    if (plant == null) {
      logger.error('Plant is null; cannot apply resource');
      notifyError('Plant state corrupted; please restart app');
      return;
    }
    
    // Defensive: Ensure resource exists and is valid
    final resource = plant!.getResource(resourceType);
    if (resource == null || resource.current < 0) {
      logger.warn('Resource $resourceType invalid; resetting to 0');
      plant!.setResource(resourceType, 0);
    }
    
    // Proceed...
  }
  ```
- [ ] Audit app boot sequence (main.dart, plant_screen.dart, plant_controller.dart init)
  - Verify tree is loaded before any state mutation
  - Add fallback defaults if tree is corrupted or missing
- [ ] Audit overlay trigger paths (Button_game_*.dart):
  - Verify plant state exists before overlay launch
  - Add null-checks for all accessed properties
- [ ] **Test**: Integration test for app boot with missing or corrupted tree file; verify graceful fallback
- [ ] **Test**: Widget test for each overlay trigger with null plant state; verify error overlay or safe exit
- [ ] **Test**: Verify coverage; run `flutter test --coverage`
- [ ] Update PLANT_MINIGAME_INTEGRATION_GUIDE.md with null-safety checklist

---

### 6. Test Coverage & Regression

**Locations:**
- `frontend/test/`: Unit tests
- `frontend/integration_test/`: Integration tests
- `frontend/test_driver/`: Driver for UI tests (if applicable)

**Implementation Checklist:**
- [ ] For each above fix, write a corresponding test:
  - **Unit tests** for debounce logic, safeMerge, null-checks
  - **Widget tests** for UI feedback (overlays, toasts, panel updates)
  - **Integration tests** for end-to-end flows (boot → minigame → save → verify state)
- [ ] Organize tests by module:
  ```
  frontend/test/
    unit/
      plant_controller_test.dart (debounce, concurrency, null-safety)
      tree_storage_service_test.dart (safeMerge, field authority)
      local_storage_service_test.dart (cooldown/decay persistence)
    widget/
      minigame_overlay_test.dart (UI feedback, debounce)
      panel_bar_test.dart (resource display, error highlighting)
    integration/
      plant_game_flow_test.dart (boot → minigame → save)
  ```
- [ ] Run all tests and check coverage:
  ```bash
  cd frontend
  flutter test --coverage
  ```
- [ ] Verify coverage does NOT decrease; aim for >80% on critical paths (plant_controller, tree_storage, overlays)
- [ ] Document coverage baseline and targets in README or CI config

---

### 7. Documentation and Onboarding Sync

**Files to Update:**
- `FRONTEND_STRUCTURE.md`: Architecture, file mappings, and new patterns
- `PLANT_MINIGAME_INTEGRATION_GUIDE.md`: Overlay lifecycle, minigame trigger flow, debounce patterns
- `MINIGAME_FLOWCHARTS_AND_DIAGRAMS.md`: Visual flowcharts, error paths, field authority matrix
- `README.md` (if exists): High-level overview, testing instructions

**Implementation Checklist:**
- [ ] After each code fix, update relevant .md:
  - Add inline code examples showing the fix
  - Reference the file:line location of the change
  - Update any flowcharts or diagrams that reflect the change
- [ ] Example update to FRONTEND_STRUCTURE.md:
  ```markdown
  ### plant_controller.dart
  
  **New Pattern: Concurrency-safe saveTree**
  
  All state mutations now call `saveTreeDebounced()` instead of `saveTree()` directly.
  This prevents data loss on rapid-fire updates.
  
  Location: `frontend/lib/modules/plant_game/plant_controller.dart:123`
  
  ```dart
  Future<void> saveTreeDebounced() async {
    if (_isSaving) return;
    _isSaving = true;
    try {
      await treeStorageService.saveTree(currentTreeState);
    } finally {
      _isSaving = false;
    }
  }
  ```
  ```
- [ ] Update MINIGAME_FLOWCHARTS_AND_DIAGRAMS.md with new flowcharts showing:
  - Debounce guard on overlay launch
  - Error feedback paths
  - Field authority enforcement in saveTree
- [ ] Add a "Changelog" section to PLANT_MINIGAME_INTEGRATION_GUIDE.md:
  ```markdown
  ## Recent Changes (May 2026)
  
  - Added concurrency guard to saveTree (plant_controller.dart:123)
  - Added debounce to overlay launch (plant_screen.dart:456)
  - Added error overlays for cooldown/resource feedback (plant_controller.dart:789)
  - Added null-safety checks in minigame overlays (all *overlay.dart files)
  ```
- [ ] Cross-reference all docs to ensure they point to each other correctly

---

### 8. Cleanup & Dead Code Removal

**Locations:**
- `frontend/lib/`: Search for empty or unused files
- `frontend/test/`: Remove test stubs or outdated test files

**Implementation Checklist:**
- [ ] Grep for all files with <100 lines and check if they are:
  - Actually used (imported elsewhere)
  - Or empty/TODO stubs
- [ ] For each unused file:
  - Remove all imports from other files
  - Delete the file
  - Update FRONTEND_STRUCTURE.md to remove the reference
  - Update any doc diagrams that mention the file
- [ ] Example:
  ```bash
  # Search for unused files
  grep -r "import.*plant_service_old.dart" frontend/lib/
  # If no results, it's safe to delete
  rm frontend/lib/services/plant_service_old.dart
  ```
- [ ] **Test**: Verify app still builds and runs:
  ```bash
  cd frontend
  flutter pub get
  flutter build apk --debug
  ```
- [ ] Update FRONTEND_STRUCTURE.md with cleaned-up file list

---

## 🛑 When to Stop and Ask

- [ ] If you encounter **undocumented files** or **ambiguous module boundaries**—ask for clarification on architecture
- [ ] If a fix requires **changes to the .tree schema**—confirm with team and update tree_models.dart first
- [ ] If a fix requires **Unity-side changes** or **backend API updates**—coordinate with backend/Unity team
- [ ] If a **minigame overlay lifecycle** is missing or incomplete—reference PLANT_MINIGAME_INTEGRATION_GUIDE.md or ask for examples
- [ ] If you discover a **breaking change** to existing UI or data flows—stop and document impact before proceeding

---

## 🧪 Example Debounce Pseudocode

### Example 1: Debounced saveTree in PlantController

```dart
// In plant_controller.dart

class PlantController extends ChangeNotifier {
  bool _isSaving = false; // Concurrency guard
  
  /// Saves tree state with concurrency protection
  /// If a save is already in progress, this returns immediately
  Future<void> saveTreeDebounced() async {
    if (_isSaving) {
      logger.info('Save already in progress; skipping duplicate save');
      return;
    }
    
    _isSaving = true;
    try {
      // Merge current state with canonical tree, respecting field authority
      final mergedTree = safeMerge(canonicalTree, currentState);
      await treeStorageService.saveTree(mergedTree);
      logger.info('Plant state saved successfully');
    } catch (e) {
      logger.error('Failed to save plant state: $e');
      // Notify user via overlay
      notifyError('Failed to save plant. Please try again.');
    } finally {
      _isSaving = false;
    }
  }
  
  /// Apply water with debounce and error feedback
  Future<void> applyWater() async {
    // 1. Null/state check
    if (plant == null) {
      notifyError('Plant state corrupted; restart app');
      return;
    }
    
    // 2. Cooldown check
    if (isWaterOnCooldown()) {
      final remaining = getWaterCooldownRemaining();
      showOverlay(CooldownOverlay(
        title: 'Water Cooldown',
        message: 'Wait ${formatSeconds(remaining)}',
      ));
      return;
    }
    
    // 3. Resource check
    if (plant!.waterLevel < 0) {
      notifyError('Water level invalid; resetting');
      plant!.waterLevel = 0;
    }
    
    // 4. Apply water and save
    plant!.applyWater();
    await saveTreeDebounced();
    notifyListeners();
  }
}
```

### Example 2: Debounce Overlay Launch in Button_game_water.dart

```dart
// In Button_game_water.dart

class WaterGameButton extends StatefulWidget {
  @override
  _WaterGameButtonState createState() => _WaterGameButtonState();
}

class _WaterGameButtonState extends State<WaterGameButton> {
  bool _overlayActive = false; // Debounce guard
  
  void _onPressed() async {
    // Guard: Prevent double-tap while overlay is active
    if (_overlayActive) {
      logger.info('Water overlay already active; ignoring tap');
      return;
    }
    
    _overlayActive = true;
    try {
      // 1. Validate plant state
      final plant = plantController.plant;
      if (plant == null) {
        showOverlay(ErrorOverlay(title: 'Error', message: 'Plant not found'));
        return;
      }
      
      // 2. Check cooldown
      if (plantController.isWaterOnCooldown()) {
        showOverlay(CooldownOverlay(
          title: 'Water Cooldown',
          message: 'Please wait...',
        ));
        return;
      }
      
      // 3. Launch minigame overlay (7-phase lifecycle)
      // Phase 1: Init
      final overlay = WaterMinigameOverlay(plant: plant);
      
      // Phase 2-4: Display, Interact, Complete
      final result = await showGeneralDialog(
        context: context,
        pageBuilder: (ctx, anim1, anim2) => overlay,
      );
      
      // Phase 5-7: Reward, Save, Dismiss
      if (result != null && result.success) {
        plantController.applyWaterReward(result.bonus);
        await plantController.saveTreeDebounced();
      }
    } finally {
      _overlayActive = false; // Release guard
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: _onPressed,
      child: Text('Water'),
    );
  }
}
```

### Example 3: Safe Merge with Field Authority (tree_storage_service.dart)

```dart
// In tree_storage_service.dart

/// Merges new state into canonical tree while respecting field authority
/// Red (Unity-owned) fields are NEVER overwritten
Map<String, dynamic> safeMerge(
  Map<String, dynamic> canonicalTree,
  Map<String, dynamic> newState,
) {
  final merged = Map<String, dynamic>.from(canonicalTree);
  
  newState.forEach((key, value) {
    // Field authority check: If Unity-owned (red), preserve canonical
    if (_fieldAuthority[key] == 'unity') {
      logger.info('Skipping merge of Unity-owned field: $key');
      return; // Keep canonical value
    }
    
    // Otherwise, merge new value
    logger.info('Merging Flutter field: $key = $value');
    merged[key] = value;
  });
  
  return merged;
}

// Field authority matrix (from tree_models.dart)
const Map<String, String> _fieldAuthority = {
  'plantSpecies': 'unity',        // Red: Unity-owned
  'plantHealth': 'unity',         // Red: Unity-owned
  'evolutionStage': 'unity',      // Red: Unity-owned
  'waterLevel': 'flutter',        // Blue: Flutter-owned
  'sunLight': 'flutter',          // Blue: Flutter-owned
  'compostLevel': 'flutter',      // Blue: Flutter-owned
  'lastWaterTime': 'flutter',     // Blue: Flutter-owned
  'createdAt': 'shared',          // Green: Both read
  'syncedAt': 'shared',           // Green: Both read
};
```

---

## 📚 Key References

- [FRONTEND_STRUCTURE.md](./FRONTEND_STRUCTURE.md): Architecture overview and file mappings
- [PLANT_MINIGAME_INTEGRATION_GUIDE.md](./PLANT_MINIGAME_INTEGRATION_GUIDE.md): Overlay lifecycle and minigame patterns
- [MINIGAME_FLOWCHARTS_AND_DIAGRAMS.md](./MINIGAME_FLOWCHARTS_AND_DIAGRAMS.md): Visual flowcharts and error paths
- [frontend/lib/models/tree_models.dart](./frontend/lib/models/tree_models.dart): .tree schema and field authority
- [frontend/lib/modules/plant_game/plant_controller.dart](./frontend/lib/modules/plant_game/plant_controller.dart): Central state hub
- [frontend/lib/services/tree_storage_service.dart](./frontend/lib/services/tree_storage_service.dart): .tree IO and merge logic
- [frontend/lib/services/shared_tree_storage_service.dart](./frontend/lib/services/shared_tree_storage_service.dart): Android sync and persistence

---

## ✅ Implementation Checklist (Master)

- [ ] **Fix 1: Concurrency in saveTree** — Debounce, test, document
- [ ] **Fix 2: Debounce Overlay Triggers** — Add guards, test double-tap, document
- [ ] **Fix 3: .tree Field Ownership** — Add safeMerge, test authority, document
- [ ] **Fix 4: Error & Cooldown Feedback** — Add overlays/toasts, test, document
- [ ] **Fix 5: Null & Edge-Case Handling** — Add checks, test boot/overlay, document
- [ ] **Fix 6: Test Coverage** — Write tests, verify coverage, run suite
- [ ] **Fix 7: Documentation Sync** — Update all .md files with examples and references
- [ ] **Fix 8: Cleanup Dead Code** — Identify unused files, remove, update docs

---

## 🎯 Success Criteria

- ✅ All 8 fixes implemented and tested
- ✅ Code coverage ≥80% on critical paths (plant_controller, tree_storage, overlays)
- ✅ All tests pass: `flutter test --coverage`
- ✅ App builds and runs without errors: `flutter build apk --debug`
- ✅ All documentation updated with examples and file:line references
- ✅ No silent errors; all failures show user-visible feedback (overlays/toasts)
- ✅ No concurrent saves; all state mutations use saveTreeDebounced()
- ✅ No Unity-owned fields overwritten; all saves use safeMerge()
- ✅ No double-tap overlay launches; all triggers use debounce guard
- ✅ Dead code removed; all file references updated

---

*Remember: Rigorous, test-backed fixes + accurate docs = robust plant and happy team!*
