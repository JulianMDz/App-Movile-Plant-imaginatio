import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:frontend/core/audio.dart';
import 'package:frontend/modules/plant_game/plant_controller.dart';

class InventoryScreen extends FlameGame {
  final BuildContext context;
  final int? initialSelectedIndex;

  InventoryScreen(this.context, {this.initialSelectedIndex});

  PlantController? _controller;
  int _selectedPlantIndex = -1;
  List<PositionComponent> _plantSlots = [];

  static const Map<String, String> _plantImageMap = {
    'pasto': 'Planta/Pasto/fase2_ss.png',
    'solar': 'Planta/Solar/fase2_ss.png',
    'hidro': 'Planta/Hidro/fase2_ss.png',
    'xerofito': 'Planta/Xerofito/fase2_ss.png',
    'templado': 'Planta/Templado/fase2_ss.png',
    'montana': 'Planta/Montana/fase2_ss.png',
  };

  static const Map<String, String> _plantNameMap = {
    'pasto': 'PASTO',
    'solar': 'SOLAR',
    'hidro': 'HIDRO',
    'xerofito': 'XEROFITO',
    'templado': 'TEMPLADO',
    'montana': 'MONTANA',
  };

  // Mapa de plantas a carpetas disponibles en assets
  // El código busca la primera carpeta que coincida con el prefijo
  static const List<String> _plantFolders = [
    'Alcaparro enano',
    'Cajeto',
    'Espino',
    'Drago',
    'Cedro',
    'Cedrillo',
    'Sietecueros',
    'Pino romerón',
    'Duraznillo',
    'Mangle',
    'Manzano',
    'Aliso',
    'Dividivi',
    'Nogal',
    'Pasto',
  ];

  // Mapa de tipos de planta a carpetas base en assets
  static const Map<String, List<String>> _plantTypeFolders = {
    'pasto': ['Pasto'],
    'solar': ['Cajeto', 'Espino', 'Drago', 'Alcaparro', 'Alcaparro grande'],
    'hidro': ['Aliso', 'Cedrillo', 'Cucharo'],
    'xerofito': ['Alcaparro enano', 'Dividivi'],
    'montana': ['Roble', 'Pino romerón', 'Nogal', 'Duraznillo'],
    'templado': ['Manzano', 'Mangle', 'Sietecueros', 'Cedro'],
  };

  // Intenta cargar imagen - si no existe, retorna path de Pasto
  String _getPlantImagePath(String plantId, String fase) {
    String faseNum;
    switch (fase) {
      case 'semilla':
        faseNum = '1';
        break;
      case 'arbusto':
        faseNum = '2';
        break;
      case 'planta':
        faseNum = '3';
        break;
      case 'ent':
        faseNum = '4';
        break;
      default:
        faseNum = '2';
    }

    // Intentar cargar la imagen de la planta específica
    final tryPath = 'Planta/$plantId/fase${faseNum}_ss.png';
    try {
      images.fromCache(tryPath);
      return tryPath;
    } catch (e) {
      // Si falla, intentar buscar coincidencias en carpetas conocidas
      final lowerId = plantId.toLowerCase();
      
      for (final folders in _plantTypeFolders.values) {
        for (final folder in folders) {
          if (lowerId.contains(folder.toLowerCase()) || folder.toLowerCase().contains(lowerId)) {
            // Probar carpeta base
            final basePath = 'Planta/$folder/fase${faseNum}_ss.png';
            try {
              images.fromCache(basePath);
              return basePath;
            } catch (_) {
              // Probar variaciones numéricas
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

    // Fallback final: Pasto (ya precargado)
    return 'Planta/Pasto/fase${faseNum}_ss.png';
  }

  // Obtiene el nombre de display para mostrar
  String _getPlantDisplayName(String plantId) {
    final lowerId = plantId.toLowerCase();
    
    // Mapear a nombres legibles
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

    // Cargar solo las imágenes básicas que sabemos que existen
    await images.loadAll([
      'Paneles/Fondo_Inv_01.png',
      'Paneles/Panel_DescripciónPlanta_05.png',
      'Inventario/Panel_InvEspacio_01.png',
      'Inventario/Panel_InvEspacio_02.png',
      // Cargar Pasto como fallback obligatorio
      'Planta/Pasto/fase1_ss.png',
      'Planta/Pasto/fase2_ss.png',
      'Planta/Pasto/fase3_ss.png',
      'Planta/Pasto/fase4_ss.png',
      // Botones necesarios
      'Botones/Boton_Cerrar_01.png',
      'Botones/Boton_Categoría_01.png',
      'Botones/Boton_Categoría_02.png',
      'Botones/Boton_Categoría_03.png',
      'Botones/Boton_Estado_02.png',
      'Botones/Boton_Estado_03.png',
      'Botones/Boton_Urgencia_01.png',
      'Botones/Boton_Filtro.png',
      'Botones/Boton_General_01a.png',
      'Iconos/Icono_Semaforo_01.png',
    ]);

    add(SpriteComponent()
      ..sprite = Sprite(images.fromCache('Paneles/Fondo_Inv_01.png'))
      ..size = size);

    add(FilterPanelComponent(gameRef: this));

    final closeBtn = CloseButtonComponent(context);
    closeBtn.position = Vector2(size.x - 82, 10);
    closeBtn.size = Vector2(40, 40);
    closeBtn.priority = 20;
    add(closeBtn);

    _loadPlantSlots();
  }

  void _loadPlantSlots() {
    for (final slot in _plantSlots) {
      slot.removeFromParent();
    }
    _plantSlots.clear();

    _controller = Provider.of<PlantController>(
      context,
      listen: false,
    );

    final plants = _controller?.plants ?? [];
    if (plants.isEmpty) {
      _addDefaultSlots();
      return;
    }

    const double collapsedH = 56.0;
    const double marginTop = 26.0;
    final double availableH = size.y - collapsedH - marginTop;
    final double slotSize = availableH * 0.40;

    final double totalSlotsW = slotSize * 3;
    final double totalGap = size.x - totalSlotsW;
    final double gap = totalGap / 4;

    final double slotY = marginTop + (availableH * 0.30 - slotSize) / 2;
    final double finalSlotY = slotY < marginTop ? marginTop : slotY;

    final displayCount = plants.length.clamp(0, 3);
    for (int i = 0; i < displayCount; i++) {
      final x = gap * (i + 1) + slotSize * i;
      _addPlantSlot(Vector2(x, finalSlotY), slotSize, slotSize, plants[i], i);
    }

    if (kDebugMode) {
      _addDebugPanel();
    }
  }

  void _addDefaultSlots() {
    const double collapsedH = 56.0;
    const double marginTop = 26.0;
    final double availableH = size.y - collapsedH - marginTop;
    final double slotSize = availableH * 0.40;
    final double totalSlotsW = slotSize * 3;
    final double totalGap = size.x - totalSlotsW;
    final double gap = totalGap / 4;
    final double slotY = marginTop + (availableH * 0.30 - slotSize) / 2;
    final double finalSlotY = slotY < marginTop ? marginTop : slotY;

    _addSlot(Vector2(gap, finalSlotY), slotSize, slotSize, true);
    _addSlot(Vector2(gap * 2 + slotSize, finalSlotY), slotSize, slotSize, false);
    _addSlot(Vector2(gap * 3 + slotSize * 2, finalSlotY), slotSize, slotSize, false);
  }

  void _addPlantSlot(Vector2 pos, double slotW, double slotH, dynamic plant, int index) {
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
        final double plantSize = slotW * 0.99;
        slot.add(SpriteComponent()
          ..sprite = Sprite(
            img,
            srcPosition: Vector2(0, 0),
            srcSize: Vector2(img.width / 18, img.height.toDouble()),
          )
          ..size = Vector2(plantSize, plantSize)
          ..anchor = Anchor.center
          ..position = Vector2(slotW / 2, slotH * 0.55));
      } catch (e) {
        debugPrint('[Inventory] Error cargando imagen: $imagePath');
      }

      final double iconH = slotH * 0.16;
      final double iconY = slotH - iconH - slotH * 0.13;
      const double iconGap = 6.0;

      final recursos = plant.recursosAplicados;
      final sol = recursos?.sol ?? 0;
      final agua = recursos?.agua ?? 0;
      final composta = recursos?.composta ?? 0;

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

      final double totalIconW = iconWidths.fold(0.0, (sum, w) => sum + w) + iconGap * (iconPaths.length - 1);
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
        onTap: (int i) => _onPlantSelected(i),
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

  void _addDebugPanel() {
    final debugPanel = _DebugTimePanel(
      controller: _controller!,
      position: Vector2(10, size.y - 150),
      onUpdate: _loadPlantSlots,
    );
    add(debugPanel);
  }

  void setState(VoidCallback fn) {
    fn();
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
      final double plantSize = slotW * 0.99;
      slot.add(SpriteComponent()
        ..sprite = Sprite(
          img,
          srcPosition: Vector2(0, 0),
          srcSize: Vector2(img.width / 18, img.height.toDouble()),
        )
        ..size = Vector2(plantSize, plantSize)
        ..anchor = Anchor.center
        ..position = Vector2(slotW / 2, slotH * 0.16));

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

      final double totalIconW =
          iconWidths.fold(0.0, (sum, w) => sum + w) + iconGap * (iconPaths.length - 1);
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
}

// -------------------------------------------------------
// Panel de filtros
// -------------------------------------------------------
class FilterPanelComponent extends PositionComponent {
  final FlameGame gameRef;
  bool _isOpen = false;
  late _FilterDrawer _drawer;
  late _FilterToggleButton _filterBtn;
  static const double _collapsedH = 56.0;

  FilterPanelComponent({required this.gameRef});

  @override
  Future<void> onLoad() async {
    final double screenW = gameRef.size.x;
    final double screenH = gameRef.size.y;

    size = Vector2(screenW, _collapsedH);
    position = Vector2(0, screenH - _collapsedH);
    priority = 5;

    add(SpriteComponent()
      ..sprite = Sprite(gameRef.images.fromCache('Paneles/Panel_DescripciónPlanta_05.png'))
      ..size = Vector2(screenW, _collapsedH));

    _drawer = _FilterDrawer(gameRef: gameRef)
      ..position = Vector2(0, screenH)
      ..size = Vector2(screenW, 0);
    gameRef.add(_drawer);

    _filterBtn = _FilterToggleButton(
      gameRef: gameRef,
      onTap: _toggleDrawer,
    )
      ..position = Vector2(screenW / 2 - 20, screenH - _collapsedH + 8)
      ..size = Vector2(40, 40)
      ..priority = 8;
    gameRef.add(_filterBtn);
  }

  void _toggleDrawer() {
    _isOpen = !_isOpen;
    _isOpen ? _openDrawer() : _closeDrawer();
  }

  void _openDrawer() {
    final double screenH = gameRef.size.y;
    final double drawerH = screenH * 0.72 - _collapsedH;
    _drawer.position = Vector2(0, screenH - _collapsedH - drawerH);
    _drawer.size = Vector2(gameRef.size.x, drawerH);
    _drawer.drawerH = drawerH;
    _drawer.isVisible = true;
    _drawer.rebuild();

    _filterBtn.position = Vector2(
      gameRef.size.x / 2 - 20,
      screenH - _collapsedH - drawerH + 8,
    );
  }

  void _closeDrawer() {
    final double screenH = gameRef.size.y;
    _drawer.position = Vector2(0, screenH);
    _drawer.size = Vector2(gameRef.size.x, 0);
    _drawer.isVisible = false;

    _filterBtn.position = Vector2(
      gameRef.size.x / 2 - 20,
      screenH - _collapsedH + 8,
    );
  }
}

class _FilterToggleButton extends SpriteComponent with TapCallbacks {
  final FlameGame gameRef;
  final VoidCallback onTap;
  _FilterToggleButton({required this.gameRef, required this.onTap});

  @override
  Future<void> onLoad() async {
    sprite = Sprite(gameRef.images.fromCache('Botones/Boton_Filtro.png'));
  }

  @override
  void onTapDown(TapDownEvent event) {
    onTap();
    event.continuePropagation = false;
  }
}

// -------------------------------------------------------
// Drawer
// -------------------------------------------------------
class _FilterDrawer extends PositionComponent with TapCallbacks {
  final FlameGame gameRef;
  bool isVisible = false;
  double drawerH = 0;

  _FilterDrawer({required this.gameRef});

  @override
  Future<void> onLoad() async {
    priority = 6;
  }

  void rebuild() {
    removeAll(children.toList());
    _buildContent();
  }

  void _buildContent() {
    final double screenW = gameRef.size.x;
    final double h = drawerH;
    const double collapsedH = 56.0;

    add(SpriteComponent()
      ..sprite = Sprite(gameRef.images.fromCache('Paneles/Panel_DescripciónPlanta_05.png'))
      ..size = Vector2(screenW, h + collapsedH)
      ..position = Vector2.zero());

    // Margen lateral mayor para centrar el contenido
    final double marginSide = screenW * 0.22;

    // Padding superior aumentado para separar del botón filtro
    const double topReserved = 62.0; 
    const double paddingV = 6.5;
    const double labelFontSize = 7.2;
    const double labelGap = 2.2;
    const double titleFontSize = 9.0;
    const double titleGap = 6.5;

    final double usableH = h - topReserved - paddingV;
    final double sectionH = usableH / 3;
    final double iconH = sectionH * 0.55;

    double currentY = topReserved;

    // ── CATEGORÍA ──
    add(_sectionTitle('CATEGORÍA', screenW / 2, currentY));
    currentY += titleFontSize + titleGap;
    _addIconRow([
      {'path': 'Botones/Boton_Categoría_01.png', 'label': 'Solar'},
      {'path': 'Botones/Boton_Categoría_02.png', 'label': 'XeroAto'},
      {'path': 'Botones/Boton_Categoría_03.png', 'label': 'Templado'},
      {'path': 'Botones/Boton_Categoría_04.png', 'label': 'Montaña'},
      {'path': 'Botones/Boton_Categoría_05.png', 'label': 'Hidro'},
    ], screenW, marginSide, currentY, iconH, labelFontSize, labelGap);
    currentY += sectionH;

    // ── ETAPA ──
    add(_sectionTitle('ETAPA', screenW / 2, currentY));
    currentY += titleFontSize + titleGap;
    _addIconRow([
      {'path': 'Botones/Boton_Estado_01.png', 'label': 'Semilla'},
      {'path': 'Botones/Boton_Estado_02.png', 'label': 'Arbusto\nPequeño'},
      {'path': 'Botones/Boton_Estado_03.png', 'label': 'Arbusto\nGrande'},
      {'path': 'Botones/Boton_Estado_04.png', 'label': 'ENT'},
    ], screenW, marginSide, currentY, iconH, labelFontSize, labelGap);
    currentY += sectionH;

    // ── URGENCIA ──
    add(_sectionTitle('URGENCIA', screenW / 2, currentY));
    currentY += titleFontSize + titleGap;
    _addIconRow([
      {'path': 'Botones/Boton_Urgencia_03.png', 'label': 'Alta'},
      {'path': 'Botones/Boton_Urgencia_02.png', 'label': 'Media'},
      {'path': 'Botones/Boton_Urgencia_01.png', 'label': 'Baja'},
    ], screenW, marginSide, currentY, iconH, labelFontSize, labelGap);
  }

  TextComponent _sectionTitle(String text, double cx, double y) {
    return TextComponent(
      text: text,
      anchor: Anchor.topCenter,
      position: Vector2(cx, y),
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 9,
          fontFamily: 'Press Start 2P',
          color: Color(0xFF3E2A1F),
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _addIconRow(
    List<Map<String, String>> items,
    double rowW,
    double marginSide,
    double startY,
    double iconH,
    double labelFontSize,
    double labelGap,
  ) {
    final int count = items.length;
    final double usableW = rowW - marginSide * 2;
    final double cellW = usableW / count;

    for (int i = 0; i < count; i++) {
      final path = items[i]['path']!;
      final label = items[i]['label']!;
      final img = gameRef.images.fromCache(path);
      final double ratio = img.width / img.height;
      final double iconW = iconH * ratio;
      final double cellX = marginSide + cellW * i;
      final double iconX = cellX + (cellW - iconW) / 2;

      add(SpriteComponent()
        ..sprite = Sprite(gameRef.images.fromCache(path))
        ..size = Vector2(iconW, iconH)
        ..position = Vector2(iconX, startY));

      add(TextComponent(
        text: label,
        anchor: Anchor.topCenter,
        position: Vector2(cellX + cellW / 2, startY + iconH + labelGap),
        textRenderer: TextPaint(
          style: TextStyle(
            fontSize: labelFontSize,
            fontFamily: 'Press Start 2P',
            color: const Color(0xFF3E2A1F),
          ),
        ),
      ));
    }
  }

  @override
  void onTapDown(TapDownEvent event) {
    event.continuePropagation = false;
  }

  @override
  void render(Canvas canvas) {
    if (!isVisible) return;
    super.render(canvas);
  }

  @override
  void renderTree(Canvas canvas) {
    if (!isVisible) return;
    super.renderTree(canvas);
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
    if (plantIndex != null && onTap != null) {
      onTap!(plantIndex!);
      event.continuePropagation = false;
      return;
    }
    if (_expanded) return;
    _expanded = true;
    gameRef.add(_ExpandedOverlay(
      gameRef: gameRef,
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

  _ExpandedOverlay({required this.gameRef, required this.onClose});

  @override
  Future<void> onLoad() async {
    priority = 10;
    size = gameRef.size;

    add(RectangleComponent(
      size: gameRef.size,
      paint: Paint()..color = const Color(0x33000000),
    ));

    const double collapsedH = 52.0;
    const double marginTop = 15.0;
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

    add(TextComponent(
      text: 'PASTO',
      anchor: Anchor.topCenter,
      position: Vector2(gameRef.size.x / 2, panelY + panelSize * 0.14),
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
    final double plantSize = panelSize * 0.99; 
    add(SpriteComponent()
      ..sprite = Sprite(
        img,
        srcPosition: Vector2(0, 0),
        srcSize: Vector2(img.width / 3, img.height.toDouble()),
      )
      ..size = Vector2(plantSize, plantSize)
      ..anchor = Anchor.center
      ..position = Vector2(gameRef.size.x / 2, panelY + panelSize * 0.15));

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

    add(_ImageButton(
      label: 'Volver',
      position: Vector2(panelX, btnY),
      btnSize: Vector2(btnW, btnH),
      gameRef: gameRef,
      onTap: () {
        gameRef.remove(this);
        onClose();
      },
    ));

    add(_ImageButton(
      label: 'Seleccionar',
      position: Vector2(panelX + panelSize - btnW, btnY),
      btnSize: Vector2(btnW, btnH),
      gameRef: gameRef,
      onTap: () {
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

// -------------------------------------------------------
// Botón con imagen
// -------------------------------------------------------
class _ImageButton extends PositionComponent with TapCallbacks {
  final String label;
  final VoidCallback onTap;
  final Vector2 btnSize;
  final FlameGame gameRef;

  _ImageButton({
    required this.label,
    required Vector2 position,
    required this.btnSize,
    required this.gameRef,
    required this.onTap,
  }) {
    this.position = position;
    size = btnSize;
  }

  @override
  Future<void> onLoad() async {
    add(SpriteComponent()
      ..sprite = Sprite(gameRef.images.fromCache('Botones/Boton_General_01a.png'))
      ..size = btnSize);

    add(TextComponent(
      text: label,
      anchor: Anchor.center,
      position: btnSize / 2,
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 9,
          fontFamily: 'Press Start 2P',
          color: Color(0xFFFFFFFF),
          fontWeight: FontWeight.bold,
        ),
      ),
    ));
  }

  @override
  void onTapDown(TapDownEvent event) {
    onTap();
    event.continuePropagation = false;
  }
}

// -------------------------------------------------------
// Botón cerrar
// -------------------------------------------------------
class CloseButtonComponent extends SpriteComponent with TapCallbacks {
  final BuildContext context;
  CloseButtonComponent(this.context);

  @override
  Future<void> onLoad() async {
    sprite = await Sprite.load('Botones/Boton_Cerrar_01.png');
  }

  @override
  void onTapDown(TapDownEvent event) {
    GoRouter.of(context).go('/plant_game');
    event.continuePropagation = false;
  }
}

// -------------------------------------------------------
// Panel Debug de Tiempo (solo en modo debug)
// -------------------------------------------------------
class _DebugTimePanel extends PositionComponent with TapCallbacks {
  final PlantController controller;
  final VoidCallback onUpdate;

  _DebugTimePanel({
    required this.controller,
    required Vector2 position,
    required this.onUpdate,
  }) {
    this.position = position;
    size = Vector2(200, 130);
  }

  @override
  Future<void> onLoad() async {
    add(SpriteComponent()
      ..sprite = await Sprite.load('Paneles/Panel_DescripciónPlanta_05.png')
      ..size = size);

    final title = TextComponent(
      text: 'DEBUG TIME',
      anchor: Anchor.topCenter,
      position: Vector2(100, 5),
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 8,
          fontFamily: 'Press Start 2P',
          color: Colors.red,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
    add(title);

    final infoText = TextComponent(
      text: _getDebugInfo(),
      anchor: Anchor.topLeft,
      position: Vector2(10, 30),
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 7,
          fontFamily: 'Press Start 2P',
          color: Colors.white,
        ),
      ),
    );
    add(infoText);

    final btnPlus10 = _DebugButton(
      label: '+10m',
      position: Vector2(10, 85),
      onTap: () => _advanceTime(10),
    );
    add(btnPlus10);

    final btnPlus60 = _DebugButton(
      label: '+1h',
      position: Vector2(70, 85),
      onTap: () => _advanceTime(60),
    );
    add(btnPlus60);

    final btnApply = _DebugButton(
      label: 'APPLY',
      position: Vector2(130, 85),
      onTap: _applyDecay,
    );
    add(btnApply);
  }

  String _getDebugInfo() {
    return controller.getDebugPlantsInfo();
  }

  void _advanceTime(int minutes) async {
    await controller.debugAdvanceTime(minutes);
    onUpdate();
  }

  void _applyDecay() async {
    await controller.applyPassiveDecay();
    await controller.saveTree();
    debugPrint('[Debug] Decay aplicado');
    onUpdate();
  }
}

class _DebugButton extends PositionComponent with TapCallbacks {
  final String label;
  final VoidCallback onTap;

  _DebugButton({
    required this.label,
    required Vector2 position,
    required this.onTap,
  }) {
    this.position = position;
    size = Vector2(50, 25);
  }

  @override
  Future<void> onLoad() async {
    add(SpriteComponent()
      ..sprite = await Sprite.load('Botones/Boton_General_01a.png')
      ..size = size);

    add(TextComponent(
      text: label,
      anchor: Anchor.center,
      position: Vector2(size.x / 2, size.y / 2),
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 8,
          fontFamily: 'Press Start 2P',
          color: Colors.white,
        ),
      ),
    ));
  }

  @override
  void onTapDown(TapDownEvent event) {
    onTap();
    event.continuePropagation = false;
  }
}