import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/models/tree_models.dart';
import 'package:frontend/services/tree_storage_service.dart';

void main() {
  group('TreeStorageService - Field Authority Tests', () {
    late TreeStorageService service;

    setUp(() {
      service = TreeStorageService();
    });

    // ── Fix 3: Field Authority Tests ──────────────────────────────────────────

    test('Field authority matrix is defined', () {
      // Given: Field authority constant
      // When: accessing the matrix
      // Then: all critical fields are mapped to correct owner
      expect(TreeStorageService._fieldAuthority['usuario.nivel'], 'unity');
      expect(TreeStorageService._fieldAuthority['usuario.xp'], 'unity');
      expect(TreeStorageService._fieldAuthority['usuario.id'], 'flutter');
      expect(TreeStorageService._fieldAuthority['usuario.nombre'], 'flutter');

      expect(TreeStorageService._fieldAuthority['recursos.sol'], 'flutter');
      expect(TreeStorageService._fieldAuthority['recursos.agua'], 'flutter');
      expect(TreeStorageService._fieldAuthority['planta.estado.salud'], 'unity');
      expect(TreeStorageService._fieldAuthority['planta.estado.hpActual'], 'unity');
      expect(TreeStorageService._fieldAuthority['planta.estado.fase'], 'flutter');
      expect(TreeStorageService._fieldAuthority['planta.recursosAplicados.sol'], 'flutter');
    });

    test('validateFieldAuthority: warns if Flutter tries to modify Unity fields', () {
      // Given: existing tree with Unity-owned field set
      final existing = TreeData(
        version: 2,
        usuario: TreeUsuario(id: 'user1', nombre: 'Alice', nivel: 5, xp: 100),
        recursos: TreeRecursos(),
        plantas: [],
        semillas: [],
      );

      // When: Flutter tries to change Unity-owned field
      final flutter = TreeData(
        version: 2,
        usuario: TreeUsuario(id: 'user1', nombre: 'Alice', nivel: 10, xp: 200), // Trying to change nivel
        recursos: TreeRecursos(),
        plantas: [],
        semillas: [],
      );

      // Then: _validateFieldAuthority should log warnings
      // (In real test with mocked debugPrint, verify warning was called)
      service._validateFieldAuthority(flutter, existing: existing);
      // Verification would require mocking debugPrint
    });

    test('mergeFlutterIntoExisting: preserves Unity-owned usuario fields', () {
      // Given: existing tree with Unity data
      final existing = TreeData(
        version: 2,
        usuario: TreeUsuario(id: 'user1', nombre: 'Alice', nivel: 5, xp: 100),
        recursos: TreeRecursos(
          sol: TreeRecurso(cantidad: 50),
          agua: TreeRecurso(cantidad: 30),
          composta: TreeRecurso(cantidad: 10),
          fertilizante: TreeRecurso(cantidad: 5),
        ),
        plantas: [],
        semillas: [],
      );

      // When: Flutter saves updated resources
      final flutter = TreeData(
        version: 2,
        usuario: TreeUsuario(id: 'user1', nombre: 'Alice', nivel: 99, xp: 999), // Trying to change
        recursos: TreeRecursos(
          sol: TreeRecurso(cantidad: 60), // Changed
          agua: TreeRecurso(cantidad: 40), // Changed
          composta: TreeRecurso(cantidad: 15), // Changed
          fertilizante: TreeRecurso(cantidad: 6), // Changed
        ),
        plantas: [],
        semillas: [],
      );

      // Then: merge should preserve Unity fields
      final merged = service._mergeFlutterIntoExisting(flutterData: flutter, existing: existing);

      // Verify Unity fields preserved
      expect(merged.usuario.nivel, 5); // Should NOT be 99
      expect(merged.usuario.xp, 100); // Should NOT be 999

      // Verify Flutter fields updated
      expect(merged.recursos.sol.cantidad, 60); // Should be updated
      expect(merged.recursos.agua.cantidad, 40); // Should be updated
      expect(merged.recursos.composta.cantidad, 15); // Should be updated
    });

    test('mergeFlutterIntoPlantas: preserves Unity plant fields', () {
      // Given: existing plant with Unity-owned fields
      final existing = [
        TreePlanta(
          id: 'pasto',
          instanceId: 'inst1',
          subid: 'pasto',
          desbloqueada: true,
          estado: TreeEstado(
            fase: 'semilla',
            salud: 100, // Unity field
            hpActual: 100, // Unity field
          ),
          recursosAplicados: TreeRecursosAplicados(sol: 3, agua: 2, fertilizante: 1),
          progreso: TreeProgreso(), // Unity field
          visualEstado: TreeVisualEstado(),
          uso: TreeUso(), // Unity field
        ),
      ];

      // When: Flutter updates phase and resources
      final flutter = [
        TreePlanta(
          id: 'pasto',
          instanceId: 'inst1',
          subid: 'pasto',
          desbloqueada: true,
          estado: TreeEstado(
            fase: 'arbusto', // Flutter updated
            salud: 50, // Trying to change (should be ignored)
            hpActual: 50, // Trying to change (should be ignored)
          ),
          recursosAplicados: TreeRecursosAplicados(sol: 5, agua: 4, fertilizante: 2), // Updated
          progreso: TreeProgreso(),
          visualEstado: TreeVisualEstado(),
          uso: TreeUso(),
        ),
      ];

      // Then: merge should preserve Unity fields
      final merged = service._mergeFlutterIntoPlantas(
        flutterPlantas: flutter,
        existingPlantas: existing,
      );

      expect(merged.length, 1);
      expect(merged[0].estado.fase, 'arbusto'); // Flutter updated
      expect(merged[0].estado.salud, 100); // Preserved from existing
      expect(merged[0].estado.hpActual, 100); // Preserved from existing
      expect(merged[0].recursosAplicados.sol, 5); // Updated by Flutter
      expect(merged[0].recursosAplicados.agua, 4); // Updated by Flutter
    });

    test('findMatch: matches plants by instance_id priority', () {
      // Given: plants with matching and non-matching instance IDs
      final target = TreePlanta(
        id: 'pasto',
        instanceId: 'inst123',
        subid: 'pasto',
        desbloqueada: true,
        estado: TreeEstado(fase: 'semilla'),
      );

      final candidates = [
        TreePlanta(
          id: 'pasto',
          instanceId: 'inst999',
          subid: 'pasto',
          desbloqueada: true,
          estado: TreeEstado(fase: 'semilla'),
        ),
        TreePlanta(
          id: 'pasto',
          instanceId: 'inst123', // Matching instance ID
          subid: 'pasto',
          desbloqueada: true,
          estado: TreeEstado(fase: 'semilla'),
        ),
      ];

      // When: finding match
      final match = service._findMatch(target, candidates);

      // Then: should match by instance_id (prioritized)
      expect(match, isNotNull);
      expect(match!.instanceId, 'inst123');
    });

    test('findMatch: fallback to id if only one of that species', () {
      // Given: target with no instance_id match, but one plant of same species
      final target = TreePlanta(
        id: 'solar',
        instanceId: 'new_inst',
        subid: 'solar',
        desbloqueada: true,
        estado: TreeEstado(fase: 'semilla'),
      );

      final candidates = [
        TreePlanta(
          id: 'solar', // Same species
          instanceId: 'other_inst',
          subid: 'solar',
          desbloqueada: true,
          estado: TreeEstado(fase: 'semilla'),
        ),
        TreePlanta(
          id: 'hidro', // Different species
          instanceId: 'hydro_inst',
          subid: 'hidro',
          desbloqueada: true,
          estado: TreeEstado(fase: 'semilla'),
        ),
      ];

      // When: finding match
      final match = service._findMatch(target, candidates);

      // Then: should match by id (fallback, since only one solar)
      expect(match, isNotNull);
      expect(match!.id, 'solar');
    });

     test('findMatch: returns null if multiple matches by id', () {
       // Given: target with multiple candidates of same species
       final target = TreePlanta(
         id: 'solar',
         instanceId: 'new_inst',
         subid: 'solar',
         desbloqueada: true,
         estado: TreeEstado(fase: 'semilla'),
       );

       final candidates = [
         TreePlanta(
           id: 'solar',
           instanceId: 'solar_inst1',
           subid: 'solar',
           desbloqueada: true,
           estado: TreeEstado(fase: 'semilla'),
         ),
         TreePlanta(
           id: 'solar', // Second of same species
           instanceId: 'solar_inst2',
           subid: 'solar',
           desbloqueada: true,
           estado: TreeEstado(fase: 'semilla'),
         ),
       ];

       // When: finding match (ambiguous)
       final match = service._findMatch(target, candidates);

       // Then: should return null (ambiguous)
       expect(match, null);
     });

     // ── FIX 1: Tests for generating instanceId for old plants ────────────────────

     test('FIX 1: mergeUnityIntoPlantas generates instanceId for empty ID plants', () {
       // Given: Flutter plant with empty instanceId (old data, pre-UUID)
       final flutterPlantas = [
         TreePlanta(
           id: 'pasto',
           instanceId: '', // Empty ID (FIX 1 target)
           subid: 'pasto',
           desbloqueada: true,
           estado: TreeEstado(fase: 'semilla'),
           recursosAplicados: TreeRecursosAplicados(sol: 1, agua: 1, fertilizante: 0),
         ),
       ];

       // When: Unity syncs (no matching data for this old plant)
       final result = service._mergeUnityIntoPlantas(
         flutterPlantas: flutterPlantas,
         unityPlantas: [],
       );

       // Then: instanceId should be generated (not empty)
       expect(result.length, 1);
       expect(result[0].instanceId, isNotEmpty);
       expect(result[0].instanceId, isA<String>());
     });

     // ── FIX 4: Tests for fase authority validation ───────────────────────────────

     test('FIX 4: mergeUnityIntoPlantas ignores fase changes from Unity', () {
       // Given: Flutter plant in 'semilla' phase
       final flutterPlantas = [
         TreePlanta(
           id: 'pasto',
           instanceId: 'inst123',
           subid: 'pasto',
           desbloqueada: true,
           estado: TreeEstado(fase: 'semilla'), // Flutter controlled
           recursosAplicados: TreeRecursosAplicados(sol: 1, agua: 1, fertilizante: 0),
         ),
       ];

       // When: Unity tries to change fase to 'planta'
       final unityPlantas = [
         TreePlanta(
           id: 'pasto',
           instanceId: 'inst123',
           subid: 'pasto',
           desbloqueada: true,
           estado: TreeEstado(fase: 'planta', salud: 100, hpActual: 100), // Unity tries to change
           progreso: TreeProgreso(),
           visualEstado: TreeVisualEstado(),
           uso: TreeUso(),
         ),
       ];

       // Then: merge should preserve Flutter's fase ('semilla'), ignore Unity's attempt
       final result = service._mergeUnityIntoPlantas(
         flutterPlantas: flutterPlantas,
         unityPlantas: unityPlantas,
       );

       expect(result.length, 1);
       expect(result[0].estado.fase, 'semilla'); // Should remain 'semilla' (Flutter domain)
       expect(result[0].estado.salud, 100); // Should update from Unity (🔴)
     });

     // ── FIX 5: Tests for duplicate detection and removal ────────────────────────

     test('FIX 5: mergeUnityIntoPlantas deduplicates plants', () {
       // Given: Flutter has one plant, Unity sends same plant twice
       final flutterPlantas = [
         TreePlanta(
           id: 'pasto',
           instanceId: 'inst123',
           subid: 'pasto',
           desbloqueada: true,
           estado: TreeEstado(fase: 'semilla'),
           recursosAplicados: TreeRecursosAplicados(sol: 1, agua: 1, fertilizante: 0),
         ),
       ];

       final unityPlantas = [
         // First copy (new to Flutter)
         TreePlanta(
           id: 'solar',
           instanceId: 'solar_new1',
           subid: 'solar',
           desbloqueada: true,
           estado: TreeEstado(fase: 'semilla', salud: 100, hpActual: 100),
           progreso: TreeProgreso(),
           visualEstado: TreeVisualEstado(),
           uso: TreeUso(),
         ),
         // Duplicate (same instanceId)
         TreePlanta(
           id: 'solar',
           instanceId: 'solar_new1', // Same as above
           subid: 'solar',
           desbloqueada: true,
           estado: TreeEstado(fase: 'semilla', salud: 100, hpActual: 100),
           progreso: TreeProgreso(),
           visualEstado: TreeVisualEstado(),
           uso: TreeUso(),
         ),
       ];

       // When: merging
       final result = service._mergeUnityIntoPlantas(
         flutterPlantas: flutterPlantas,
         unityPlantas: unityPlantas,
       );

       // Then: should have 2 plants (pasto + solar), NOT 3 (no duplicate solar)
       expect(result.length, 2); // pasto + only ONE solar
       final solarPlants = result.where((p) => p.id == 'solar').toList();
       expect(solarPlants.length, 1); // Only one solar should be present
     });

     test('FIX 5: mergeUnityIntoPlantas deduplicates by (id, instanceId) pair', () {
       // Given: Flutter empty, Unity sends duplicates
       final unityPlantas = [
         TreePlanta(
           id: 'solar',
           instanceId: 'inst1',
           subid: 'solar',
           desbloqueada: true,
           estado: TreeEstado(fase: 'semilla', salud: 100, hpActual: 100),
           progreso: TreeProgreso(),
           visualEstado: TreeVisualEstado(),
           uso: TreeUso(),
         ),
         TreePlanta(
           id: 'solar',
           instanceId: 'inst1', // Duplicate pair
           subid: 'solar',
           desbloqueada: true,
           estado: TreeEstado(fase: 'semilla', salud: 100, hpActual: 100),
           progreso: TreeProgreso(),
           visualEstado: TreeVisualEstado(),
           uso: TreeUso(),
         ),
         TreePlanta(
           id: 'pasto',
           instanceId: 'inst2',
           subid: 'pasto',
           desbloqueada: true,
           estado: TreeEstado(fase: 'semilla', salud: 100, hpActual: 100),
           progreso: TreeProgreso(),
           visualEstado: TreeVisualEstado(),
           uso: TreeUso(),
         ),
       ];

       // When: merging (no Flutter plants to update)
       final result = service._mergeUnityIntoPlantas(
         flutterPlantas: [],
         unityPlantas: unityPlantas,
       );

       // Then: should have 2 plants, NOT 3
       expect(result.length, 2); // Only unique pairs
       final uniqueKeys = <String>{};
       for (final p in result) {
         uniqueKeys.add('${p.id}|${p.instanceId}');
       }
       expect(uniqueKeys.length, 2); // Exactly 2 unique pairs
     });

     // ── FIX 6: Tests for JSON validation in applyUnitySync ────────────────────────

     test('FIX 6: applyUnitySync validation - plants have correct default recursosAplicados', () {
       // Given: Unity sends new plant
       final unityPlantas = [
         TreePlanta(
           id: 'solar',
           instanceId: 'solar_new',
           subid: 'solar',
           desbloqueada: true,
           estado: TreeEstado(fase: 'semilla', salud: 100, hpActual: 100),
           progreso: TreeProgreso(),
           visualEstado: TreeVisualEstado(),
           uso: TreeUso(),
         ),
       ];

       // When: merging as new plant
       final result = service._mergeUnityIntoPlantas(
         flutterPlantas: [],
         unityPlantas: unityPlantas,
       );

       // Then: new plant should have correct defaults (FIX 3 + FIX 6)
       expect(result.length, 1);
       expect(result[0].recursosAplicados.sol, 1); // Not 0 (FIX 3)
       expect(result[0].recursosAplicados.agua, 1); // Not 0 (FIX 3)
       expect(result[0].recursosAplicados.fertilizante, 0);
       expect(result[0].desbloqueada, true);
       expect(result[0].estado.fase, 'semilla'); // Flutter default (FIX 3)
     });
   });
 }
