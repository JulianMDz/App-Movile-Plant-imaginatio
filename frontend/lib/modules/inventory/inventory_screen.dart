import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import 'package:frontend/core/audio.dart';
import 'package:frontend/modules/inventory/components/button_close.dart';
import 'package:frontend/modules/inventory/components/filter_panel.dart';
import 'package:frontend/modules/inventory/components/image_button.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:frontend/modules/plant_game/plant_controller.dart';

class InventoryScreen extends FlameGame with DragCallbacks {
  final BuildContext context;
  final int? initialSelectedIndex;

  InventoryScreen(this.context, {this.initialSelectedIndex});

  PlantController? _controller;
  int _selectedPlantIndex = -1;
  List<PositionComponent> _plantSlots = [];

  // Scroll vertical
  double _scrollOffsetY = 0;
  double _maxScrollY = 0;
  bool _isDragging = false;
  double _dragDistance = 0;

  // Constantes de layout compartidas
  static const double _collapsedH = 56.0;
  static const double _marginTop = 42.0;
  static const int _columns = 3;

  static const Map<String, List<String>> _plantTypeFolders = {
    'pasto': ['Pasto'],
    'solar': ['Cajeto', 'Espino', 'Drago', 'Alcaparro', 'Alcaparro grande'],
    'hidro': ['Aliso', 'Cedrillo', 'Cucharo'],
    'xerofito': ['Alcaparro enano', 'Dividivi'],
    'montana': ['Roble', 'Pino romerón', 'Nogal', 'Duraznillo'],
    'templado': ['Manzano', 'Mangle', 'Sietecueros', 'Cedro'],
  };

  String _getPlantImagePath(String plantId, String fase) {
    String faseNum;
    switch (fase) {
      case 'semilla': faseNum = '1'; break;
      case 'arbusto': faseNum = '2'; break;
      case 'planta':  faseNum = '3'; break;
      case 'ent':     faseNum = '4'; break;
      default:        faseNum = '2';
    }

    final tryPath = 'Planta/$plantId/fase${faseNum}_ss.png';
    try {
      images.fromCache(tryPath);
      return tryPath;
    } catch (e) {
      final lowerId = plantId.toLowerCase();
      for (final folders in _plantTypeFolders.values) {
        for (final folder in folders) {
          if (lowerId.contains(folder.toLowerCase()) ||
              folder.toLowerCase().contains(lowerId)) {
            final basePath = 'Planta/$folder/fase${faseNum}_ss.png';
            try {
              images.fromCache(basePath);
              return basePath;
            } catch (_) {
              for (int i = 1; i <= 12; i++) {
                final varPath = 'Planta/$folder$i/fase${faseNum}_ss.png';
                try {
                  images.fromCache(varPath);
                  return varPath;
                } catch (_) {}
              }
            }
          }
        }
      }
    }
    return 'Planta/Pasto/fase${faseNum}_ss.png';
  }

  String _getPlantDisplayName(String plantId) {
    final lowerId = plantId.toLowerCase();
    if (lowerId.contains('pasto')) return 'PASTO';
    if (lowerId.contains('alcaparro enano')) return 'ALCAPARRO ENANO';
    if (lowerId.contains('alcaparro')) return 'ALCAPARRO';
    if (lowerId.contains('cajeto')) return 'CAJETO';
    if (lowerId.contains('espino')) return 'ESPINO';
    if (lowerId.contains('drago')) return 'DRAGO';
    if (lowerId.contains('roble')) return 'ROBLE';
    if (lowerId.contains('pino')) return 'PINO ROMERÓN';
    if (lowerId.contains('nogal')) return 'NOGAL';
    if (lowerId.contains('duraznillo')) return 'DURAZNILLO';
    if (lowerId.contains('manzano')) return 'MANZANO';
    if (lowerId.contains('mangle')) return 'MANGLE';
    if (lowerId.contains('sietecueros')) return 'SIETECUEROS';
    if (lowerId.contains('cedro')) return 'CEDRO';
    if (lowerId.contains('cedrillo')) return 'CEDRILLO';
    if (lowerId.contains('aliso')) return 'ALISO';
    if (lowerId.contains('dividivi')) return 'DIVIDIVI';
    return plantId.toUpperCase();
  }

  @override
  Future<void> onLoad() async {
    _selectedPlantIndex = initialSelectedIndex ?? -1;

    final ctx = context;
    _controller = Provider.of<PlantController>(ctx, listen: false);

    await images.loadAll([
      'Paneles/Fondo_Inv_01.png',
      'Paneles/Panel_DescripciónPlanta_05.png',
      'Inventario/Panel_InvEspacio_01.png',
      'Inventario/Panel_InvEspacio_02.png',
      'Planta/Pasto/fase1_ss.png',
      'Planta/Pasto/fase2_ss.png',
      'Planta/Pasto/fase3_ss.png',
      'Planta/Pasto/fase4_ss.png',
      'Botones/Boton_Cerrar_01.png',
      'Botones/Boton_Categoría_01.png',
      'Botones/Boton_Categoría_02.png',
      'Botones/Boton_Categoría_03.png',
      'Botones/Boton_Categoría_04.png',
      'Botones/Boton_Categoría_05.png',
      'Botones/Boton_Estado_01.png',
      'Botones/Boton_Estado_02.png',
      'Botones/Boton_Estado_03.png',
      'Botones/Boton_Estado_04.png',
      'Botones/Boton_Urgencia_01.png',
      'Botones/Boton_Urgencia_02.png',
      'Botones/Boton_Urgencia_03.png',
      'Botones/Boton_Filtro.png',
      'Botones/Boton_General_01a.png',
      'Iconos/Icono_Semaforo_01.png',
    ]);

    await AudioManager.musicaInventario();

    final plantsToLoad = _controller?.plants ?? [];
    for (final plant in plantsToLoad) {
      final plantId = plant.id;
      final fase = plant.estado.fase;
      final faseNum = _faseToNum(fase);
      final candidates = _buildImageCandidates(plantId, faseNum);
      for (final path in candidates) {
        try {
          await images.load(path);
          break;
        } catch (_) {}
      }
    }

    add(SpriteComponent()
      ..sprite = Sprite(images.fromCache('Paneles/Fondo_Inv_01.png'))
      ..size = size);

    add(FilterPanelComponent(gameRef: this));

    final closeBtn = CloseButtonComponent(ctx);
    closeBtn.position = Vector2(size.x - 82, 10);
    closeBtn.size = Vector2(40, 40);
    closeBtn.priority = 20;
    add(closeBtn);

    _loadPlantSlots();
  }

  static String _faseToNum(String fase) {
    switch (fase) {
      case 'semilla': return '1';
      case 'arbusto': return '2';
      case 'planta':  return '3';
      case 'ent':     return '4';
      default:        return '2';
    }
  }

  List<String> _buildImageCandidates(String plantId, String faseNum) {
    final candidates = <String>[];
    candidates.add('Planta/$plantId/fase${faseNum}_ss.png');
    final lowerId = plantId.toLowerCase();
    for (final folders in _plantTypeFolders.values) {
      for (final folder in folders) {
        if (lowerId.contains(folder.toLowerCase()) ||
            folder.toLowerCase().contains(lowerId)) {
          candidates.add('Planta/$folder/fase${faseNum}_ss.png');
        }
      }
    }
    candidates.add('Planta/Pasto/fase${faseNum}_ss.png');
    return candidates;
  }

  // ── Cálculo de layout compartido ─────────────────────
  double _getSlotSize() {
    final double availableH = size.y - _collapsedH - _marginTop;
    return availableH * 0.40;
  }

  double _getGap() {
    final double slotSize = _getSlotSize();
    final double totalSlotsW = slotSize * _columns;
    final double totalGap = size.x - totalSlotsW;
    return totalGap / (_columns + 1);
  }

  // Posición X base de una columna
  double _colToX(int col) {
    final double slotSize = _getSlotSize();
    final double gap = _getGap();
    return gap * (col + 1) + slotSize * col;
  }

  // Posición Y base de una fila (sin scroll)
  double _rowToBaseY(int row) {
    final double slotSize = _getSlotSize();
    final double gap = _getGap();
    return _marginTop + gap * (row + 1) + slotSize * row;
  }

  void _loadPlantSlots() {
    for (final slot in _plantSlots) {
      slot.removeFromParent();
    }
    _plantSlots.clear();

    _controller = Provider.of<PlantController>(context, listen: false);

    final plants = _controller?.plants ?? [];
    if (plants.isEmpty) {
      _addDefaultSlots();
      return;
    }

    final int displayCount = plants.length;
    final int rows = (displayCount / _columns).ceil();
    final double slotSize = _getSlotSize();
    final double gap = _getGap();

    // Alto total del contenido — para calcular scroll máximo
    final double totalContentH = _marginTop + rows * slotSize + (rows + 1) * gap;
    // Área visible disponible para los slots (sin drawer ni margen)
    final double visibleH = size.y - _collapsedH;
    _maxScrollY = (totalContentH - visibleH).clamp(0, double.infinity);
    _scrollOffsetY = 0;

    for (int i = 0; i < displayCount; i++) {
      final int col = i % _columns;
      final int row = i ~/ _columns;
      final double x = _colToX(col);
      final double y = _rowToBaseY(row);
      _addPlantSlot(Vector2(x, y), slotSize, slotSize, plants[i], i);
    }
  }

  void _addDefaultSlots() {
    final double slotSize = _getSlotSize();
    final double gap = _getGap();
    final double slotY = _marginTop + gap;

    _addSlot(Vector2(_colToX(0), slotY), slotSize, slotSize, true);
    _addSlot(Vector2(_colToX(1), slotY), slotSize, slotSize, false);
    _addSlot(Vector2(_colToX(2), slotY), slotSize, slotSize, false);
  }

  void _addPlantSlot(
      Vector2 pos, double slotW, double slotH, dynamic plant, int index) {
    final slot = PositionComponent()
      ..position = pos
      ..size = Vector2(slotW, slotH);

    final isSelected = index == _selectedPlantIndex;
    final isAlive = plant.estado?.fase != 'muerto' && plant.desbloqueada;

    slot.add(SpriteComponent()
      ..sprite = Sprite(images.fromCache(
        isSelected
            ? 'Inventario/Panel_InvEspacio_01.png'
            : 'Inventario/Panel_InvEspacio_02.png',
      ))
      ..size = Vector2(slotW, slotH));

    if (isAlive) {
      final plantId = plant.id ?? 'pasto';
      final fase = plant.estado?.fase ?? 'arbusto';
      final displayName = _getPlantDisplayName(plantId);
      final imagePath = _getPlantImagePath(plantId, fase);

      slot.add(TextComponent(
        text: displayName,
        anchor: Anchor.topCenter,
        position: Vector2(slotW / 2, slotH * 0.16),
        textRenderer: TextPaint(
          style: const TextStyle(
            fontSize: 10,
            fontFamily: 'Press Start 2P',
            color: Color(0xFF3E2A1F),
            fontWeight: FontWeight.bold,
          ),
        ),
      ));

      try {
        final img = images.fromCache(imagePath);
        final double plantSize = slotW * 0.4;
        slot.add(SpriteComponent()
          ..sprite = Sprite(
            img,
            srcPosition: Vector2(0, 0),
            srcSize: Vector2(img.width / 18, img.height.toDouble()),
          )
          ..size = Vector2(plantSize, plantSize)
          ..anchor = Anchor.center
          ..position = Vector2(slotW / 2, slotH / 2));
      } catch (e) {
        debugPrint(
            '[Inventory] Error cargando imagen: $imagePath - usando Pasto fallback');
        final fallbackImg = images.fromCache('Planta/Pasto/fase2_ss.png');
        final double plantSize = slotW * 0.4;
        slot.add(SpriteComponent()
          ..sprite = Sprite(
            fallbackImg,
            srcPosition: Vector2(0, 0),
            srcSize: Vector2(fallbackImg.width / 18, fallbackImg.height.toDouble()),
          )
          ..size = Vector2(plantSize, plantSize)
          ..anchor = Anchor.center
          ..position = Vector2(slotW / 2, slotH * 0.16));
      }

      final double iconH = slotH * 0.16;
      final double iconY = slotH - iconH - slotH * 0.13;
      const double iconGap = 6.0;

      final recursos = plant.recursosAplicados;
      final sol = recursos?.sol ?? 0;
      final agua = recursos?.agua ?? 0;

      String estadoIcon = 'Botones/Boton_Estado_02.png';
      if (sol <= 0 || agua <= 0) {
        estadoIcon = 'Botones/Boton_Urgencia_01.png';
      } else if (sol <= 3 || agua <= 3) {
        estadoIcon = 'Botones/Boton_Estado_03.png';
      }

      final iconPaths = [
        'Botones/Boton_Categoría_01.png',
        estadoIcon,
        'Iconos/Icono_Semaforo_01.png',
      ];

      final List<double> iconWidths = iconPaths.map((path) {
        final iconImg = images.fromCache(path);
        final double ratio = iconImg.width / iconImg.height;
        return iconH * ratio;
      }).toList();

      final double totalIconW = iconWidths.fold(0.0, (sum, w) => sum + w) +
          iconGap * (iconPaths.length - 1);
      double ix = (slotW - totalIconW) / 2;

      for (int i = 0; i < iconPaths.length; i++) {
        final iconImg = images.fromCache(iconPaths[i]);
        final double ratio = iconImg.width / iconImg.height;
        final double iconW = iconH * ratio;
        slot.add(SpriteComponent()
          ..sprite = Sprite(images.fromCache(iconPaths[i]))
          ..size = Vector2(iconW, iconH)
          ..position = Vector2(ix, iconY));
        ix += iconW + iconGap;
      }

      slot.add(_TappableSlot(
        slotSize: Vector2(slotW, slotH),
        gameRef: this,
        plantIndex: index,
        onTap: (int i) {
          // Solo seleccionar si no se estaba arrastrando
          if (_isDragging) return;
          _onPlantSelected(i);
        },
      )..size = Vector2(slotW, slotH));
    } else {
      slot.add(TextComponent(
        text: 'MUERTA',
        anchor: Anchor.center,
        position: Vector2(slotW / 2, slotH / 2),
        textRenderer: TextPaint(
          style: const TextStyle(
            fontSize: 10,
            fontFamily: 'Press Start 2P',
            color: Color(0xFF666666),
            fontWeight: FontWeight.bold,
          ),
        ),
      ));
    }

    add(slot);
    _plantSlots.add(slot);
  }

  void _onPlantSelected(int index) {
    setState(() {
      _selectedPlantIndex = index;
    });
    _controller?.setActivePlant(index);
    _loadPlantSlots();
    debugPrint('[Inventory] Planta seleccionada: $index');
  }

  void setState(VoidCallback fn) {
    fn();
    children
        .whereType<FilterPanelComponent>()
        .forEach((c) => c.removeFromParent());
    children
        .whereType<CloseButtonComponent>()
        .forEach((c) => c.removeFromParent());

    add(FilterPanelComponent(gameRef: this));

    final closeBtn = CloseButtonComponent(context);
    closeBtn.position = Vector2(size.x - 108, 32);
    closeBtn.size = Vector2(40, 40);
    closeBtn.priority = 20;
    add(closeBtn);
  }

  void _addSlot(Vector2 pos, double slotW, double slotH, bool full) {
    final slot = PositionComponent()
      ..position = pos
      ..size = Vector2(slotW, slotH);

    slot.add(SpriteComponent()
      ..sprite = Sprite(images.fromCache(
        full
            ? 'Inventario/Panel_InvEspacio_01.png'
            : 'Inventario/Panel_InvEspacio_02.png',
      ))
      ..size = Vector2(slotW, slotH));

    if (full) {
      slot.add(TextComponent(
        text: 'PASTO',
        anchor: Anchor.topCenter,
        position: Vector2(slotW / 2, slotH * 0.16),
        textRenderer: TextPaint(
          style: const TextStyle(
            fontSize: 10,
            fontFamily: 'Press Start 2P',
            color: Color(0xFF3E2A1F),
            fontWeight: FontWeight.bold,
          ),
        ),
      ));

      final img = images.fromCache('Planta/Pasto/fase2_ss.png');
      final double plantSize = slotW * 0.32;
      slot.add(SpriteComponent()
        ..sprite = Sprite(
          img,
          srcPosition: Vector2(0, 0),
          srcSize: Vector2(img.width / 18, img.height.toDouble()),
        )
        ..size = Vector2(plantSize, plantSize)
        ..anchor = Anchor.center
        ..position = Vector2(slotW / 2, slotH * 0.50));

      final double iconH = slotH * 0.16;
      final double iconY = slotH - iconH - slotH * 0.13;
      const double iconGap = 6.0;

      final iconPaths = [
        'Botones/Boton_Categoría_01.png',
        'Botones/Boton_Estado_02.png',
        'Iconos/Icono_Semaforo_01.png',
      ];

      final List<double> iconWidths = iconPaths.map((path) {
        final iconImg = images.fromCache(path);
        final double ratio = iconImg.width / iconImg.height;
        return iconH * ratio;
      }).toList();

      final double totalIconW = iconWidths.fold(0.0, (sum, w) => sum + w) +
          iconGap * (iconPaths.length - 1);
      double ix = (slotW - totalIconW) / 2;

      for (int i = 0; i < iconPaths.length; i++) {
        final iconImg = images.fromCache(iconPaths[i]);
        final double ratio = iconImg.width / iconImg.height;
        final double iconW = iconH * ratio;
        slot.add(SpriteComponent()
          ..sprite = Sprite(images.fromCache(iconPaths[i]))
          ..size = Vector2(iconW, iconH)
          ..position = Vector2(ix, iconY));
        ix += iconW + iconGap;
      }

      slot.add(_TappableSlot(
        slotSize: Vector2(slotW, slotH),
        gameRef: this,
      )..size = Vector2(slotW, slotH));
    }

    add(slot);
  }

  // ── Scroll vertical ───────────────────────────────────
  @override
  void onDragUpdate(DragUpdateEvent event) {
    final dy = event.localDelta.y;

    // Marcar como dragging si el movimiento es suficiente
    if (dy.abs() > 12) {
      _isDragging = true;
    }

    // Scroll: arrastrar hacia arriba = ver más plantas abajo
    _scrollOffsetY -= dy;
    _scrollOffsetY = _scrollOffsetY.clamp(0.0, _maxScrollY);

    // Mover cada slot según el scroll
    for (int i = 0; i < _plantSlots.length; i++) {
      final int row = i ~/ _columns;
      final int col = i % _columns;
      _plantSlots[i].position.x = _colToX(col);
      _plantSlots[i].position.y = _rowToBaseY(row) - _scrollOffsetY;
    }
  }

@override
void onDragEnd(DragEndEvent event) {
  super.onDragEnd(event);
  Future.delayed(const Duration(milliseconds: 150), () {
    _isDragging = false;
    _dragDistance = 0; // resetear distancia acumulada
  });
}
}

// -------------------------------------------------------
// Slot tappable
// -------------------------------------------------------
class _TappableSlot extends PositionComponent with TapCallbacks {
  final Vector2 slotSize;
  final FlameGame gameRef;
  final int? plantIndex;
  final Function(int)? onTap;
  bool _expanded = false;

  _TappableSlot({required this.slotSize, required this.gameRef, this.plantIndex, this.onTap});

  @override
  void onTapDown(TapDownEvent event) {
    if (_expanded) return;
    if (plantIndex == null || onTap == null) return;

    AudioManager.click();
    onTap!(plantIndex!);
    _expanded = true;
    gameRef.add(_ExpandedOverlay(
      gameRef: gameRef,
      plant: (gameRef as InventoryScreen)._controller!.plants[plantIndex!],
      onClose: () => _expanded = false,
    )..size = gameRef.size);
    event.continuePropagation = false;
  }
}

// -------------------------------------------------------
// Overlay expandido
// -------------------------------------------------------
class _ExpandedOverlay extends PositionComponent with TapCallbacks {
  final FlameGame gameRef;
  final VoidCallback onClose;
  final dynamic plant;

  _ExpandedOverlay({required this.gameRef, required this.onClose, required this.plant});

  @override
  Future<void> onLoad() async {
    priority = 10;
    size = gameRef.size;

    add(RectangleComponent(
      size: gameRef.size,
      paint: Paint()..color = const Color(0x33000000),
    ));

    const double collapsedH = 52.0;
    const double marginTop = 40.0;//15
    const double marginSide = 30.0;
    const double btnH = 44.0;
    const double btnGap = 10.0;

    final double availH =
        gameRef.size.y - collapsedH - marginTop - btnH - btnGap - 8.0;
    final double availW = gameRef.size.x - marginSide * 2;
    final double panelSize = availH < availW ? availH : availW;

    final double panelX = (gameRef.size.x - panelSize) / 2;
    final double panelY = marginTop;

    add(SpriteComponent()
      ..sprite = Sprite(gameRef.images.fromCache('Inventario/Panel_InvEspacio_01.png'))
      ..size = Vector2(panelSize, panelSize)
      ..position = Vector2(panelX, panelY));

    final lowerId = plant.id ?? 'pasto';
    final displayName = (gameRef as InventoryScreen)._getPlantDisplayName(lowerId);

    add(TextComponent(
      text: displayName,
      anchor: Anchor.topCenter,
      position: Vector2(gameRef.size.x / 2, panelY + panelSize * 0.16),
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 18,
          fontFamily: 'Press Start 2P',
          color: Color(0xFF3E2A1F),
          fontWeight: FontWeight.bold,
        ),
      ),
    ));

    final img = gameRef.images.fromCache('Planta/Pasto/fase2_ss.png');
    final double plantSize = panelSize * 0.32; 
    add(SpriteComponent()
      ..sprite = Sprite(
        img,
        srcPosition: Vector2(0, 0),
        srcSize: Vector2(img.width / 18, img.height.toDouble()),
      )
      ..size = Vector2(plantSize, plantSize)
      ..anchor = Anchor.center
      ..position = Vector2(gameRef.size.x / 2, panelY + panelSize * 0.50));

    final double iconH = panelSize * 0.15;
    final double iconY = panelY + panelSize - iconH - panelSize * 0.13;
    const double gap = 8.0;

    final iconPaths = [
      'Botones/Boton_Categoría_01.png',
      'Botones/Boton_Estado_02.png',
      'Iconos/Icono_Semaforo_01.png',
    ];

    final List<double> iconWidths = iconPaths.map((path) {
      final iconImg = gameRef.images.fromCache(path);
      final double ratio = iconImg.width / iconImg.height;
      return iconH * ratio;
    }).toList();

    final double totalIconW =
        iconWidths.fold(0.0, (sum, w) => sum + w) + gap * (iconPaths.length - 1);
    double ix = (gameRef.size.x - totalIconW) / 2;

    for (int i = 0; i < iconPaths.length; i++) {
      final iconImg = gameRef.images.fromCache(iconPaths[i]);
      final double ratio = iconImg.width / iconImg.height;
      final double iconW = iconH * ratio;
      add(SpriteComponent()
        ..sprite = Sprite(gameRef.images.fromCache(iconPaths[i]))
        ..size = Vector2(iconW, iconH)
        ..position = Vector2(ix, iconY));
      ix += iconW + gap;
    }

    final double btnY = panelY + panelSize + btnGap;
    final double btnW = panelSize * 0.42;

    // Botón Volver — click y cierra overlay
    add(ImageButton(
      label: 'Volver',
      position: Vector2(panelX, btnY),
      btnSize: Vector2(btnW, btnH),
      gameRef: gameRef,
      onTap: () {
        AudioManager.click();
        gameRef.remove(this);
        onClose();
      },
    ));

    // Botón Seleccionar — click, detiene música y navega
    add(ImageButton(
      label: 'Seleccionar',
      position: Vector2(panelX + panelSize - btnW, btnY),
      btnSize: Vector2(btnW, btnH),
      gameRef: gameRef,
      onTap: () {
        AudioManager.click();
        AudioManager.stopMusica();
        gameRef.remove(this);
        onClose();
        if (gameRef is InventoryScreen) {
          GoRouter.of((gameRef as InventoryScreen).context).go('/plant_game');
        }
      },
    ));
  }

  @override
  void onTapDown(TapDownEvent event) {
    event.continuePropagation = true;
  }
}



