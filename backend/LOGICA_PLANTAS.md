# Documentación de Lógica del Backend - Sistema de Plantas

Este documento describe toda la lógica del backend relacionada con el sistema de plantas, manejo de recursos y evolución, necesaria para migrar a Flutter.

---

## 1. Tipos de Plantas (PlantType)

Existen 6 tipos de plantas, cada uno con requisitos diferentes:

| Tipo | Descripción |
|------|-------------|
| `solar` | Planta que necesita mucho sol |
| `xerofito` | Planta del desierto, pouca agua |
| `templado` | Planta de clima templado |
| `montana` | Planta de montaña |
| `hidro` | Planta acuática |
| `pasto` | Planta de pasto |

---

## 2. Etapas de Evolución (PlantStage)

4 etapas de evolución: `SEED` → `BUSH` → `TREE` → `ENT`

La etapa `ENT` es la final (la planta se convierte en un Ent y solo puede participar en combates).

---

## 3. Estado de la Planta (PlantState)

```dart
class PlantState {
  String plant_name;
  PlantType plant_type;
  PlantStage stage = PlantStage.SEED;
  double health = 100;        // 0-100
  double sun = 0;            // Recursos acumulados
  double water = 0;
  double fertilizer = 0;
  bool is_dead = false;
  DateTime last_interaction;
  SourcesNextState sources_next_state;
}
```

### SourcesNextState

```dart
class SourcesNextState {
  double sun;        // Recursos necesarios para siguiente etapa
  double water;
  double fertilizer;
}
```

---

## 4. Constantes del Sistema

| Constante | Valor | Descripción |
|-----------|-------|-------------|
| `MAX_HEALTH` | 100 | Salud máxima |
| `DEATH_HOURS_THRESHOLD` | 72.0 horas | Horas sin interacción antes de morir |
| `HEALTH_LOSS_PER_HOUR` | 100/72 ≈ 1.39 | Pérdida de salud por hora |
| `RESOURCE_LOSS_PER_HOUR` | 1.0 | Pérdida de recursos por hora |
| `COMPOST_TO_FERTILIZER` | 10 | Compost necesario para crear fertilizante |

---

## 5. Requisitos por Etapa y Tipo

### Stage Requirements (sun, water)

```
| Tipo       | SEED | BUSH | TREE |
|------------|------|------|------|
| solar      | 6,2  | 8,4  | 10,6 |
| xerofito   | 4,2  | 6,4  | 8,6  |
| templado  | 4,4  | 6,6  | 8,8  |
| montana    | 2,4  | 4,6  | 6,8  |
| hidro      | 2,6  | 4,8  | 6,10 |
| pasto      | 3,3  | 5,5  | 7,7  |
```

### Fertilizer Requirements (fertilizer necesario para evolucionar)

| Etapa Actual | Fertilizer Necesario |
|-------------|-------------------|
| SEED        | 4                 |
| BUSH        | 6                 |
| TREE        | 8                 |

---

## 6. Lógica de Disminución de Recursos (Pasiva)

### Función: `updatePassiveState(plant: PlantState) -> PlantState`

Se ejecuta cada vez que se interactúa con la planta:

1. **Calcular tiempo transcurrido** desde `last_interaction` hasta ahora
2. **Si hours_passed >= 72 horas**:
   - La planta muere (`is_dead = true`, `health = 0`)
3. **Sino, aplicar pérdida pasiva**:
   ```dart
   health = max(0, health - (100/72) * hours_passed)
   water = max(0, water - 1 * hours_passed)
   sun = max(0, sun - 1 * hours_passed)
   ```
4. **Si health <= 0**: planta muere (`is_dead = true`)

---

## 7. Acciones sobre la Planta

### water_plant / apply_sun / apply_fertilizer

Cada acción sigue este flujo:

1. Validar que la planta no está muerta ni en etapa ENT
2. **Descontar recurso del usuario** (si aplica)
3. **Ejecutar `updatePassiveState`** (actualizar estado pasivo)
4. **Aplicar efecto del recurso**:
   - **water**: `water +1`, `health +5` (máx 100)
   - **sun**: `sun +1`, `health +5` (máx 100)
   - **fertilizer**: `fertilizer +1`, `health +20` (máx 100)
5. **Actualizar `last_interaction`** = ahora
6. **Ejecutar `checkEvolution`** (verificar si puede evolucionar)
7. **Calcular `sources_next_state`** (recursos necesarios para sig. etapa)

### apply_water(plant)
```dart
if (!is_dead && stage != ENT) {
  water += 1;
  health = min(100, health + 5);
  last_interaction = now();
}
```

### apply_sun(plant)
```dart
if (!is_dead && stage != ENT) {
  sun += 1;
  health = min(100, health + 5);
  last_interaction = now();
}
```

### apply_fertilizer(plant, amount)
```dart
if (!is_dead && stage != ENT) {
  fertilizer += amount;
  health = min(100, health + 20);
  last_interaction = now();
}
```

---

## 8. Sistema de Evolución

### Función: `checkEvolution(plant: PlantState) -> (PlantState, bool)`

```dart
// Obtener requisitos para la etapa actual
Map<String, int> reqs = STAGE_REQUIREMENTS[type][stage];
int fert_needed = FERTILIZER_TO_EVOLVE[stage];

// Verificar si tiene todos los recursos
bool canEvolve = (
  plant.sun >= reqs["sun"] &&
  plant.water >= reqs["water"] &&
  plant.fertilizer >= fert_needed
);

if (canEvolve) {
  // Consumir recursos
  plant.sun -= reqs["sun"];
  plant.water -= reqs["water"];
  plant.fertilizer -= fert_needed;
  
  // Evolucionar
  plant.stage = NEXT_STAGE[stage];  // SEED→BUSH→TREE→ENT
  plant.health = 100;
  
  return (plant, true);
}

return (plant, false);
```

### Siguiente Etapa
```dart
NEXT_STAGE = {
  SEED: BUSH,
  BUSH: TREE,
  TREE: ENT,
};
```

---

## 9. Recursos del Usuario

### UserResources

```dart
class UserResources {
  int sun_amount = 0;
  int water_amount = 0;
  int fertilizer_amount = 0;
  int compost_amount = 0;
}
```

### ResourceType (enum)

- `sun`
- `water`
- `fertilizer`

### Función: `useResource(resources: UserResources, type: ResourceType, amount: int)`

```dart
switch (type) {
  case ResourceType.water:
    if (resources.water_amount < amount) throw Exception("No tienes suficiente agua");
    resources.water_amount -= amount;
    break;
  case ResourceType.sun:
    if (resources.sun_amount < amount) throw Exception("No tienes suficiente sol");
    resources.sun_amount -= amount;
    break;
  case ResourceType.fertilizer:
    if (resources.fertilizer_amount < amount) throw Exception("No tienes suficiente fertilizante");
    resources.fertilizer_amount -= amount;
    break;
}
```

---

## 10. Resumen de APIs del Backend

### Endpoints de Plantas

| Método | Endpoint | Descripción |
|--------|----------|-------------|
| POST | `/plant/water` | Regar planta |
| POST | `/plant/sun` | Exponer al sol |
| POST | `/plant/fertilize` | Fertilizar planta |
| POST | `/plant/evolve` | Intentar evolucionar |

### Request/Response

**Request** (para todos):
```json
{
  "user_id": "string",
  "plant_id": "string",
  "plant_state": { ... }
}
```

**Response**:
```json
{
  "plant_id": "string",
  "plant_state": { ... },
  "evolved": true/false,
  "message": "string"
}
```

### Endpoints de Recursos

| Método | Endpoint | Descripción |
|--------|----------|-------------|
| POST | `/user/resources/use` | Usar recurso |

---

## 11. Notas para Flutter

1. **Persistencia**: Necesitarás guardar `last_interaction` en SQLite/SharedPreferences para calcular el tiempo transcurrido

2. **Background updates**: Considera usar isolate o background service para actualizar el estado pasivo si la app está cerrada

3. **Validaciones**: Implementa las validaciones en Dart similares a `_validate_plant` en el backend

4. **Errores**: Maneja HTTPException cuando no hay recursos suficientes

5. **Estados de muerte**: La planta muere si pasan 72 horas sin interacción O si health <= 0