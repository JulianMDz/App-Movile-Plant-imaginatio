import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'plant_controller.dart';
import '../../services/tree_storage_service.dart'; // Ajusta la ruta a tu servicio

class PlantLogic {
  
  /// Abre el minijuego del sol, espera el resultado y hace el auto-sync
  static Future<void> playSunMinigame(BuildContext context) async {
    // 1. Abrimos el minijuego y esperamos (await) el pop() de la pantalla
    final result = await context.push('/minigame/sun-v2');

    // 2. Si el usuario cerró con la 'X', result será null. Si terminó el juego, trae datos.
    if (result != null && result is Map<String, dynamic>) {
      final reward = result['reward'] as int?;
      
      if (reward != null && reward > 0) {
        // 3. Obtenemos el controller y el servicio
        final controller = context.read<PlantController>();
        final treeService = context.read<TreeStorageService>(); // o locator si usas GetIt

        // 4. Actualizamos el inventario en memoria (State)
        controller.addSun(reward);

        // 5. AUTO-SYNC: Guardamos el .tree modificado en el almacenamiento local
        // (Replicando la función `syncInventoryToTree()` de la Web)
        try {
          await treeService.saveTreeLocally(
            user: controller.currentUser!, 
            plants: controller.plants,
            seeds: controller.seeds,
          );
          
          // 6. Feedback visual al usuario
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('¡Ganaste +$reward Soles! ☀️ Guardado correctamente.'),
              backgroundColor: Colors.orange,
            ),
          );
        } catch (e) {
          debugPrint('Error al hacer auto-sync del .tree: $e');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error al guardar el progreso.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  // Las funciones para Agua y Composta seguirán exactamente este mismo patrón
  static Future<void> playWaterMinigame(BuildContext context) async {}
  static Future<void> playCompostMinigame(BuildContext context) async {}
}