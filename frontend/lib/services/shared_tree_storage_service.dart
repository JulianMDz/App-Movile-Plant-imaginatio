import 'dart:io';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import '../models/tree_models.dart';

// ═══════════════════════════════════════════════════════════════════════════
// SharedTreeStorageService
//
// Exporta/importa el archivo Data_user.tree en Documents/IMAGINATIO/.
//
// Usa un MethodChannel nativo (MainActivity.kt) para:
//   • Obtener la ruta real de Documents via Environment.DIRECTORY_DOCUMENTS
//   • Verificar y pedir MANAGE_EXTERNAL_STORAGE (Android 11+) sin plugins
//
// El canal nativo garantiza que la ruta sea correcta en cualquier dispositivo
// Android, independientemente de la ROM o versión del sistema.
// ═══════════════════════════════════════════════════════════════════════════
class SharedTreeStorageService {
  static const String _folder = 'IMAGINATIO';
  static const String _treeFilename = 'Data_user.tree';
  static const String _metaFilename = '.metadata';

  // Canal nativo definido en MainActivity.kt
  static const _channel = MethodChannel('com.example.frontend/storage');

  // ── Directorio base ───────────────────────────────────────────────────────

  /// Retorna el directorio Documents/IMAGINATIO/, creándolo si no existe.
  /// Android: /storage/emulated/0/Documents/IMAGINATIO/
  Future<Directory> getImaginatioDirectory() async {
    final base = await _getDocumentsDir();
    final dir = Directory('${base.path}/$_folder');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
      debugPrint('[SharedTree] ✅ Carpeta creada: ${dir.path}');
    }
    return dir;
  }

  /// Retorna la referencia al archivo .tree principal.
  Future<File> getTreeFile() async {
    final dir = await getImaginatioDirectory();
    return File('${dir.path}/$_treeFilename');
  }

  // ── Permisos ──────────────────────────────────────────────────────────────

  /// Verifica si ya tenemos acceso a Documents públicos.
  /// En Android 11+ comprueba MANAGE_EXTERNAL_STORAGE via MethodChannel nativo.
  /// Seguro para llamar durante el game loop (no muestra ningún diálogo).
  Future<bool> checkPermissions() async {
    if (!Platform.isAndroid) return true;
    try {
      final granted = await _channel.invokeMethod<bool>('hasAllFilesPermission');
      return granted ?? false;
    } catch (e) {
      debugPrint('[SharedTree] ⚠️ checkPermissions error: $e');
      return false;
    }
  }

  /// Solicita permiso abriendo directamente la pantalla de Ajustes del sistema.
  /// Solo llamar desde una acción explícita del usuario (botón "Exportar").
  /// Retorna true si el permiso ya estaba concedido antes de abrir Ajustes.
  Future<bool> requestPermissions() async {
    if (!Platform.isAndroid) return true;
    try {
      final alreadyGranted = await checkPermissions();
      if (alreadyGranted) return true;

      // Abre Settings > Acceso especial > Todos los archivos
      await _channel.invokeMethod('requestAllFilesPermission');

      // No podemos saber el resultado en tiempo real (el usuario actúa en Settings).
      // El caller debe re-intentar checkPermissions() después de que el usuario regrese.
      return false;
    } catch (e) {
      debugPrint('[SharedTree] ⚠️ requestPermissions error: $e');
      return false;
    }
  }

  // ── Exportar ──────────────────────────────────────────────────────────────

  /// Exporta [tree] al archivo físico Data_user.tree en Documents/IMAGINATIO/.
  ///
  /// [silent] = true  → omite silenciosamente si no hay permisos (game loop).
  /// [silent] = false → lanza excepción si no hay permisos (acción del usuario).
  Future<File?> exportTree(TreeData tree, {bool silent = false}) async {
    // Verificar permisos sin mostrar diálogos
    final hasPermission = await checkPermissions();
    if (!hasPermission) {
      if (silent) {
        debugPrint('[SharedTree] ⚠️ Sin permisos para exportar (silent).');
        return null;
      }
      throw Exception(
        'Sin acceso a Documents. Usa el botón "Exportar" para conceder permiso.',
      );
    }

    try {
      final file = await getTreeFile();
      final jsonStr = tree.toJsonString(pretty: true);
      await file.writeAsString(jsonStr, flush: true);

      await _saveMetadata({
        'last_export': DateTime.now().toUtc().toIso8601String(),
        'user_id': tree.usuario.id,
        'source': 'flutter',
      });

      debugPrint('[SharedTree] ✅ .tree exportado: ${file.path}');
      return file;
    } catch (e) {
      debugPrint('[SharedTree] ❌ Error exportando: $e');
      if (!silent) rethrow;
      return null;
    }
  }

  // ── Importar ──────────────────────────────────────────────────────────────

  /// Lee el archivo Data_user.tree y lo parsea a [TreeData].
  /// Retorna `null` si el archivo no existe o no hay permisos.
  Future<TreeData?> importTree() async {
    final hasPermission = await checkPermissions();
    if (!hasPermission) {
      debugPrint('[SharedTree] ⚠️ Sin permisos para importar.');
      return null;
    }

    final file = await getTreeFile();
    if (!await file.exists()) {
      debugPrint('[SharedTree] ℹ️ No existe archivo .tree para importar.');
      return null;
    }

    final contents = await file.readAsString();
    final json = jsonDecode(contents) as Map<String, dynamic>;
    final data = TreeData.fromJson(json);

    await _saveMetadata({
      'last_import': DateTime.now().toUtc().toIso8601String(),
      'user_id': data.usuario.id,
      'source': 'unity_import',
    });

    debugPrint('[SharedTree] ✅ Importado desde: ${file.path}');
    return data;
  }

  // ── Backup ────────────────────────────────────────────────────────────────

  Future<File?> createBackup(String reason) async {
    try {
      final src = await getTreeFile();
      if (!await src.exists()) return null;

      final dir = await getImaginatioDirectory();
      final ts = DateTime.now().millisecondsSinceEpoch;
      final backup = File('${dir.path}/Data_user_backup_${reason}_$ts.tree');
      await src.copy(backup.path);
      debugPrint('[SharedTree] 💾 Backup: ${backup.path}');
      return backup;
    } catch (e) {
      debugPrint('[SharedTree] ⚠️ Error en backup: $e');
      return null;
    }
  }

  // ── Diagnóstico ───────────────────────────────────────────────────────────

  Future<SharedFolderInfo> getFolderInfo() async {
    try {
      final dir = await getImaginatioDirectory();
      final file = await getTreeFile();
      final exists = await file.exists();

      String? size;
      DateTime? lastModified;
      if (exists) {
        final bytes = await file.length();
        size = '${(bytes / 1024).toStringAsFixed(1)} KB';
        lastModified = await file.lastModified();
      }

      final writable = await _canWrite(dir);

      return SharedFolderInfo(
        path: file.path,
        fileExists: exists,
        fileSize: size,
        lastModified: lastModified,
        writable: writable,
      );
    } catch (e) {
      return SharedFolderInfo(
        path: 'Error: $e',
        fileExists: false,
        fileSize: null,
        lastModified: null,
        writable: false,
      );
    }
  }

  // ── Helpers privados ──────────────────────────────────────────────────────

  /// Obtiene el directorio Documents del dispositivo via MethodChannel nativo.
  /// El canal llama a Environment.getExternalStoragePublicDirectory(DIRECTORY_DOCUMENTS).
  Future<Directory> _getDocumentsDir() async {
    if (Platform.isAndroid) {
      try {
        final path = await _channel.invokeMethod<String>('getDocumentsPath');
        if (path != null && path.isNotEmpty) {
          debugPrint('[SharedTree] Documents path: $path');
          return Directory(path);
        }
      } catch (e) {
        debugPrint('[SharedTree] ⚠️ MethodChannel error: $e — usando fallback');
      }
      // Fallback si el canal falla (no debería ocurrir)
      return Directory('/storage/emulated/0/Documents');
    }
    return await getApplicationDocumentsDirectory();
  }

  Future<bool> _canWrite(Directory dir) async {
    try {
      final test = File('${dir.path}/.write_test');
      await test.writeAsString('ok');
      await test.delete();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _saveMetadata(Map<String, dynamic> data) async {
    try {
      final dir = await getImaginatioDirectory();
      final meta = File('${dir.path}/$_metaFilename');
      await meta.writeAsString(const JsonEncoder.withIndent('  ').convert(data));
    } catch (e) {
      debugPrint('[SharedTree] ⚠️ Error guardando metadata: $e');
    }
  }
}

// ── DTO de diagnóstico ────────────────────────────────────────────────────────

class SharedFolderInfo {
  final String path;
  final bool fileExists;
  final String? fileSize;
  final DateTime? lastModified;
  final bool writable;

  const SharedFolderInfo({
    required this.path,
    required this.fileExists,
    required this.fileSize,
    required this.lastModified,
    required this.writable,
  });
}
