import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/tree_models.dart';

// ═══════════════════════════════════════════════════════════════════════════
// TreeStorageService
//
// Responsable de leer y escribir el archivo .tree (JSON v2) en
// SharedPreferences bajo la clave [_treeKey].
//
// Equivalente Flutter de syncInventoryToTree() + applyTreeDataFrom3D()
// del equipo web (Astro/Preact).
//
// REGLA DE MERGE:
//   - Flutter solo sobreescribe campos 🟢 de su dominio.
//   - Los campos 🔴 de Unity se leen del .tree existente y se preservan.
//   - Matching de plantas: por instance_id (prioritario), fallback por id.
// ═══════════════════════════════════════════════════════════════════════════
class TreeStorageService {
  /// Clave SharedPreferences — coincide con localStorage del equipo web.
  static const String _treeKey = 'imaginatio_tree_data';
  /// Clave SharedPreferences para recursos de Flutter (sol, agua, composta, fertilizante).
  static const String _recursosFlutterKey = 'imaginatio_recursos_flutter';

  // ── Lectura ───────────────────────────────────────────────────────────────

  /// Carga el .tree desde SharedPreferences.
  /// Combina los recursos del .tree con los recursos guardados en SharedPreferences
  /// (sol, agua, composta, fertilizante) que Flutter mantiene separados de Unity.
  Future<TreeData?> loadTree() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_treeKey);
      if (raw == null || raw.isEmpty) return null;
      
      final treeData = TreeData.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      debugPrint('[TreeStorageService] loadTree .tree recursos: sol=${treeData.recursos.sol.cantidad} agua=${treeData.recursos.agua.cantidad} composta=${treeData.recursos.composta.cantidad} fertilizante=${treeData.recursos.fertilizante.cantidad}');
      
      // Combinar recursos de Flutter desde SharedPreferences
      final recursosFlutter = await loadRecursosFlutter();
      if (recursosFlutter != null) {
        // Usar recursos de SharedPreferences (los más actualizados de Flutter)
        debugPrint('[TreeStorageService] loadTree usando recursos de SharedPreferences');
        return TreeData(
          version: treeData.version,
          usuario: treeData.usuario,
          recursos: recursosFlutter,
          plantas: treeData.plantas,
          semillas: treeData.semillas,
        );
      }
      
      debugPrint('[TreeStorageService] loadTree sin recursos de SharedPreferences, usando .tree');
      return treeData;
    } catch (e) {
      debugPrint('[TreeStorageService] Error al cargar .tree: $e');
      return null;
    }
  }

  /// Carga los recursos de Flutter desde SharedPreferences.
  /// Retorna null si no existen.
  Future<TreeRecursos?> loadRecursosFlutter() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_recursosFlutterKey);
      debugPrint('[TreeStorageService] loadRecursosFlutter raw: $raw');
      if (raw == null || raw.isEmpty) return null;
      final result = TreeRecursos.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      debugPrint('[TreeStorageService] loadRecursosFlutter result: sol=${result.sol.cantidad} agua=${result.agua.cantidad} composta=${result.composta.cantidad} fertilizante=${result.fertilizante.cantidad}');
      return result;
    } catch (e) {
      debugPrint('[TreeStorageService] Error al cargar recursos Flutter: $e');
      return null;
    }
  }

  /// Guarda los recursos de Flutter en SharedPreferences (separado del .tree).
  Future<void> saveRecursosFlutter(TreeRecursos recursos) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_recursosFlutterKey, jsonEncode(recursos.toJson()));
      debugPrint(
        '[TreeStorageService] Recursos Flutter guardados ✓ — '
        'sol:${recursos.sol.cantidad} '
        'agua:${recursos.agua.cantidad} '
        'composta:${recursos.composta.cantidad} '
        'fertilizante:${recursos.fertilizante.cantidad}',
      );
    } catch (e) {
      debugPrint('[TreeStorageService] Error al guardar recursos Flutter: $e');
      rethrow;
    }
  }

  // ── Escritura con merge (Flutter → .tree) ─────────────────────────────────

/// Persiste [flutterData] como .tree v2, preservando los campos 🔴 de
  /// Unity que ya estaban guardados.
  ///
  /// Flujo:
  /// 1. Lee el .tree existente para recuperar campos 🔴 de Unity.
  /// 2. Hace merge: campos 🟢 de [flutterData] + campos 🔴 del existente.
  /// 3. Persiste el resultado en SharedPreferences.
  Future<void> saveTreeLocally({required TreeData flutterData}) async {
    try {
      debugPrint('[TreeStorageService] saveTreeLocally input: sol=${flutterData.recursos.sol.cantidad} agua=${flutterData.recursos.agua.cantidad} composta=${flutterData.recursos.composta.cantidad} fertilizante=${flutterData.recursos.fertilizante.cantidad}');
      
      // Guardar recursos de Flutter en SharedPreferences (separado del .tree para Unity)
      await saveRecursosFlutter(flutterData.recursos);

      // Guardar .tree para Unity (sin los recursos de Flutter - se preservan del existente)
      final existing = await loadTree();
      final merged = _mergeFlutterIntoExisting(
        flutterData: flutterData,
        existing: existing,
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_treeKey, merged.toJsonString());

      debugPrint(
        '[TreeStorageService] .tree guardado ✓ — '
        'sol:${merged.recursos.sol.cantidad} '
        'agua:${merged.recursos.agua.cantidad} '
        'composta:${merged.recursos.composta.cantidad}',
      );
} catch (e) {
      debugPrint('[TreeStorageService] Error al guardar .tree: $e');
      rethrow;
    }
  }

  // ── Sync desde Unity (Unity → .tree) ─────────────────────────────────────

  /// Aplica los datos exportados por Unity al .tree local.
  /// Equivalente al botón "Sync desde 3D" del equipo web.
  ///
  /// Solo actualiza campos 🔴 de Unity:
  ///   - usuario.nivel y usuario.xp
  ///   - planta.estado.salud, planta.estado.hp_actual
  ///   - planta.progreso.*, planta.uso.*
  ///   - Semillas nuevas (dedup por seed_id)
  ///
  /// Los campos 🟢 de Flutter NUNCA se modifican.
  Future<void> applyUnitySync(TreeData unityData) async {
    try {
      final current = await loadTree();
      if (current == null) {
        debugPrint('[TreeStorageService] No hay .tree local — sync Unity ignorado.');
        return;
      }

      // Usuario: actualizar solo nivel/xp (🔴), preservar id/nombre (🟢)
      final mergedUsuario = TreeUsuario(
        id: current.usuario.id, // 🟢 Flutter — no tocar
        nombre: current.usuario.nombre, // 🟢 Flutter — no tocar
        nivel: unityData.usuario.nivel, // 🔴 Unity actualiza
        xp: unityData.usuario.xp, // 🔴 Unity actualiza
      );

      // Plantas: merge por instance_id / fallback por id
      final mergedPlantas = _mergeUnityIntoPlantas(
        flutterPlantas: current.plantas,
        unityPlantas: unityData.plantas,
      );

      // Semillas: agregar solo las nuevas de Unity (dedup por seed_id)
      final existingSeedIds = current.semillas.map((s) => s.seedId).toSet();
      final newSeeds = unityData.semillas
          .where((s) => !existingSeedIds.contains(s.seedId))
          .toList();

      final result = TreeData(
        version: 2,
        usuario: mergedUsuario,
        recursos: current.recursos, // 🟢 Flutter — no tocar nunca
        plantas: mergedPlantas,
        semillas: [...current.semillas, ...newSeeds],
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_treeKey, result.toJsonString());

      debugPrint(
        '[TreeStorageService] Sync Unity aplicado ✓ — '
        '${newSeeds.length} semilla(s) nueva(s)',
      );
    } catch (e) {
      debugPrint('[TreeStorageService] Error en applyUnitySync: $e');
      rethrow;
    }
  }

  /// Elimina el .tree local. Útil para pruebas o cierre de sesión.
  Future<void> clearTree() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_treeKey);
    debugPrint('[TreeStorageService] .tree eliminado.');
  }

  // ── Lógica interna ────────────────────────────────────────────────────────

  /// Combina [flutterData] (fuente 🟢) con los campos 🔴 de [existing].
  /// Si [existing] es null (primer guardado), retorna [flutterData] directo.
  TreeData _mergeFlutterIntoExisting({
    required TreeData flutterData,
    TreeData? existing,
  }) {
    if (existing == null) return flutterData;

    // Preservar nivel/xp de Unity en el usuario
    final mergedUsuario = TreeUsuario(
      id: flutterData.usuario.id, // 🟢
      nombre: flutterData.usuario.nombre, // 🟢
      nivel: existing.usuario.nivel, // 🔴 preservado
      xp: existing.usuario.xp, // 🔴 preservado
    );

    // Merge plantas: Flutter trae los campos 🟢, Unity aporta los 🔴
    final mergedPlantas = _mergeFlutterIntoPlantas(
      flutterPlantas: flutterData.plantas,
      existingPlantas: existing.plantas,
    );

    return TreeData(
      version: 2,
      usuario: mergedUsuario,
      recursos: existing.recursos,
      plantas: mergedPlantas,
      semillas: existing.semillas,
    );
  }

  /// Para cada planta de [flutterPlantas], busca su contraparte en
  /// [existingPlantas] y le aplica los campos 🔴 de Unity preservados.
  ///
  /// Matching: instance_id prioritario → fallback por id de especie.
  List<TreePlanta> _mergeFlutterIntoPlantas({
    required List<TreePlanta> flutterPlantas,
    required List<TreePlanta> existingPlantas,
  }) {
    return flutterPlantas.map((fp) {
      final match = _findMatch(fp, existingPlantas);
      if (match == null) return fp; // planta nueva, sin datos Unity

      // Construir planta final: campos 🟢 de fp + campos 🔴 de match
      return TreePlanta(
        id: fp.id, // 🟢
        instanceId: fp.instanceId, // 🟢 inmutable
        subid: fp.subid, // 🟢
        desbloqueada: fp.desbloqueada, // 🟢
        estado: TreeEstado(
          fase: fp.estado.fase, // 🟢 Flutter actualiza
          salud: match.estado.salud, // 🔴 Unity — preservar
          hpActual: match.estado.hpActual, // 🔴 Unity — preservar
        ),
        progreso: match.progreso, // 🔴 completo de Unity
        visualEstado: fp.visualEstado, // 🟢
        uso: match.uso, // 🔴 completo de Unity
        recursosAplicados: fp.recursosAplicados, // 🟢
      );
    }).toList();
  }

  /// Para cada planta existente (Flutter), busca la versión de Unity y aplica
  /// solo los campos 🔴. También agrega nuevas plantas de Unity que no existen en Flutter.
  /// Usado en [applyUnitySync].
  List<TreePlanta> _mergeUnityIntoPlantas({
    required List<TreePlanta> flutterPlantas,
    required List<TreePlanta> unityPlantas,
  }) {
    // 1. Mantener plantas existentes de Flutter (actualizadas por Unity)
    final mergedPlantas = flutterPlantas.map((fp) {
      final unityMatch = _findMatch(fp, unityPlantas);
      if (unityMatch == null) return fp; // Unity no tiene datos de esta planta

      return TreePlanta(
        id: fp.id, // 🟢 preservado
        instanceId: fp.instanceId, // 🟢 inmutable
        subid: fp.subid, // 🟢 preservado
        desbloqueada: fp.desbloqueada, // 🟢 preservado
        estado: TreeEstado(
          fase: fp.estado.fase, // 🟢 Flutter — no tocar
          salud: unityMatch.estado.salud, // 🔴 Unity actualiza
          hpActual: unityMatch.estado.hpActual, // 🔴 Unity actualiza
        ),
        progreso: unityMatch.progreso, // 🔴 Unity actualiza
        visualEstado: fp.visualEstado, // 🟢 preservado
        uso: unityMatch.uso, // 🔴 Unity actualiza
        recursosAplicados: fp.recursosAplicados, // 🟢 preservado
      );
    }).toList();

    // 2. Agregar plantas nuevas de Unity que no existen en Flutter
    final existingInstanceIds = flutterPlantas.map((p) => p.instanceId).toSet();
    final existingIds = flutterPlantas.map((p) => p.id).toSet();
    
    final newPlantsFromUnity = <TreePlanta>[];
    
    for (final up in unityPlantas) {
      // Agregar si es una nueva planta (instance_id no existe en Flutter)
      if (!existingInstanceIds.contains(up.instanceId)) {
        newPlantsFromUnity.add(TreePlanta(
          id: up.id,
          instanceId: up.instanceId,
          subid: up.subid,
          desbloqueada: true,
          estado: TreeEstado(fase: 'semilla'), // 🟢 default
          progreso: up.progreso,
          visualEstado: TreeVisualEstado(),
          uso: up.uso,
          recursosAplicados: TreeRecursosAplicados(sol: 1, agua: 1, fertilizante: 0), // 🟢 default
        ));
      }
    }

    return [...mergedPlantas, ...newPlantsFromUnity];
  }

  /// Busca la contraparte de [target] en [candidates].
  /// Prioridad: instance_id → fallback por id (si solo hay una de esa especie).
  TreePlanta? _findMatch(TreePlanta target, List<TreePlanta> candidates) {
    // 1. Matching por instance_id (prioritario, nunca ambiguo)
    if (target.instanceId.isNotEmpty) {
      final byInstanceId = candidates
          .where((c) => c.instanceId == target.instanceId)
          .toList();
      if (byInstanceId.isNotEmpty) return byInstanceId.first;
    }

    // 2. Fallback por id de especie (solo si hay exactamente una)
    final byId = candidates.where((c) => c.id == target.id).toList();
    return byId.length == 1 ? byId.first : null;
  }
}
