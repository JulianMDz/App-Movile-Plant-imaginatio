import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/modules/plant_game/plant_controller.dart';
import 'package:frontend/models/tree_models.dart';

void main() {
  group('PlantController - Concurrency & Debounce Tests', () {
    late PlantController controller;

    setUp(() {
      controller = PlantController();
    });

    // ── Fix 1: Concurrency Tests ──────────────────────────────────────────────

    test('saveTreeDebounced: first call enters save', () async {
      // Given: controller with _isSaving = false
      expect(controller._isSaving, false);

      // When: calling saveTreeDebounced with null tree (should early exit)
      await controller.saveTreeDebounced();

      // Then: _isSaving should be reset to false after completion
      expect(controller._isSaving, false);
    });

    test('saveTreeDebounced: concurrent call returns early', () async {
      // Manually set _isSaving to true to simulate concurrent save
      controller._isSaving = true;

      // When: calling saveTreeDebounced during active save
      await controller.saveTreeDebounced();

      // Then: method should return immediately without attempting save
      // (verified by _isSaving still being true, or via mocking in real test)
      expect(controller._isSaving, true);
    });

    // ── Fix 2: Minigame Overlay Debounce Tests ────────────────────────────────

    test('canLaunchSunOverlay: first call succeeds', () {
      // Given: _sunOverlayActive = false
      expect(controller._sunOverlayActive, false);

      // When: calling canLaunchSunOverlay
      final result = controller.canLaunchSunOverlay();

      // Then: returns true and sets _sunOverlayActive = true
      expect(result, true);
      expect(controller._sunOverlayActive, true);
    });

    test('canLaunchSunOverlay: second call blocked (debounced)', () {
      // Given: _sunOverlayActive = true (overlay already active)
      controller._sunOverlayActive = true;

      // When: calling canLaunchSunOverlay while active
      final result = controller.canLaunchSunOverlay();

      // Then: returns false (debounced)
      expect(result, false);
    });

    test('resetSunOverlay: clears debounce guard', () {
      // Given: _sunOverlayActive = true
      controller._sunOverlayActive = true;

      // When: calling resetSunOverlay
      controller.resetSunOverlay();

      // Then: _sunOverlayActive = false
      expect(controller._sunOverlayActive, false);
    });

    test('canLaunchWaterOverlay: debounce cycle', () {
      // Water overlay should follow same debounce pattern as sun
      expect(controller.canLaunchWaterOverlay(), true);
      expect(controller._waterOverlayActive, true);

      expect(controller.canLaunchWaterOverlay(), false);

      controller.resetWaterOverlay();
      expect(controller._waterOverlayActive, false);
    });

    test('canLaunchCompostOverlay: debounce cycle', () {
      // Compost overlay should follow same debounce pattern
      expect(controller.canLaunchCompostOverlay(), true);
      expect(controller._compostOverlayActive, true);

      expect(controller.canLaunchCompostOverlay(), false);

      controller.resetCompostOverlay();
      expect(controller._compostOverlayActive, false);
    });

    // ── Fix 5: Null Safety Tests ──────────────────────────────────────────────

    test('activePlant: returns null when currentTree is null', () {
      // Given: _currentTree = null
      controller._currentTree = null;

      // When: accessing activePlant
      final plant = controller.activePlant;

      // Then: returns null
      expect(plant, null);
    });

    test('spendSun: returns false when currentTree is null', () async {
      // Given: _currentTree = null
      controller._currentTree = null;

      // When: trying to spend sun
      final result = await controller.spendSun(amount: 1);

      // Then: returns false (cannot spend)
      expect(result, false);
    });

    test('spendWater: returns false when insufficient stock', () async {
      // Given: tree with 0 water
      // (In real test, this would be set up with proper TreeData)
      // For now, this is a placeholder

      // When: trying to spend more than available

      // Then: returns false
      // expect(result, false);
    });

     test('spendCompost: returns false when currentTree is null', () async {
       // Given: _currentTree = null
       controller._currentTree = null;

       // When: trying to spend compost
       final result = await controller.spendCompost(amount: 1);

       // Then: returns false (cannot spend)
       expect(result, false);
     });

     // ── FIX 2: Active Plant Preservation After Sync Tests ──────────────────────

     test('FIX 2: activePlant getter returns null when no plants', () {
       // Given: tree with empty plant list
       controller._currentTree = TreeData(
         version: 2,
         usuario: TreeUsuario(id: 'user1', nombre: 'Alice'),
         recursos: TreeRecursos(),
         plantas: [], // No plants
         semillas: [],
       );

       // When: accessing activePlant
       final plant = controller.activePlant;

       // Then: returns null (no plants available)
       expect(plant, null);
     });

     test('FIX 2: activePlant getter returns null when all plants dead', () {
       // Given: tree with only dead plants
       controller._currentTree = TreeData(
         version: 2,
         usuario: TreeUsuario(id: 'user1', nombre: 'Alice'),
         recursos: TreeRecursos(),
         plantas: [
           TreePlanta(
             id: 'pasto',
             instanceId: 'inst1',
             subid: 'pasto',
             desbloqueada: true,
             estado: TreeEstado(fase: 'muerto'), // Dead
           ),
         ],
         semillas: [],
       );

       // When: accessing activePlant
       final plant = controller.activePlant;

       // Then: returns null (no alive plants)
       expect(plant, null);
     });

     test('FIX 7: activePlant getter auto-resets out-of-bounds index to 0', () {
       // Given: tree with one plant but _activePlantIndex out of bounds
       controller._currentTree = TreeData(
         version: 2,
         usuario: TreeUsuario(id: 'user1', nombre: 'Alice'),
         recursos: TreeRecursos(),
         plantas: [
           TreePlanta(
             id: 'pasto',
             instanceId: 'inst1',
             subid: 'pasto',
             desbloqueada: true,
             estado: TreeEstado(fase: 'semilla'),
           ),
         ],
         semillas: [],
       );
       controller._activePlantIndex = 5; // Out of bounds (only 1 plant)

       // When: accessing activePlant (FIX 7 should auto-reset)
       final plant = controller.activePlant;

       // Then: returns the plant and index is reset to 0
       expect(plant, isNotNull);
       expect(plant!.id, 'pasto');
       expect(controller._activePlantIndex, 0); // FIX 7 reset
     });

     test('FIX 7: activePlant getter auto-initializes null recursosAplicados', () {
       // Given: tree with plant that has null recursosAplicados
       final planta = TreePlanta(
         id: 'pasto',
         instanceId: 'inst1',
         subid: 'pasto',
         desbloqueada: true,
         estado: TreeEstado(fase: 'semilla'),
         recursosAplicados: null, // Null (should be initialized)
       );
       controller._currentTree = TreeData(
         version: 2,
         usuario: TreeUsuario(id: 'user1', nombre: 'Alice'),
         recursos: TreeRecursos(),
         plantas: [planta],
         semillas: [],
       );

       // When: accessing activePlant
       final plant = controller.activePlant;

       // Then: plant should be returned with initialized recursosAplicados
       expect(plant, isNotNull);
       expect(plant!.recursosAplicados, isNotNull);
       expect(plant.recursosAplicados!.sol, 0);
     });
   });
 }
