import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:frontend/modules/plant_game/plant_controller.dart';
import 'package:frontend/services/shared_tree_storage_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SyncOverlay — Overlay Flame para sincronización Flutter ↔ Unity
//
// Se abre pulsando el botón Button_game_3d (esquina inferior derecha).
// Muestra:
//   • Ruta del archivo compartido
//   • Estado del .tree (existe / tamaño / permisos)
//   • Botón "Exportar ahora" (fuerza re-exportación)
//   • Botón "Importar desde Unity" (aplica cambios de Unity)
//   • Botón ✕ para cerrar
//
// Patrón idéntico al SunOverlay: se añade al PlantGameScreen como child.
// ─────────────────────────────────────────────────────────────────────────────
class SyncOverlay extends FlameGame with TapCallbacks {
  final BuildContext context;

  SyncOverlay({required this.context});

  late _SyncPanel _panel;

  @override
  Future<void> onLoad() async {
    _panel = _SyncPanel(
      gameSize: size,
      context: context,
      onClose: _closeOverlay,
    );
    await add(_panel);
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    _panel.resize(size);
  }

  void _closeOverlay() => removeFromParent();
}

// ─────────────────────────────────────────────────────────────────────────────
// _SyncPanel — Panel visual principal del overlay de sincronización
// ─────────────────────────────────────────────────────────────────────────────
class _SyncPanel extends PositionComponent with TapCallbacks {
  final BuildContext context;
  final VoidCallback onClose;

  // Colores de la UI
  static const _accentColor = Color(0xFF00E5A0);   // verde lima
  static const _dangerColor = Color(0xFFFF5252);   // rojo
  static const _textColor = Color(0xFFE8F5E9);     // blanco verdoso
  static const _mutedColor = Color(0xFF78909C);    // gris suave
  static const _cardColor = Color(0xFF0D2137);     // card fondo

  // Estado de la UI
  _SyncState _state = _SyncState.idle;
  SharedFolderInfo? _info;

  // Subcomponentes de texto
  late TextComponent _titleText;
  late TextComponent _pathText;
  late TextComponent _statusText;
  late TextComponent _messageText;
  late _ActionButton _exportButton;
  late _ActionButton _importButton;
  late _ActionButton _closeButton;

  _SyncPanel({
    required Vector2 gameSize,
    required this.context,
    required this.onClose,
  }) : super(size: gameSize);

  @override
  Future<void> onLoad() async {
    // ── Fondo semitransparente ───────────────────────────────────────────────
    add(RectangleComponent(
      size: size,
      paint: Paint()..color = const Color(0xCC000000),
    ));

    // ── Card central ─────────────────────────────────────────────────────────
    final cardW = size.x * 0.70;
    final cardH = size.y * 0.80;
    final cardX = (size.x - cardW) / 2;
    final cardY = (size.y - cardH) / 2;

    add(RectangleComponent(
      position: Vector2(cardX, cardY),
      size: Vector2(cardW, cardH),
      paint: Paint()..color = _cardColor,
    ));

    // ── Borde acento ─────────────────────────────────────────────────────────
    add(RectangleComponent(
      position: Vector2(cardX, cardY),
      size: Vector2(cardW, 4),
      paint: Paint()..color = _accentColor,
    ));

    final cx = size.x / 2;
    final baseY = cardY + 20;

    // ── Título ────────────────────────────────────────────────────────────────
    _titleText = TextComponent(
      text: '🌿  Sincronización  Unity ↔ Flutter',
      textRenderer: TextPaint(
        style: const TextStyle(
          color: _accentColor,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      anchor: Anchor.topCenter,
      position: Vector2(cx, baseY + 8),
    );
    add(_titleText);

    // ── Ruta del archivo ──────────────────────────────────────────────────────
    _pathText = TextComponent(
      text: 'Cargando...',
      textRenderer: TextPaint(
        style: const TextStyle(
          color: _mutedColor,
          fontSize: 11,
        ),
      ),
      anchor: Anchor.topCenter,
      position: Vector2(cx, baseY + 36),
    );
    add(_pathText);

    // ── Estado del archivo ────────────────────────────────────────────────────
    _statusText = TextComponent(
      text: '',
      textRenderer: TextPaint(
        style: const TextStyle(
          color: _textColor,
          fontSize: 13,
        ),
      ),
      anchor: Anchor.topCenter,
      position: Vector2(cx, baseY + 58),
    );
    add(_statusText);

    // ── Mensaje de operación ──────────────────────────────────────────────────
    _messageText = TextComponent(
      text: '',
      textRenderer: TextPaint(
        style: const TextStyle(
          color: _textColor,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
      anchor: Anchor.topCenter,
      position: Vector2(cx, baseY + 90),
    );
    add(_messageText);

    // ── Botones de acción ─────────────────────────────────────────────────────
    final btnY = cardY + cardH - 95;
    final btnSpacing = cardW / 3;

    _exportButton = _ActionButton(
      label: '📤  Exportar ahora',
      color: _accentColor,
      position: Vector2(cardX + btnSpacing * 0.5, btnY),
      onTap: _onExport,
    );
    add(_exportButton);

    _importButton = _ActionButton(
      label: '📥  Importar Unity',
      color: const Color(0xFF4FC3F7),
      position: Vector2(cardX + btnSpacing * 1.5, btnY),
      onTap: _onImport,
    );
    add(_importButton);

    _closeButton = _ActionButton(
      label: '✕  Cerrar',
      color: _dangerColor,
      position: Vector2(cardX + btnSpacing * 2.5, btnY),
      onTap: onClose,
    );
    add(_closeButton);

    // ── Cargar info inicial ───────────────────────────────────────────────────
    _loadInfo();
  }

  // ── Carga de información ──────────────────────────────────────────────────

  void _loadInfo() async {
    _setState(_SyncState.loading);
    try {
      final controller = Provider.of<PlantController>(context, listen: false);
      _info = await controller.getSharedFolderInfo();
      _applyInfo();
      _setState(_SyncState.idle);
    } catch (e) {
      _setMessage('❌ Error: $e', isError: true);
      _setState(_SyncState.idle);
    }
  }

  void _applyInfo() {
    if (_info == null) return;

    // Ruta (acortada)
    final path = _info!.path;
    _pathText.text = path.length > 55 ? '…${path.substring(path.length - 55)}' : path;

    // Estado
    final existsIcon = _info!.fileExists ? '✅' : '❌';
    final writeIcon = _info!.writable ? '✅' : '❌';
    final size = _info!.fileSize ?? 'N/A';
    final modified = _info!.lastModified != null
        ? _info!.lastModified!.toLocal().toString().substring(0, 16)
        : '--';

    _statusText.text =
        '$existsIcon Archivo: ${_info!.fileExists ? size : "no existe"}  '
        '$writeIcon Escritura  |  Modificado: $modified';
  }

  // ── Acciones ──────────────────────────────────────────────────────────────

  void _onExport() async {
    if (_state == _SyncState.loading) return;
    _setState(_SyncState.loading);

    try {
      final controller = Provider.of<PlantController>(context, listen: false);

      // Paso 1: verificar si ya tiene permiso
      final hasPermission = await controller.checkStoragePermission();

      if (!hasPermission) {
        // Paso 2: abrir Ajustes del sistema
        _setMessage(
          '⚙️ Abriendo Ajustes del sistema...\n'
          'Activa "Acceso a todos los archivos" para esta app,\n'
          'luego regresa y pulsa Exportar de nuevo.',
          isError: false,
        );
        await controller.requestStoragePermission();
        _setState(_SyncState.idle);
        return;
      }

      // Paso 3: exportar (ya tiene permiso)
      _setMessage('Exportando...', isError: false);
      final path = await controller.exportToSharedStorage();
      _setMessage('✅ Exportado a:\n$path', isError: false);
    } catch (e) {
      _setMessage('❌ Error: $e', isError: true);
    }

    _loadInfo();
  }

  void _onImport() async {
    if (_state == _SyncState.loading) return;
    _setState(_SyncState.loading);
    _setMessage('Importando desde Unity...', isError: false);

    try {
      final controller = Provider.of<PlantController>(context, listen: false);
      final success = await controller.importFromSharedStorage();
      if (success) {
        _setMessage('✅ Cambios de Unity aplicados correctamente.', isError: false);
      } else {
        _setMessage('ℹ️ No se encontró archivo .tree para importar.', isError: false);
      }
    } catch (e) {
      _setMessage('❌ Error: $e', isError: true);
    }

    _loadInfo();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  void _setState(_SyncState s) {
    _state = s;
    // Deshabilitar botones durante carga
    _exportButton.setEnabled(s != _SyncState.loading);
    _importButton.setEnabled(s != _SyncState.loading);
  }

  void _setMessage(String msg, {required bool isError}) {
    _messageText.text = msg;
    _messageText.textRenderer = TextPaint(
      style: TextStyle(
        color: isError ? _dangerColor : _accentColor,
        fontSize: 13,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  void resize(Vector2 newSize) {
    size = newSize;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Estado interno del overlay
// ─────────────────────────────────────────────────────────────────────────────
enum _SyncState { idle, loading }

// ─────────────────────────────────────────────────────────────────────────────
// _ActionButton — Botón de texto tapeable
// ─────────────────────────────────────────────────────────────────────────────
class _ActionButton extends PositionComponent with TapCallbacks {
  final String label;
  final Color color;
  final VoidCallback onTap;

  bool _enabled = true;
  late TextComponent _text;
  late RectangleComponent _bg;

  static const double _w = 160;
  static const double _h = 38;

  _ActionButton({
    required this.label,
    required this.color,
    required super.position,
    required this.onTap,
  }) : super(size: Vector2(_w, _h), anchor: Anchor.topCenter);

  @override
  Future<void> onLoad() async {
    _bg = RectangleComponent(
      size: size,
      paint: Paint()..color = color.withValues(alpha: 0.18),
    );
    add(_bg);

    // Borde
    add(RectangleComponent(
      size: Vector2(_w, 2),
      paint: Paint()..color = color,
      position: Vector2(0, _h - 2),
    ));

    _text = TextComponent(
      text: label,
      textRenderer: TextPaint(
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
      anchor: Anchor.center,
      position: Vector2(_w / 2, _h / 2),
    );
    add(_text);
  }

  void setEnabled(bool enabled) {
    _enabled = enabled;
    _bg.paint = Paint()..color = color.withValues(alpha: enabled ? 0.18 : 0.06);
    _text.textRenderer = TextPaint(
      style: TextStyle(
        color: enabled ? color : color.withValues(alpha: 0.35),
        fontSize: 12,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  @override
  void onTapDown(TapDownEvent event) {
    if (!_enabled) return;
    // Flash visual
    _bg.paint = Paint()..color = color.withValues(alpha: 0.40);
    onTap();
  }

  @override
  void onTapUp(TapUpEvent event) {
    _bg.paint = Paint()..color = color.withValues(alpha: _enabled ? 0.18 : 0.06);
  }
}
