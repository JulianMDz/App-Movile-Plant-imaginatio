# Plant Imaginatio: System Flowcharts & Visual Diagrams

---

## Diagram 1: Minigame Event Propagation (Complete Lifecycle)

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                        MINIGAME EVENT LIFECYCLE                              │
└─────────────────────────────────────────────────────────────────────────────┘

                              USER INTERACTION
                                    │
                                    ▼
                         ┌──────────────────────┐
                         │ Button_game_water    │
                         │   onTap()            │
                         └──────────────────────┘
                                    │
                     ┌──────────────┴──────────────┐
                     ▼                             ▼
            ┌────────────────────┐      ┌─────────────────────┐
            │ canPlayWaterGame() │      │  On Cooldown?       │
            │ (10 min check)     │◄────┤  RETURN (silent)    │
            └────────────────────┘      └─────────────────────┘
                     │ YES
                     ▼
            ┌────────────────────────────┐
            │ gameRef.addOverlay()       │
            │ (WaterOverlay added)       │
            └────────────────────────────┘
                     │
                     ▼
        ┌────────────────────────────────────────┐
        │      WATEROVERLAY GAME LOOP            │
        ├────────────────────────────────────────┤
        │  onLoad()      → Initialize game       │
        │  onTapDown()   → Count taps            │
        │  update(dt)    → Check win condition  │
        │                 (5 sec timer)         │
        └────────────────────────────────────────┘
                     │
            (Timer expires after 5 sec)
                     ▼
        ┌────────────────────────────────┐
        │ _endMinigame()                 │
        │  _gameEndHandled = true        │
        └────────────────────────────────┘
                     │
        ┌────────────┴────────────┬─────────────┐
        ▼                         ▼             ▼
  ┌─────────────┐      ┌──────────────────┐  ┌──────────────┐
  │ addWater()  │      │ playWaterGame()  │  │ saveTree()   │
  │ +5 to       │      │ Set cooldown     │  │ Persist to   │
  │ inventory & │      │ timestamp        │  │ SharedPrefs  │
  │ plant       │      └──────────────────┘  └──────────────┘
  └─────────────┘             │                      │
        │                     │                      │
        ├─────────────────────┴──────────────────────┤
        ▼
  ┌──────────────────────────┐
  │ notifyListeners()        │
  │ (Alert UI listeners)     │
  └──────────────────────────┘
        │
        ▼
  ┌──────────────────────────┐
  │ PlantScreen listener     │
  │ _onControllerChange()    │
  └──────────────────────────┘
        │
        ├──┬────────────────────┬──────────────────┐
        ▼  ▼                    ▼                  ▼
   ┌─────┴──┐  ┌────────────┐  ┌──────────┐  ┌──────────┐
   │ UPDATE │  │ ANIMATION  │  │ COOLDOWN │  │ RESULT   │
   │ BARS   │  │ CHECK      │  │ DISPLAY  │  │ ALERT    │
   └────────┘  └────────────┘  └──────────┘  └──────────┘
        │
        ▼
   ┌──────────────────────┐
   │ _showResultAlert()   │
   │ "💧 +5"              │
   └──────────────────────┘
        │
        (User taps alert)
        │
        ▼
   ┌──────────────────────┐
   │ removeFromParent()   │
   │ (Overlay closes)     │
   └──────────────────────┘
        │
        ▼
   ┌──────────────────────┐
   │ Return to            │
   │ Plant Screen         │
   │ (UI updated!)        │
   └──────────────────────┘
```

---

## Diagram 2: Resource & State Data Flow

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    RESOURCE & STATE PROPAGATION                              │
└─────────────────────────────────────────────────────────────────────────────┘

                        USER APPLIES RESOURCE
                              │
                ┌─────────────┴─────────────┐
                ▼                           ▼
        ┌───────────────┐        ┌──────────────────┐
        │ addWater(5)   │        │ addSun(5)        │
        │ adds to both: │        │ adds to both:    │
        │ - Inventory   │        │ - Inventory      │
        │ - Plant       │        │ - Plant          │
        └───────────────┘        └──────────────────┘
                │                         │
                ├─────────────┬───────────┤
                ▼             ▼           ▼
        ┌──────────┐  ┌───────────────┐  ┌────────────┐
        │TreeData  │  │CHECKED BY     │  │notifyList  │
        │in memory │  │_checkEvolution│  │listeners()│
        └──────────┘  └───────────────┘  └────────────┘
                │             │               │
                │             │               ▼
                │             │       ┌──────────────────┐
                │             │       │PlantScreen       │
                │             │       │listener triggered│
                │             │       │setState()        │
                │             │       └──────────────────┘
                │             │               │
                │      ┌──────┴─────┐        │
                │      ▼            ▼        ▼
                │  ┌────────────┐  ┌────────────────┐
                │  │EVOLUTION   │  │UI UPDATES:     │
                │  │TRIGGERED?  │  │- Bars progress │
                │  │Phase ++    │  │- Animations    │
                │  │Resources   │  │- Colors        │
                │  │reset       │  └────────────────┘
                │  └────────────┘        │
                │        │               │
                │        ▼               │
                │  ┌──────────────┐      │
                │  │Animation_evo │      │
                │  │(25 frames)   │      │
                │  └──────────────┘      │
                │                        │
                └────────────┬───────────┘
                             ▼
                    ┌─────────────────┐
                    │TreeData SAVED   │
                    │to SharedPrefs   │
                    └─────────────────┘
                             │
                ┌────────────┬┴────────────┐
                ▼            ▼             ▼
        ┌────────────┐ ┌───────────┐ ┌──────────────┐
        │Session     │ │Local      │ │Android Docs/ │
        │Memory      │ │Storage    │ │IMAGINATIO/   │
        │(PlantCtrl) │ │(SharedPr) │ │Data_user.tree│
        └────────────┘ └───────────┘ └──────────────┘
```

---

## Diagram 3: Passive Decay Timeline

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    PASSIVE DECAY MECHANISM                                   │
└─────────────────────────────────────────────────────────────────────────────┘

Plant Created or Interacted With
    │
    ▼
lastInteraction = NOW
    │
    ├─ Time passes...
    │
    ├─ 9 minutes 59 seconds: No decay (< 10 min)
    │
    ├─ 10 minutes exactly: DECAY TRIGGERED
    │   ├─ intervals = 10 // 10 = 1
    │   ├─ agua: 10 - 1 = 9
    │   ├─ sol:  10 - 1 = 9
    │   └─ lastInteraction updated to NOW
    │
    ├─ More time passes...
    │
    ├─ 19 minutes 59 seconds: No additional decay
    │
    ├─ 20 minutes: DECAY TRIGGERED AGAIN
    │   ├─ intervals = 20 // 10 = 2
    │   ├─ agua: 10 - 2 = 8
    │   ├─ sol:  10 - 2 = 8
    │   └─ lastInteraction updated to NOW
    │
    ├─ More time passes...
    │
    ├─ 29 minutes 59 seconds: No decay
    │
    ├─ 30 minutes: DECAY TRIGGERED
    │   ├─ intervals = 30 // 10 = 3
    │   ├─ agua: 10 - 3 = 7
    │   ├─ sol:  10 - 3 = 7
    │
    ├─ ...pattern continues...
    │
    ├─ At some point: agua ≤ 0 OR sol ≤ 0
    │   ├─ Plant.estado.fase = 'muerto'
    │   ├─ Plant removed from active selection
    │   └─ Animation_critical triggered (red warning)
    │
    └─ END OF PLANT LIFECYCLE
```

---

## Diagram 4: Cooldown System State Machine

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    COOLDOWN STATE MACHINE                                    │
└─────────────────────────────────────────────────────────────────────────────┘

                           START
                             │
                ┌────────────┴─────────────┐
                │ First time ever played?  │
                └────────────┬─────────────┘
                             │
        ┌────────────────────┴────────────────────┐
        │ YES: _lastWaterGameTime = null          │ NO: Move to next check
        │                                         │
        ▼                                         ▼
   ┌─────────────┐                      ┌──────────────────┐
   │ READY STATE │                      │ Calculate time   │
   │ Can play    │                      │ difference:      │
   │ now()       │                      │ now - lastTime   │
   └─────────────┘                      └──────────────────┘
        │                                        │
        │                                        ▼
        │                               ┌──────────────────┐
        │                               │ > 10 minutes?    │
        │                               └──────┬───┬──────┘
        │                                      │   │
        │                          ┌───────────┘   └──────────┐
        │                          │                         │
        │                        YES                        NO
        │                          │                         │
        │                          ▼                         ▼
        │                   ┌────────────┐          ┌──────────────┐
        │                   │READY STATE │          │COOLDOWN STATE│
        │                   │Can play    │          │Cannot play   │
        │                   │now()       │          │Wait M:SS more│
        │                   └────────────┘          └──────────────┘
        │                          │                         │
        │                          ▼                         ▼
        │                   ┌────────────────────────────────────┐
        │                   │ User taps minigame button          │
        │                   │ canPlayWaterGame() → true/false    │
        │                   │ if false: RETURN (silent)          │
        │                   │ if true: PLAY GAME                 │
        │                   └────────────────────────────────────┘
        │                          │
        │                (Game completes after 5 sec)
        │                          │
        │                          ▼
        │                   ┌──────────────────┐
        │                   │ playWaterGame()  │
        │                   │ _lastWaterGameTime
        │                   │ = DateTime.now() │
        │                   │ Save to SharedPr │
        │                   └──────────────────┘
        │                          │
        │                          ▼
        │                   ┌──────────────────┐
        └──────────────────→│COOLDOWN STARTED  │
                            │Now = 0 min into  │
                            │10 min cooldown   │
                            └──────────────────┘
                                   │
                      (Wait 10 min for next play)
                                   │
                                   └─────┐
                                         │
                              (Loops back to "Calculate time difference")
```

---

## Diagram 5: Error Handling Paths

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    ERROR HANDLING & FEEDBACK                                 │
└─────────────────────────────────────────────────────────────────────────────┘

Minigame Completes
    │
    ▼
Try {
    ├─ addWater(reward)
    │   ├─ Check: _currentTree != null? ✓
    │   ├─ Check: activePlant != null? ✓
    │   └─ Update: recursos.agua.cantidad += reward
    │
    ├─ playWaterGame()
    │   └─ Set: _lastWaterGameTime = now
    │       Save to SharedPreferences
    │
    └─ saveTree()
        ├─ Merge with existing .tree
        ├─ Write to SharedPreferences
        └─ Export to Android Documents/
}
    │
    ├─────────────┬───────────┐
    │             │           │
    SUCCESS     ERROR1       ERROR2
    │             │           │
    ▼             ▼           ▼
┌────────┐   ┌─────────┐  ┌──────────┐
│Success │   │Save     │  │Resource  │
│Show    │   │Failed   │  │Validation│
│Result  │   │Log to   │  │Failed    │
│Alert   │   │console  │  │Log + UI? │
│"✓ +5"  │   │(silent) │  │(silent)  │
└────────┘   └─────────┘  └──────────┘
    │             │           │
    │             ├───────────┤
    │                         │
    │                    ⚠️ ISSUE: No error
    │                    feedback to user!
    │                    
    └─→ User taps alert → Overlay closes
        State updated (if save succeeded)
        OR State stale (if save failed)
        BUT UI LOOKS SAME EITHER WAY!


RECOMMENDED FIX:

Try {
    // ... all operations
} catch (SaveException e) {
    showErrorOverlay(
        title: 'Save Failed',
        message: e.toString(),
        onRetry: () => saveTree(),
    );
    return;  // Don't show success
}

// Only show result alert if we got here
showResultAlert(reward);
```

---

## Diagram 6: Flutter-Unity Field Ownership Matrix

```
┌─────────────────────────────────────────────────────────────────────────────┐
│            FLUTTER ↔ UNITY FIELD OWNERSHIP                                  │
└─────────────────────────────────────────────────────────────────────────────┘

                    .tree JSON File Structure


USER SECTION
┌─────────────────────────────────────────┐
│ "usuario": {                            │
│   "id": "uuid-123",         🟢 Flutter  │
│   "nombre": "John",         🟢 Flutter  │
│   "nivel": 25,              🔴 Unity    │
│   "xp": 5000                🔴 Unity    │
│ }                                       │
└─────────────────────────────────────────┘


RESOURCE SECTION (INVENTORY)
┌──────────────────────────────────────────┐
│ "recursos": {                            │
│   "agua": {                              │
│     "cantidad": 45          🟢 Flutter   │
│   },                                     │
│   "sol": {                               │
│     "cantidad": 62          🟢 Flutter   │
│   },                                     │
│   "composta": {                          │
│     "cantidad": 8           🟢 Flutter   │
│   },                                     │
│   "fertilizante": {                      │
│     "cantidad": 2           🟢 Flutter   │
│   }                                      │
│ }                                        │
└──────────────────────────────────────────┘


PLANT SECTION
┌─────────────────────────────────────────────────────────────────┐
│ "plantas": [                                                    │
│   {                                                             │
│     "id": "solar",                    🟢 Flutter               │
│     "instance_id": "plant-001",       🟢 Flutter               │
│     "subid": "...",                   🟢 Flutter               │
│     "desbloqueada": true,             🟢 Flutter               │
│     "estado": {                                                 │
│       "fase": "planta",               🟢 Flutter               │
│       "salud": "saludable",           🔴 Unity (read-only)    │
│       "hp_actual": 950                🔴 Unity (read-only)    │
│     },                                                          │
│     "progreso": {                                               │
│       "nivel": 5,                     🔴 Unity (read-only)    │
│       "xp": 250                       🔴 Unity (read-only)    │
│     },                                                          │
│     "visual_estado": {                                          │
│       "skin": "default",              🟢 Flutter               │
│       "variacion": "normal"           🟢 Flutter               │
│     },                                                          │
│     "recursos_aplicados": {                                     │
│       "agua": 20,                     🟢 Flutter               │
│       "sol": 35,                      🟢 Flutter               │
│       "composta": 0                   🟢 Flutter               │
│     }                                                           │
│   }                                                             │
│ ]                                                               │
└─────────────────────────────────────────────────────────────────┘


GOLDEN RULE:
🟢 Green (Flutter):  Flutter can READ & WRITE
🔴 Red (Unity):      Flutter can READ, but NEVER WRITE

When saving from Flutter:
  1. Load existing .tree (preserves all red fields)
  2. Update green fields with new values
  3. Save merged result

When importing from Unity:
  1. Load current Flutter state
  2. Merge red fields from Unity data
  3. Preserve green fields (never overwrite)
```

---

## Diagram 7: Multi-Layer Storage Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    STORAGE LAYER ARCHITECTURE                                │
└─────────────────────────────────────────────────────────────────────────────┘

                         DATA FLOW


┌─────────────────────┐
│   PlantController   │  ◄─── In-memory state
│   (TreeData)        │        (FASTEST)
└──────────┬──────────┘
           │
           │ notifyListeners()
           │
           ▼
┌─────────────────────────────────────┐
│   PlantScreen listeners             │
│   UI updates (bars, animations)     │
└─────────────────────────────────────┘


           ▲
           │ saveTree()
           │
           ▼
┌──────────────────────────────────────┐
│   LocalStorageService                │  ◄─── Session layer
│   (SharedPreferences in-memory)      │        (FAST)
│   - usuario data                     │
│   - session ID                       │
│   - cooldown timestamps              │
│   - plant interaction times          │
└──────────────────────────────────────┘


           ▲
           │ _storage.saveTreeLocally()
           │
           ▼
┌──────────────────────────────────────┐
│   TreeStorageService                 │  ◄─── File I/O layer
│   (SharedPreferences raw JSON)       │        (SLOWER)
│   - Full TreeData serialized         │
│   - Merged with existing .tree       │
│   - Flutter fields only written      │
└──────────────────────────────────────┘


           ▲
           │ SharedPreferences.setString()
           │
           ▼
┌──────────────────────────────────────┐
│   SharedTreeStorageService           │  ◄─── Android file system
│   (Android Documents folder)         │        (PERSISTENT)
│   - Android/data/IMAGINATIO/         │
│   - Documents/IMAGINATIO/            │
│   - Data_user.tree (JSON file)       │
│   - Syncs with Unity on app restart  │
└──────────────────────────────────────┘


RECOVERY SCENARIO:

If app crashes while saving:
  ✓ PlantController state preserved in memory
  ✓ Last saved version in SharedPreferences
  ✓ If SharedPreferences corrupted, restore from Documents/.tree

If phone is offline:
  ✓ All changes cached locally
  ✓ On reconnect, sync automatically

If Unity overwrites .tree:
  ✓ Pre-import backup created
  ✓ Merge strategy preserves Flutter fields
```

---

## Diagram 8: Minigame Overlay Types & Rewards

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    MINIGAME OVERLAY TYPES                                    │
└─────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────┐
│ 1. WATER MINIGAME                               │
├─────────────────────────────────────────────────┤
│ File: water_overlay.dart (180 lines)            │
│ Duration: 5 seconds                             │
│ Mechanic: Tap counter (count taps in 5 sec)    │
│ Scoring: taps_in_5_sec → reward_amount         │
│ Reward: +N Water to inventory & plant           │
│ Cooldown: 10 minutes                            │
│ Button: Button_game_water.dart                  │
│ Animation: Animation_water.dart (particles)     │
└─────────────────────────────────────────────────┘


┌─────────────────────────────────────────────────┐
│ 2. SUN MINIGAME                                 │
├─────────────────────────────────────────────────┤
│ File: sun_overlay.dart (247 lines)              │
│ Duration: Tier progression until max            │
│ Mechanic: 4-click tier progression              │
│   Click 1 → Bronze tier                         │
│   Click 2 → Silver tier                         │
│   Click 3 → Gold tier                           │
│   Click 4 → Solar tier (MAX)                    │
│ Scoring: tier_reached → reward_amount           │
│ Reward: +N Sun to inventory & plant             │
│ Cooldown: 10 minutes                            │
│ Button: Button_game_sun.dart                    │
│ Animation: Animation_sun.dart (particles)       │
└─────────────────────────────────────────────────┘


┌──────────────────────────────────────────────────┐
│ 3. COMPOST MINIGAME                              │
├──────────────────────────────────────────────────┤
│ File: compost_overlay.dart (205 lines)           │
│ Duration: 30 seconds (time-based)                │
│ Mechanic: 8-cell grid (organic/inorganic sort)   │
│   Player taps cells to categorize items          │
│   Correct categorization = points                │
│ Scoring: points → compost_reward_amount          │
│ Reward: +N Compost (auto-converts 4→1 fertilizer│
│ Cooldown: 3 minutes (shortest!)                  │
│ Button: Button_game_compost.dart (shows X/4)    │
│ Animation: Animation_compost.dart (particles)   │
│ Stock Display: Compost button shows current stock
│   Format: "{compost % 4}/4"                      │
│   At 4 compost → auto-convert to 1 fertilizer   │
└──────────────────────────────────────────────────┘


┌──────────────────────────────────────────────────┐
│ 4. SYNC OVERLAY                                  │
├──────────────────────────────────────────────────┤
│ File: sync_flutter_overlay.dart (328 lines)      │
│ Duration: Until sync completes                   │
│ Mechanic: Data synchronization (Unity↔Flutter)   │
│   Shows progress of sync                         │
│   Merges Flutter & Unity fields                  │
│ Reward: N/A (state merge)                        │
│ Cooldown: N/A (manual trigger)                   │
│ Button: Button_game_3d.dart                      │
│ Purpose: Manual data sync trigger                │
└──────────────────────────────────────────────────┘


REWARD DISTRIBUTION TABLE:

Minigame      │ Base Reward │ Time Bonus │ Max Reward │ Cooldown
──────────────┼─────────────┼────────────┼────────────┼─────────────
Water (5sec)  │ 1-5 taps    │ Yes        │ 10+        │ 10 minutes
Sun (tiers)   │ 1-4 tiers   │ No         │ 8+         │ 10 minutes
Compost (30s) │ Variable    │ Yes        │ 12+        │ 3 minutes
Sync          │ State merge │ N/A        │ N/A        │ N/A
```

---

## Diagram 9: Animation Priority System

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    ANIMATION PRIORITY & DISPLAY                              │
└─────────────────────────────────────────────────────────────────────────────┘

PlantController State Changes
    │
    ├─ Check animation flags
    │
    ▼
Priority 1: CRITICAL (Highest)
┌────────────────────────────────────────────┐
│ Condition: sol ≤ 2 OR agua ≤ 2             │
│ Animation: Animation_critical.dart         │
│ Visual: Red pulsing particles              │
│ Loop: YES (continuous until resolved)      │
│ File: Animation_critical.dart (~80 lines)  │
│ Flag: _showCriticalAnimation = true        │
└────────────────────────────────────────────┘
    │
    ├─ (Only show if CRITICAL is false)
    │
    ▼
Priority 2: DANGER (Medium)
┌────────────────────────────────────────────┐
│ Condition: sol ≤ 4 OR agua ≤ 4             │
│ Animation: Animation_danger.dart           │
│ Visual: Yellow pulsing particles           │
│ Loop: YES (continuous until resolved)      │
│ File: Animation_danger.dart (~80 lines)    │
│ Flag: _showDangerAnimation = true          │
└────────────────────────────────────────────┘
    │
    ├─ (Only show if CRITICAL & DANGER are false)
    │
    ▼
Priority 3: EVOLUTION (Low-Medium)
┌────────────────────────────────────────────┐
│ Condition: Plant phase advanced            │
│ Animation: Animation_evo.dart              │
│ Visual: 25-frame evolution sequence        │
│ Loop: NO (single play-through)             │
│ File: Animation_evo.dart (~100 lines)      │
│ Trigger: _checkEvolution() succeeds        │
│ Duration: ~1 second                        │
└────────────────────────────────────────────┘
    │
    ├─ (Show reward particles after minigame)
    │
    ▼
Priority 4: REWARD (Lowest)
┌────────────────────────────────────────────┐
│ Condition: Minigame completed              │
│ Animation: Animation_water/sun/compost.dart│
│ Visual: Colored particle burst             │
│ Loop: NO (single play-through)             │
│ File: ~60 lines each                       │
│ Duration: ~500ms                           │
│ Cleanup: removeFromParent() after anim     │
└────────────────────────────────────────────┘


DISPLAY LOGIC:

if (_showCriticalAnimation) {
    display Critical animation
} else if (_showDangerAnimation) {
    display Danger animation
} else if (_showEvolutionAnimation) {
    display Evolution animation
} else {
    // No high-priority animation
    // May show reward particles here
}
```

---

## Diagram 10: Debugging Decision Tree

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    DEBUGGING DECISION TREE                                   │
└─────────────────────────────────────────────────────────────────────────────┘

START: "Minigame not working"
    │
    ├─ Does button respond at all?
    │   ├─ NO  → Check: Button_game_water.dart (onTap)
    │   │         Is button added to UI?
    │   │         Is gameRef available?
    │   │
    │   └─ YES → Check: canPlayWaterGame() returns what?
    │       ├─ FALSE  → Cooldown active
    │       │    Check: _lastWaterGameTime in SharedPreferences?
    │       │    Is 10 minutes actually elapsed?
    │       │    Are timestamps UTC?
    │       │
    │       └─ TRUE   → Check: Overlay added to Flame game
    │           ├─ NO  → Check: WaterOverlay class loaded?
    │           │         Check: gameRef.addOverlay() signature?
    │           │
    │           └─ YES → Check: Overlay visible on screen?
    │               ├─ NO  → Check: Overlay positioned correctly?
    │               │         Check: onLoad() called?
    │               │
    │               └─ YES → Check: Game responds to taps?
    │                   ├─ NO  → Check: onTapDown() method?
    │                   │         Check: event coordinates?
    │                   │
    │                   └─ YES → Check: Timer expires?
    │                       ├─ NO  → Check: update(dt) logic?
    │                       │         Check: _elapsedTime tracking?
    │                       │
    │                       └─ YES → Check: Reward applied?
    │                           ├─ NO  → Check: controller.addWater()?
    │                           │         Check: _currentTree != null?
    │                           │         Check: activePlant != null?
    │                           │
    │                           └─ YES → Check: State persisted?
    │                               ├─ NO  → Check: saveTree() called?
    │                               │         Check: SharedPreferences write?
    │                               │         Check: Permissions?
    │                               │
    │                               └─ YES → Check: UI updated?
    │                                   ├─ NO  → Check: notifyListeners()?
    │                                   │         Check: PlantScreen listener?
    │                                   │
    │                                   └─ YES → SUCCESS!
    │                                           Minigame fully working


COMMON ISSUES & FIXES:

Issue: Button unresponsive
  Fix: Check gameRef context in Button_game_water.dart

Issue: Overlay appears but no interaction
  Fix: Check onTapDown() collision detection in water_overlay.dart

Issue: Reward shows but state doesn't persist
  Fix: Check saveTree() in PlantController, verify permissions

Issue: Cooldown shows but player can play anyway
  Fix: Check DateTime comparison logic (UTC vs local time)

Issue: Player plays but no reward applied
  Fix: Check _currentTree != null in PlantController.addWater()

Issue: Save succeeds but no UI update
  Fix: Check notifyListeners() called in saveTree()
```

---

**End of Flowcharts & Diagrams**

All diagrams are ASCII-based for easy integration into markdown and GitHub.

For UML diagrams or more detailed visual flows, refer to the main documentation:
`PLANT_MINIGAME_INTEGRATION_GUIDE.md`
