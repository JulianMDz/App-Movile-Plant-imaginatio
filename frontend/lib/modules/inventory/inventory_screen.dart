import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class InventoryScreen extends FlameGame {
  final BuildContext context;
  InventoryScreen(this.context);

  @override
  Future<void> onLoad() async {
    await images.loadAll([
      'Paneles/Fondo_Inv_01.png',
      'Inventario/Panel_InvEspacio_01.png',
      'Inventario/Panel_InvEspacio_02.png',
      'Planta/pasto_fase_02.png',
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
      'Botones/Boton_General_01a.png',
      'Botones/Boton_Filtro.png',
      'Paneles/Panel_DescripciónPlanta_05.png',
      'Iconos/Icono_Semaforo_01.png',
    ]);

    add(SpriteComponent()
      ..sprite = Sprite(images.fromCache('Paneles/Fondo_Inv_01.png'))
      ..size = size);

    add(CloseButtonComponent(context)..position = Vector2(size.x - 20, 20));

    const double padding = 12.0;
    const double topOffset = 80.0;

    final double slotW = (size.x - padding * 3) / 2;
    final double slotH = slotW;

    _addSlot(Vector2(padding, topOffset), slotW, slotH, true);
    _addSlot(Vector2(padding * 2 + slotW, topOffset), slotW, slotH, false);
    _addSlot(Vector2(padding, topOffset + slotH + padding), slotW, slotH, false);
    _addSlot(Vector2(padding * 2 + slotW, topOffset + slotH + padding), slotW, slotH, false);

    // Panel de filtros en la parte inferior
    add(FilterPanelComponent(gameRef: this));
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
        text: 'Pasto',
        anchor: Anchor.topCenter,
        position: Vector2(slotW / 2, slotH * 0.13),
        textRenderer: TextPaint(
          style: const TextStyle(
            fontSize: 10,
            fontFamily: 'Press Start 2P',
            color: Color(0xFF3E2A1F),
            fontWeight: FontWeight.bold,
          ),
        ),
      ));

      final img = images.fromCache('Planta/pasto_fase_02.png');
      final double plantSize = slotW * 0.42;
      slot.add(SpriteComponent()
        ..sprite = Sprite(
          img,
          srcPosition: Vector2(0, 0),
          srcSize: Vector2(img.width / 3, img.height.toDouble()),
        )
        ..size = Vector2(plantSize, plantSize)
        ..anchor = Anchor.center
        ..position = Vector2(slotW / 2, slotH * 0.42));

      final double iconH = slotH * 0.16;
      final double iconY = slotH - iconH - slotH * 0.07;
      const double gap = 6.0;

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

      final double totalW = iconWidths.fold(0.0, (sum, w) => sum + w) + gap * (iconPaths.length - 1);
      double ix = (slotW - totalW) / 2;

      for (int i = 0; i < iconPaths.length; i++) {
        final iconImg = images.fromCache(iconPaths[i]);
        final double ratio = iconImg.width / iconImg.height;
        final double iconW = iconH * ratio;

        slot.add(SpriteComponent()
          ..sprite = Sprite(images.fromCache(iconPaths[i]))
          ..size = Vector2(iconW, iconH)
          ..position = Vector2(ix, iconY));
        ix += iconW + gap;
      }

      slot.add(_TappableSlot(
        slotSize: Vector2(slotW, slotH),
        gameRef: this,
      )..size = Vector2(slotW, slotH));
    }

    add(slot);
  }
}

class FilterPanelComponent extends PositionComponent {
  final FlameGame gameRef;
  bool _isOpen = false;
  late _FilterDrawer _drawer;
  late SpriteComponent _bgPanel;
  late _FilterToggleButton _btn;

  // Alto del fondo siempre visible (solo el botón)
  static const double _collapsedH = 56.0;

  FilterPanelComponent({required this.gameRef});

  @override
  Future<void> onLoad() async {
    final double screenW = gameRef.size.x;
    final double screenH = gameRef.size.y;

    size = Vector2(screenW, _collapsedH);
    position = Vector2(0, screenH - _collapsedH);
    priority = 5;

    _bgPanel = SpriteComponent()
      ..sprite = Sprite(gameRef.images.fromCache('Paneles/Panel_DescripciónPlanta_05.png'))
      ..size = Vector2(screenW, _collapsedH)
      ..position = Vector2.zero();
    add(_bgPanel);

    // Botón filtro centrado
    _btn = _FilterToggleButton(
      gameRef: gameRef,
      onTap: _toggleDrawer,
    )
      ..position = Vector2(screenW / 2 - 24, 8)
      ..size = Vector2(48, 40);
    add(_btn);

    // Drawer (empieza oculto)
    _drawer = _FilterDrawer(gameRef: gameRef)
      ..position = Vector2(0, screenH) // fuera de pantalla
      ..size = Vector2(screenW, 0);
    gameRef.add(_drawer);
  }

  void _toggleDrawer() {
    _isOpen = !_isOpen;
    if (_isOpen) {
      _openDrawer();
    } else {
      _closeDrawer();
    }
  }

  void _openDrawer() {
    final double screenH = gameRef.size.y;
    const double drawerH = 340.0;
    _drawer.position = Vector2(0, screenH - _collapsedH - drawerH);
    _drawer.size = Vector2(gameRef.size.x, drawerH);
    _drawer.isVisible = true;
  }

  void _closeDrawer() {
    final double screenH = gameRef.size.y;
    _drawer.position = Vector2(0, screenH);
    _drawer.size = Vector2(gameRef.size.x, 0);
    _drawer.isVisible = false;
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

class _FilterDrawer extends PositionComponent with TapCallbacks {
  final FlameGame gameRef;
  bool isVisible = false;

  _FilterDrawer({required this.gameRef});

  bool _loaded = false;

  @override
  Future<void> onLoad() async {
    priority = 6;
    await _buildContent();
    _loaded = true;
  }

  Future<void> _buildContent() async {
    final double w = gameRef.size.x;
    const double drawerH = 340.0;

    // Fondo del drawer
    add(SpriteComponent()
      ..sprite = Sprite(gameRef.images.fromCache('Paneles/Panel_DescripciónPlanta_05.png'))
      ..size = Vector2(w, drawerH)
      ..position = Vector2.zero());

    const double paddingH = 16.0;
    const double sectionGap = 14.0;
    const double titleFontSize = 9.0;
    const double iconH = 38.0;
    const double labelFontSize = 7.0;
    const double labelGap = 4.0;

    double currentY = 16.0;

    // ── CATEGORÍA ──
    add(_sectionTitle('CATEGORÍA', w / 2, currentY));
    currentY += 20.0;

    final categorias = [
      {'path': 'Botones/Boton_Categoría_01.png', 'label': 'Solar'},
      {'path': 'Botones/Boton_Categoría_02.png', 'label': 'XeroAto'},
      {'path': 'Botones/Boton_Categoría_03.png', 'label': 'Templado'},
      {'path': 'Botones/Boton_Categoría_04.png', 'label': 'Montaña'},
      {'path': 'Botones/Boton_Categoría_05.png', 'label': 'Hidro'},
    ];
    currentY = _addIconRow(categorias, w, paddingH, currentY, iconH, labelFontSize, labelGap);
    currentY += sectionGap;

    // ── ETAPA ──
    add(_sectionTitle('ETAPA', w / 2, currentY));
    currentY += 20.0;

    final etapas = [
      {'path': 'Botones/Boton_Estado_01.png', 'label': 'Semilla'},
      {'path': 'Botones/Boton_Estado_02.png', 'label': 'Arbusto\nPequeño'},
      {'path': 'Botones/Boton_Estado_03.png', 'label': 'Arbusto\nGrande'},
      {'path': 'Botones/Boton_Estado_04.png', 'label': 'ENT'},
    ];
    currentY = _addIconRow(etapas, w, paddingH, currentY, iconH, labelFontSize, labelGap);
    currentY += sectionGap;

    // ── URGENCIA ──
    add(_sectionTitle('URGENCIA', w / 2, currentY));
    currentY += 20.0;

    final urgencias = [
      {'path': 'Botones/Boton_Urgencia_03.png', 'label': 'Alta'},
      {'path': 'Botones/Boton_Urgencia_02.png', 'label': 'Media'},
      {'path': 'Botones/Boton_Urgencia_01.png', 'label': 'Baja'},
    ];
    _addIconRow(urgencias, w, paddingH, currentY, iconH, labelFontSize, labelGap);
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
          letterSpacing: 1,
        ),
      ),
    );
  }

  // Agrega una fila de iconos centrados con etiqueta debajo
  // Retorna el nuevo Y después de los iconos + labels
  double _addIconRow(
    List<Map<String, String>> items,
    double rowW,
    double paddingH,
    double startY,
    double iconH,
    double labelFontSize,
    double labelGap,
  ) {
    final int count = items.length;
    final double usableW = rowW - paddingH * 2;
    final double cellW = usableW / count;

    for (int i = 0; i < count; i++) {
      final path = items[i]['path']!;
      final label = items[i]['label']!;
      final img = gameRef.images.fromCache(path);
      final double ratio = img.width / img.height;
      final double iconW = iconH * ratio;
      final double cellX = paddingH + cellW * i;
      final double iconX = cellX + (cellW - iconW) / 2;

      // Icono
      add(SpriteComponent()
        ..sprite = Sprite(gameRef.images.fromCache(path))
        ..size = Vector2(iconW, iconH)
        ..position = Vector2(iconX, startY));

      // Etiqueta debajo del icono
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

    // Altura de label (aprox 2 líneas max)
    const double labelH = 20.0;
    return startY + iconH + labelGap + labelH;
  }

  @override
  void onTapDown(TapDownEvent event) {
    // absorber taps dentro del drawer
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

class _TappableSlot extends PositionComponent with TapCallbacks {
  final Vector2 slotSize;
  final FlameGame gameRef;
  bool _expanded = false;

  _TappableSlot({required this.slotSize, required this.gameRef});

  @override
  void onTapDown(TapDownEvent event) {
    if (_expanded) return;
    _expanded = true;
    gameRef.add(_ExpandedOverlay(
      gameRef: gameRef,
      onClose: () => _expanded = false,
    )..size = gameRef.size);
    event.continuePropagation = false;
  }
}

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
      paint: Paint()..color = const Color(0x88000000),
    ));

    final double panelW = gameRef.size.x * 0.70;
    final double panelH = panelW;
    final double panelX = (gameRef.size.x - panelW) / 2;
    final double panelY = (gameRef.size.y - panelH) / 2 - 40;

    add(SpriteComponent()
      ..sprite = Sprite(gameRef.images.fromCache('Inventario/Panel_InvEspacio_01.png'))
      ..size = Vector2(panelW, panelH)
      ..position = Vector2(panelX, panelY));

    add(TextComponent(
      text: 'PASTO',
      anchor: Anchor.topCenter,
      position: Vector2(gameRef.size.x / 2, panelY + panelH * 0.13),
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 16,
          fontFamily: 'Press Start 2P',
          color: Color(0xFF3E2A1F),
          fontWeight: FontWeight.bold,
          letterSpacing: 2,
        ),
      ),
    ));

    final img = gameRef.images.fromCache('Planta/pasto_fase_02.png');
    final double plantSize = panelW * 0.42;
    add(SpriteComponent()
      ..sprite = Sprite(
        img,
        srcPosition: Vector2(0, 0),
        srcSize: Vector2(img.width / 3, img.height.toDouble()),
      )
      ..size = Vector2(plantSize, plantSize)
      ..anchor = Anchor.center
      ..position = Vector2(gameRef.size.x / 2, panelY + panelH * 0.48));

    final double iconH = panelH * 0.15;
    final double iconY = panelY + panelH - iconH - panelH * 0.08;
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

    final double totalW = iconWidths.fold(0.0, (sum, w) => sum + w) + gap * (iconPaths.length - 1);
    double ix = (gameRef.size.x - totalW) / 2;

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

    final double btnY = panelY + panelH + 14;
    final double btnW = panelW * 0.44;
    const double btnH = 48.0;

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
      position: Vector2(panelX + panelW - btnW, btnY),
      btnSize: Vector2(btnW, btnH),
      gameRef: gameRef,
      onTap: () {
        gameRef.remove(this);
        onClose();
      },
    ));
  }

  @override
  void onTapDown(TapDownEvent event) {
    event.continuePropagation = false;
  }
}

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
          fontSize: 10,
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

class CloseButtonComponent extends SpriteComponent with TapCallbacks {
  final BuildContext context;
  CloseButtonComponent(this.context);

  @override
  Future<void> onLoad() async {
    sprite = await Sprite.load('Botones/Boton_Cerrar_01.png');
    size = Vector2(60, 60);
    anchor = Anchor.topRight;
  }

  @override
  void onTapDown(TapDownEvent event) {
    GoRouter.of(context).go('/plant_game');
  }
}