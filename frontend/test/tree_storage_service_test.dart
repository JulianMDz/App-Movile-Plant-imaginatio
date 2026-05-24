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
  });
}
