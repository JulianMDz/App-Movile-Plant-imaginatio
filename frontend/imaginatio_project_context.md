# 🧠 IMAGINATIO - Contexto Global del Proyecto (Memory Bank)

## 1. Visión General y Arquitectura
IMAGINATIO es un ecosistema multiplataforma (Web/Flutter + Unity 3D) donde los usuarios cultivan plantas y gestionan recursos. Ambos sistemas están completamente desacoplados y su única fuente de verdad compartida es un archivo JSON local con extensión `.tree`.

**Stack de Flutter:**
- **Estado:** `Provider` (`ChangeNotifier`). No usar GetX, Bloc ni Riverpod.
- **Navegación:** `go_router`.
- **Game Engine:** `flame`. La pantalla principal (`PlantGameScreen`) es una instancia de `FlameGame`.

---

## 2. Estructura Estricta de Minijuegos (REGLA DE EQUIPO - INQUEBRANTABLE)
**NO** debes crear nuevas pantallas nativas de Flutter ni agregar rutas en GoRouter para los minijuegos. Debes respetar la estructura de carpetas existente en `lib/modules/plant_game/mini_games/` y trabajar dentro del motor Flame:

```text
mini_games/
 ├── compost/
 │    ├── compost_logic.dart   # Lógica de estados y recompensas del minijuego
 │    └── compost_overlay.dart # Flame Component (UI del minijuego)
 ├── sun/
 │    ├── sun_logic.dart       # Lógica matemática (probabilidades/tiers)
 │    └── sun_overlay.dart     # Flame Component (UI del minijuego)
 └── water/
      ├── water_logic.dart     
      └── water_overlay.dart   
Patrón de Ejecución: Los minijuegos se renderizan superpuestos como componentes de Flame (ej. add(SunOverlay()) dentro de PlantGameScreen).

El Puente de Estado (Contexto): Para que la lógica del minijuego (_logic.dart) pueda sumar recursos y guardar el archivo .tree, debe acceder al PlantController de Flutter. Esto se logra pasando el BuildContext nativo de Flutter hacia el overlay (ya sea por constructor o usando HasGameReference<PlantGameScreen>).

3. El Contrato de Datos: Archivo .tree (JSON v2)
Este archivo maneja TODAS las plantas y datos del usuario. El emparejamiento (matching) de entidades se hace SIEMPRE priorizando el instance_id (inmutable).

⚖️ Matriz Estricta de Responsabilidades (Merge Logic)
🟢 Dominio de Flutter/Web (Escribe Flutter, Unity solo lee):

usuario.id, usuario.nombre

recursos.agua, recursos.sol, recursos.composta (Inventarios de recursos)

planta.id, planta.instance_id, planta.subid, planta.desbloqueada

planta.estado.fase (semilla, arbusto, planta, ent)

planta.visual_estado

planta.recursos_aplicados

🔴 Dominio de Unity 3D (Escribe Unity, Flutter solo lee y preserva):

usuario.nivel, usuario.xp

planta.estado.salud (saludable, dañado, critico, muerto), planta.estado.hp_actual

planta.progreso.nivel, planta.progreso.xp

planta.uso.seleccionada, planta.uso.en_combate

semillas[] (Cualquier entrada nueva generada en 3D se suma al inventario de Flutter).

4. Regla de Oro: Auto-Sync Bidireccional
Cada vez que un minijuego termine con éxito y retorne su recompensa (ej. +5 Soles) dentro de su archivo _logic.dart, se deben ejecutar estrictamente estos dos pasos:

Actualizar el inventario del usuario en memoria mediante el PlantController.

Llamar inmediatamente a TreeStorageService.saveTreeLocally() para que el .tree guardado en el dispositivo siempre refleje el cambio recién hecho.

5. Especificaciones de los Minijuegos
☀️ Minijuego del Sol: Máximo 4 clicks exactos. Cada click tiene una probabilidad matemática de subir de Tier (Bronce, Plata, Oro, Diamante, Solar). Recompensa max: 5 Soles.

💧 Minijuego de Agua: Clicker de velocidad puro. 9 segundos límite (el contador inicia al primer click). Cada click llena una barra de progreso.

🌱 Minijuego de Composta: Puzzle visual. 5 segundos límite. El usuario debe tocar exactamente los 3 objetos orgánicos entre 8 opciones mezcladas.

6. Bugs Críticos Actuales (Top Priority)
Antes de avanzar con funcionalidades nuevas, el agente de IA debe mitigar estos fallos:

🚨 Crash por Parseo JSON (lib/models/models.dart): El método PlantState.fromJson() crashea al parsear fechas (last_interaction) si vienen nulas o corruptas desde Unity. Solución: Implementar null-checks y validación defensiva try-catch.

🚨 Lógica de Evolución Rota (lib/services/plant_service.dart): El mapa stageRequirements solo contempla PlantType.solar. Solución: Añadir configuraciones para xerofito, templado, montana, pasto e hidro.

🚨 Typo Fatal en Minijuego (lib/modules/plant_game/mini_games/water/water_overlay.dart): Llamada errónea a panelWater() en lugar de usar la clase en mayúscula PanelWater().

7. Instrucciones Directas para el Agente IA
No inventes arquitecturas: Lee la sección 2. Si se te pide trabajar en un minijuego, usa las clases de Flame (PositionComponent, SpriteComponent, etc.) dentro de los archivos _overlay.dart.

Protege el estado: Lee la sección 3. Jamás escribas un método que sobreescriba la salud (hp_actual) o experiencia (xp) desde Flutter. Esos datos le pertenecen a Unity.