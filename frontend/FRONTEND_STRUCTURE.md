# Frontend Structure - Plant Imaginatio

## Overview

Flutter mobile application for "Plant Imaginatio" - a plant care game that syncs data with Unity 3D via a shared `.tree` JSON file.

---

## Directory Structure

```
lib/
├── main.dart                    # App entry point
├── core/                       # Core utilities
│   ├── audio.dart              # Audio playback
│   ├── router.dart             # Navigation
│   └── text_styles.dart        # Text styling
├── models/                     # Data models
│   ├── models.dart             # Main exports
│   └── tree_models.dart        # .tree file structures (JSON v2)
├── services/                  # Business logic services
│   ├── auth_service.dart      # User authentication
│   ├── local_storage_service.dart  # User session storage (SharedPreferences)
│   ├── tree_storage_service.dart   # .tree file sync (Flutter ↔ Unity)
│   ├── plant_service.dart     # Plant management
│   └── minigame_service.dart  # Mini-game logic
└── modules/                   # Screen modules
    ├── main_menu/             # Login/registration
    ├── plant_game/            # Main game screen
    │   ├── components/        # UI components
    │   └── mini_games/        # Resource mini-games
    │       ├── water/
    │       ├── sun/
    │       └── compost/
    ├── inventory/             # User inventory
    ├── settings/              # App settings
    └── help/                 # Help screen
```

---

## Storage Architecture

### 1. User Session (SharedPreferences)

**Service:** `LocalStorageService`  
**Key pattern:** `user_{userId}`

```dart
// Saves user data
saveUser(UserModel user) → JSON → SharedPreferences

// Session management
saveCurrentSession(String userId)
getCurrentSession() → String?
```

**Stored data:**
- User credentials
- Active session ID

---

### 2. Game State (.tree file)

**Service:** `TreeStorageService`  
**Key:** `imaginatio_tree_data`  
**Format:** JSON v2 (shared with Unity 3D)

#### Data Schema

```json
{
  "version": 2,
  "usuario": {
    "id": "string",
    "nombre": "string",
    "nivel": 0,
    "xp": 0
  },
  "recursos": {
    "agua": { "cantidad": 0 },
    "sol": { "cantidad": 0 },
    "composta": { "cantidad": 0 }
  },
  "plantas": [
    {
      "id": "string",
      "instance_id": "string",
      "subid": "string",
      "desbloqueada": true,
      "estado": {
        "fase": "semilla|arbusto|planta|ent",
        "salud": "saludable|dañado|critico|muerto",
        "hp_actual": 1000
      },
      "progreso": { "nivel": 0, "xp": 0 },
      "visual_estado": {
        "skin": "default",
        "variacion": "normal"
      },
      "uso": {
        "seleccionada": false,
        "en_combate": false
      },
      "recursos_aplicados": {
        "agua": 0,
        "sol": 0,
        "composta": 0
      }
    }
  ],
  "semillas": [
    {
      "seed_id": "string",
      "species_id": "string",
      "categoria": "string",
      "recibida_en": 1234567890
    }
  ]
}
```

---

## Ownership Matrix

| Field | Flutter (Green) | Unity (Red) |
|-------|-----------------|-------------|
| **Usuario** | | |
| id | ✅ | - |
| nombre | ✅ | - |
| nivel | - | 🔴 |
| xp | - | 🔴 |
| **Recursos** | | |
| agua.cantidad | ✅ | - |
| sol.cantidad | ✅ | - |
| composta.cantidad | ✅ | - |
| **Planta** | | |
| id | ✅ | - |
| instance_id | ✅ | - |
| subid | ✅ | - |
| desbloqueada | ✅ | - |
| estado.fase | ✅ | - |
| estado.salud | - | 🔴 |
| estado.hp_actual | - | 🔴 |
| progreso.* | - | 🔴 |
| visual_estado.* | ✅ | - |
| uso.* | - | 🔴 |
| recursos_aplicados.* | ✅ | - |
| **Semillas** | | |
| All fields | - | 🔴 |

---

## Sync Flow

### Flutter → Unity

```
saveTreeLocally(TreeData flutterData)
  1. Load existing .tree
  2. Merge: Flutter fields (green) + Unity fields preserved
  3. Save to SharedPreferences
```

### Unity → Flutter

```
applyUnitySync(TreeData unityData)
  1. Load current .tree
  2. Update only Unity fields (red)
  3. Preserve Flutter fields (green)
  4. Save merged result
```

### Merge Rules

- Plants matched by `instance_id` first, fallback by `id`
- Flutter NEVER overwrites Unity fields
- Unity NEVER overwrites Flutter fields
- New seeds from Unity added (dedup by `seed_id`)

---

## Storage Services

### LocalStorageService

**Purpose:** User session and authentication

**Methods:**
- `saveUser(UserModel)` - Persist user data
- `getUser(String userId)` - Retrieve user
- `saveCurrentSession(String)` - Set active session
- `getCurrentSession()` - Get active session ID

---

### TreeStorageService

**Purpose:** .tree file read/write with Flutter-Unity merge

**Methods:**
- `loadTree()` - Load .tree from SharedPreferences
- `saveTreeLocally(TreeData)` - Save with Flutter ownership merge
- `applyUnitySync(TreeData)` - Apply Unity exports
- `clearTree()` - Delete local .tree

---

## Key Files

| File | Purpose |
|------|---------|
| `lib/services/local_storage_service.dart` | User session (SharedPreferences) |
| `lib/services/tree_storage_service.dart` | .tree sync (Flutter ↔ Unity) |
| `lib/models/tree_models.dart` | .tree JSON v2 schemas |
| `lib/services/plant_service.dart` | Plant business logic |
| `lib/services/auth_service.dart` | Authentication |
| `lib/modules/plant_game/plant_screen.dart` | Main game screen |

---

## Dependencies

- `shared_preferences` - Local key-value storage
- `flutter` - UI framework ( Flame game engine)