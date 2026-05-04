import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:frontend/modules/plant_game/plant_controller.dart';
import 'package:frontend/modules/plant_game/plant_screen.dart';
import 'package:frontend/services/shared_tree_storage_service.dart';

// ═══════════════════════════════════════════════════════════════════════════
// SyncFlutterOverlay
//
// Panel de sincronización Flutter ↔ Unity mostrado vía overlays.add('sync').
//
// UX simplificada:
//   • El permiso se pide una sola vez al entrar al juego (PlantGameWrapper).
//   • Este overlay es solo informativo: muestra el status y el botón
//     "Traer cambios de Unity" que importa con un solo tap.
//   • El auto-export ocurre silenciosamente en cada saveTree().
// ═══════════════════════════════════════════════════════════════════════════
class SyncFlutterOverlay extends StatefulWidget {
  final PlantGameScreen game;
  const SyncFlutterOverlay({super.key, required this.game});

  @override
  State<SyncFlutterOverlay> createState() => _SyncFlutterOverlayState();
}

class _SyncFlutterOverlayState extends State<SyncFlutterOverlay> {
  static const _accent = Color(0xFF00E5A0);
  static const _danger = Color(0xFFFF5252);
  static const _muted  = Color(0xFF78909C);
  static const _card   = Color(0xFF0D2137);
  static const _blue   = Color(0xFF4FC3F7);

  bool _loading = false;
  String _message = '';
  bool _isError = false;
  SharedFolderInfo? _info;

  @override
  void initState() {
    super.initState();
    _loadInfo();
  }

  Future<void> _loadInfo() async {
    setState(() => _loading = true);
    try {
      final info = await context.read<PlantController>().getSharedFolderInfo();
      if (mounted) setState(() => _info = info);
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _onImport() async {
    setState(() { _loading = true; _message = 'Importando...'; _isError = false; });
    try {
      final success = await context.read<PlantController>().importFromSharedStorage();
      _setMsg(success ? '✅ Cambios de Unity aplicados.' : 'ℹ️ Sin archivo .tree para importar.', false);
    } catch (e) {
      _setMsg('❌ Error: $e', true);
    } finally {
      if (mounted) setState(() => _loading = false);
      await _loadInfo();
    }
  }

  Future<void> _onExportNow() async {
    setState(() { _loading = true; _message = 'Exportando...'; _isError = false; });
    try {
      final path = await context.read<PlantController>().exportToSharedStorage();
      _setMsg('✅ $path', false);
    } catch (e) {
      _setMsg('❌ $e', true);
    } finally {
      if (mounted) setState(() => _loading = false);
      await _loadInfo();
    }
  }

  void _setMsg(String msg, bool err) {
    if (mounted) setState(() { _message = msg; _isError = err; });
  }

  void _close() => widget.game.overlays.remove('sync');

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Stack(children: [
        GestureDetector(onTap: _close, child: Container(color: const Color(0xBB000000))),
        Center(child: _card_(context)),
      ]),
    );
  }

  Widget _card_(BuildContext ctx) {
    return Container(
      width: 400,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(12),
        border: Border(top: BorderSide(color: _accent, width: 3)),
        boxShadow: [BoxShadow(color: Colors.black45, blurRadius: 20)],
      ),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Título
        Row(children: [
          const Text('🌿 ', style: TextStyle(fontSize: 18)),
          Text('Sincronización Unity ↔ Flutter',
              style: TextStyle(color: _accent, fontSize: 15, fontWeight: FontWeight.bold)),
          const Spacer(),
          GestureDetector(onTap: _close,
              child: const Icon(Icons.close, color: Colors.white54, size: 20)),
        ]),
        const SizedBox(height: 14),

        // Estado del archivo
        if (_info != null) ...[
          _statusRow('📁 Ruta', _info!.path.length > 48
              ? '…${_info!.path.substring(_info!.path.length - 48)}' : _info!.path),
          _statusRow('📄 Archivo', _info!.fileExists
              ? '✅ Existe  (${_info!.fileSize ?? "?"})'
              : '❌ No existe aún'),
          _statusRow('✏️ Escritura', _info!.writable ? '✅ OK' : '❌ Sin acceso'),
          if (_info!.lastModified != null)
            _statusRow('🕐 Modificado',
                _info!.lastModified!.toLocal().toString().substring(0, 16)),
        ] else if (_loading)
          Center(child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: CircularProgressIndicator(color: _accent, strokeWidth: 2),
          )),

        // Auto-sync notice
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: _accent.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(children: [
            Icon(Icons.sync, color: _accent, size: 14),
            const SizedBox(width: 6),
            Expanded(child: Text(
              'Auto-sync activo: el archivo se actualiza en cada acción del juego.',
              style: TextStyle(color: _accent, fontSize: 10),
            )),
          ]),
        ),

        // Mensaje de operación
        if (_message.isNotEmpty) ...[
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(6)),
            child: Text(_message,
                style: TextStyle(color: _isError ? _danger : _accent,
                    fontSize: 11, fontWeight: FontWeight.bold)),
          ),
        ],

        const SizedBox(height: 18),

        // Botones
        if (_loading)
          const Center(child: CircularProgressIndicator(color: Color(0xFF00E5A0)))
        else
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            _btn('📥 Traer cambios\nde Unity', _blue, _onImport),
            _btn('📤 Forzar\nexportación', _accent, _onExportNow),
            _btn('✕  Cerrar', _danger, _close),
          ]),
      ]),
    );
  }

  Widget _statusRow(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(width: 90, child: Text(label, style: TextStyle(color: _muted, fontSize: 11))),
      Expanded(child: Text(value, style: const TextStyle(color: Colors.white70, fontSize: 11))),
    ]),
  );

  Widget _btn(String label, Color color, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        border: Border(bottom: BorderSide(color: color, width: 2)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label, textAlign: TextAlign.center,
          style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
    ),
  );
}


// ═══════════════════════════════════════════════════════════════════════════
// PlantGameWrapper
//
// Wrapper del GameWidget que solicita MANAGE_EXTERNAL_STORAGE UNA SOLA VEZ
// al montar la pantalla del juego.
//
// Flujo:
//   1. Se monta → verifica si ya tiene permiso
//   2. Si NO → muestra AlertDialog explicativo → abre Ajustes del sistema
//   3. Cuando el usuario regresa → el permiso ya está concedido
//   4. A partir de aquí el auto-sync funciona silenciosamente para siempre
// ═══════════════════════════════════════════════════════════════════════════
class PlantGameWrapper extends StatefulWidget {
  final Widget child;
  const PlantGameWrapper({super.key, required this.child});

  @override
  State<PlantGameWrapper> createState() => _PlantGameWrapperState();
}

class _PlantGameWrapperState extends State<PlantGameWrapper>
    with WidgetsBindingObserver {

  bool _permissionChecked = false;
  bool _permissionGranted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBindingObserver;
    WidgetsBinding.instance.addObserver(this);
    // Pedir permiso cuando el frame esté listo
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkAndRequest());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Al regresar de Ajustes, revisar si el usuario concedió el permiso
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _permissionChecked && !_permissionGranted) {
      _recheckPermission();
    }
  }

  Future<void> _recheckPermission() async {
    final controller = context.read<PlantController>();
    final granted = await controller.checkStoragePermission();
    if (mounted && granted && !_permissionGranted) {
      setState(() => _permissionGranted = true);
      // Ahora que tenemos permiso, exportar el estado actual
      controller.saveTree();
    }
  }

  Future<void> _checkAndRequest() async {
    final controller = context.read<PlantController>();
    final granted = await controller.checkStoragePermission();

    if (!mounted) return;
    setState(() { _permissionChecked = true; _permissionGranted = granted; });

    if (!granted) {
      // Mostrar diálogo explicativo UNA SOLA VEZ
      final shouldOpen = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (_) => const _PermissionDialog(),
      );
      if (shouldOpen == true) {
        await controller.requestStoragePermission();
      }
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}


/// Diálogo explicativo de permisos — se muestra una sola vez.
class _PermissionDialog extends StatelessWidget {
  const _PermissionDialog();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF0D2137),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFF00E5A0), width: 2),
      ),
      title: const Text('🌿 Sincronización con Unity',
          style: TextStyle(color: Color(0xFF00E5A0), fontSize: 16)),
      content: const Text(
        'Para sincronizar tu progreso con la experiencia 3D de Unity, '
        'necesitamos acceso a la carpeta Documentos del dispositivo.\n\n'
        'Solo ocurrirá una vez. Después, todo se sincroniza automáticamente.',
        style: TextStyle(color: Colors.white70, fontSize: 13),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Ahora no', style: TextStyle(color: Colors.white38)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00E5A0),
            foregroundColor: Colors.black,
          ),
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Dar acceso →'),
        ),
      ],
    );
  }
}
