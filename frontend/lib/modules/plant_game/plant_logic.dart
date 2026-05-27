import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'plant_controller.dart';
import '../../services/tree_storage_service.dart'; // Ajusta la ruta a tu servicio

class PlantLogic {
  
  /// Shows a simple error overlay with title and message
  static void _showErrorOverlay(BuildContext context, String title, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$title\n$message'),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Shows a cooldown warning overlay
  static void _showCooldownOverlay(BuildContext context, String gameType, Duration remaining) {
    final minutes = remaining.inMinutes;
    final seconds = remaining.inSeconds % 60;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$gameType está en enfriamiento.\nEspera $minutes:${seconds.toString().padLeft(2, '0')}'),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Shows a plant state error overlay
  static void _showPlantStateError(BuildContext context, String reason) {
    _showErrorOverlay(context, '❌ No se puede jugar', reason);
  }
  
  /// Abre el minijuego del sol con debounce protection, espera el resultado y hace el auto-sync
  static Future<void> playSunMinigame(BuildContext context) async {
    final controller = context.read<PlantController>();

    // 0. Debounce guard: check if overlay is already active
    if (!controller.canLaunchSunOverlay()) {
      debugPrint('[PlantLogic] Sun minigame tap ignored (already active)');
      return;
    }

    try {
      // Pre-check 1: Validate plant state
      final plant = controller.activePlant;
      if (plant == null) {
        _showPlantStateError(context, 'No hay planta seleccionada.');
        return;
      }

      if (plant.estado.fase == 'muerto') {
        _showPlantStateError(context, 'La planta está muerta. Revívela primero.');
        return;
      }

      // Pre-check 2: Check cooldown
      if (!controller.canPlaySunGame()) {
        final remaining = controller.getSunGameRemainingCooldown();
        if (remaining != null) {
          _showCooldownOverlay(context, 'Minijuego del Sol', remaining);
        }
        return;
      }

      // 1. Abrimos el minijuego y esperamos (await) el pop() de la pantalla
      final result = await context.push('/minigame/sun-v2');

      // 2. Si el usuario cerró con la 'X', result será null. Si terminó el juego, trae datos.
      if (result != null && result is Map<String, dynamic>) {
        final reward = result['reward'] as int?;
        
        if (reward != null && reward > 0) {
          // 3. Obtenemos el servicio
          final treeService = context.read<TreeStorageService>(); // o locator si usas GetIt

          // 4. Actualizamos el inventario en memoria (State)
          controller.addSun(reward);

          // 5. AUTO-SYNC: Guardamos el .tree modificado en el almacenamiento local
          // (Replicando la función `syncInventoryToTree()` de la Web)
          try {
            if (controller.currentTree != null) {
              await treeService.saveTreeLocally(flutterData: controller.currentTree!);
            }
            
            // 6. Feedback visual al usuario
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('¡Ganaste +$reward Soles! ☀️ Guardado correctamente.'),
                backgroundColor: Colors.orange,
              ),
            );
          } catch (e) {
            debugPrint('Error al hacer auto-sync del .tree: $e');
            _showErrorOverlay(context, '❌ Error de guardado', 'No se pudo guardar el progreso: $e');
          }
        }
      }
    } finally {
      // Always reset the debounce guard when overlay closes (success or cancel)
      controller.resetSunOverlay();
    }
  }

  // Las funciones para Agua y Composta seguirán exactamente este mismo patrón
  
  /// Abre el minijuego del agua con debounce protection, espera el resultado y hace el auto-sync
  static Future<void> playWaterMinigame(BuildContext context) async {
    final controller = context.read<PlantController>();

    // 0. Debounce guard: check if overlay is already active
    if (!controller.canLaunchWaterOverlay()) {
      debugPrint('[PlantLogic] Water minigame tap ignored (already active)');
      return;
    }

    try {
      // Pre-check 1: Validate plant state
      final plant = controller.activePlant;
      if (plant == null) {
        _showPlantStateError(context, 'No hay planta seleccionada.');
        return;
      }

      if (plant.estado.fase == 'muerto') {
        _showPlantStateError(context, 'La planta está muerta. Revívela primero.');
        return;
      }

      // Pre-check 2: Check cooldown
      if (!controller.canPlayWaterGame()) {
        final remaining = controller.getWaterGameRemainingCooldown();
        if (remaining != null) {
          _showCooldownOverlay(context, 'Minijuego del Agua', remaining);
        }
        return;
      }

      final result = await context.push('/minigame/water-v2');

      if (result != null && result is Map<String, dynamic>) {
        final reward = result['reward'] as int?;
        
        if (reward != null && reward > 0) {
          final treeService = context.read<TreeStorageService>();

          controller.addWater(reward);

          try {
            if (controller.currentTree != null) {
              await treeService.saveTreeLocally(flutterData: controller.currentTree!);
            }
            
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('¡Ganaste +$reward Agua! 💧 Guardado correctamente.'),
                backgroundColor: Colors.blue,
              ),
            );
          } catch (e) {
            debugPrint('Error al hacer auto-sync del .tree: $e');
            _showErrorOverlay(context, '❌ Error de guardado', 'No se pudo guardar el progreso: $e');
          }
        }
      }
    } finally {
      controller.resetWaterOverlay();
    }
  }
  
  /// Abre el minijuego de composta con debounce protection, espera el resultado y hace el auto-sync
  static Future<void> playCompostMinigame(BuildContext context) async {
    final controller = context.read<PlantController>();

    // 0. Debounce guard: check if overlay is already active
    if (!controller.canLaunchCompostOverlay()) {
      debugPrint('[PlantLogic] Compost minigame tap ignored (already active)');
      return;
    }

    try {
      // Pre-check 1: Validate plant state
      final plant = controller.activePlant;
      if (plant == null) {
        _showPlantStateError(context, 'No hay planta seleccionada.');
        return;
      }

      if (plant.estado.fase == 'muerto') {
        _showPlantStateError(context, 'La planta está muerta. Revívela primero.');
        return;
      }

      // Pre-check 2: Check cooldown
      if (!controller.canPlayCompostGame()) {
        final remaining = controller.getCompostGameRemainingCooldown();
        if (remaining != null) {
          _showCooldownOverlay(context, 'Minijuego de Composta', remaining);
        }
        return;
      }

      final result = await context.push('/minigame/compost-v2');

      if (result != null && result is Map<String, dynamic>) {
        final reward = result['reward'] as int?;
        
        if (reward != null && reward > 0) {
          final treeService = context.read<TreeStorageService>();

          controller.addCompost(reward);

          try {
            if (controller.currentTree != null) {
              await treeService.saveTreeLocally(flutterData: controller.currentTree!);
            }
            
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('¡Ganaste +$reward Composta! 🟤 Guardado correctamente.'),
                backgroundColor: Colors.brown,
              ),
            );
          } catch (e) {
            debugPrint('Error al hacer auto-sync del .tree: $e');
            _showErrorOverlay(context, '❌ Error de guardado', 'No se pudo guardar el progreso: $e');
          }
        }
      }
    } finally {
      controller.resetCompostOverlay();
    }
  }
}