// -------------------------------------------------------
// Drawer
// -------------------------------------------------------

import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

// -------------------------------------------------------
// BOTON TOCABLE
// -------------------------------------------------------

class _FilterButton extends PositionComponent with TapCallbacks {

  final VoidCallback onPressed;
  final bool selected;

  _FilterButton({
    required Vector2 position,
    required Vector2 size,
    required this.onPressed,
    this.selected = false,
  }) {
    this.position = position;
    this.size = size;
  }

  @override
  void onTapDown(TapDownEvent event) {
    onPressed();
    event.continuePropagation = false;
  }

  @override
  void render(Canvas canvas) {

    // Primero renderiza el botón
    super.render(canvas);

    // Luego dibuja la sombra encima
    if (selected) {
      final paint = Paint()
        ..color = const Color(0x88000000);

      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.x, size.y),
        paint,
      );
    }
  }
}

// -------------------------------------------------------
// DRAWER
// -------------------------------------------------------

class FilterDrawer extends PositionComponent with TapCallbacks {

  final FlameGame gameRef;

  final Function(String?)? onCategorySelected;
  final Function(String?)? onStageSelected;
  final Function(String?)? onUrgencySelected;

  String? _selectedCategory;
  String? _selectedStage;
  String? _selectedUrgency;

  bool isVisible = false;
  double drawerH = 0;

  static const double _marginSide = 58.0;

  FilterDrawer({
    required this.gameRef,
    this.onCategorySelected,
    this.onStageSelected,
    this.onUrgencySelected,
  });

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

    // Fondo
    add(
      SpriteComponent()
        ..sprite = Sprite(
          gameRef.images.fromCache(
            'Paneles/Panel_DescripciónPlanta_05.png',
          ),
        )
        ..size = Vector2(
          screenW - _marginSide * 2,
          h + collapsedH,
        )
        ..position = Vector2(_marginSide, 0),
    );

    final double marginSide = screenW * 0.22;

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

    // -------------------------------------------------------
    // CATEGORY
    // -------------------------------------------------------

    add(_sectionTitle('CATEGORÍA', screenW / 2, currentY));

    currentY += titleFontSize + titleGap;

    _addIconRow(
      [
        {
          'path': 'Botones/Boton_Categoría_01.png',
          'label': 'Solar',
          'value': 'solar',
        },
        {
          'path': 'Botones/Boton_Categoría_02.png',
          'label': 'XeroAto',
          'value': 'xerofito',
        },
        {
          'path': 'Botones/Boton_Categoría_03.png',
          'label': 'Templado',
          'value': 'templado',
        },
        {
          'path': 'Botones/Boton_Categoría_04.png',
          'label': 'Montaña',
          'value': 'montana',
        },
        {
          'path': 'Botones/Boton_Categoría_05.png',
          'label': 'Hidro',
          'value': 'hidro',
        },
      ],
      'category',
      screenW,
      marginSide,
      currentY,
      iconH,
      labelFontSize,
      labelGap,
    );

    currentY += sectionH;

    // -------------------------------------------------------
    // STAGE
    // -------------------------------------------------------

    add(_sectionTitle('ETAPA', screenW / 2, currentY));

    currentY += titleFontSize + titleGap;

    _addIconRow(
      [
        {
          'path': 'Botones/Boton_Estado_01.png',
          'label': 'Semilla',
          'value': 'semilla',
        },
        {
          'path': 'Botones/Boton_Estado_02.png',
          'label': 'Arbusto\nPequeño',
          'value': 'arbusto',
        },
        {
          'path': 'Botones/Boton_Estado_03.png',
          'label': 'Arbusto\nGrande',
          'value': 'planta',
        },
        {
          'path': 'Botones/Boton_Estado_04.png',
          'label': 'ENT',
          'value': 'ent',
        },
      ],
      'stage',
      screenW,
      marginSide,
      currentY,
      iconH,
      labelFontSize,
      labelGap,
    );

    currentY += sectionH;

    // -------------------------------------------------------
    // URGENCY
    // -------------------------------------------------------

    add(_sectionTitle('URGENCIA', screenW / 2, currentY));

    currentY += titleFontSize + titleGap;

    _addIconRow(
      [
        {
          'path': 'Botones/Boton_Urgencia_03.png',
          'label': 'Alta',
          'value': 'critical',
        },
        {
          'path': 'Botones/Boton_Urgencia_02.png',
          'label': 'Media',
          'value': 'warning',
        },
        {
          'path': 'Botones/Boton_Urgencia_01.png',
          'label': 'Baja',
          'value': 'normal',
        },
      ],
      'urgency',
      screenW,
      marginSide,
      currentY,
      iconH,
      labelFontSize,
      labelGap,
    );
  }

  // -------------------------------------------------------
  // SECTION TITLE
  // -------------------------------------------------------

  TextComponent _sectionTitle(
    String text,
    double cx,
    double y,
  ) {
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

  // -------------------------------------------------------
  // ICON ROW
  // -------------------------------------------------------

  void _addIconRow(
    List<Map<String, String>> items,
    String filterType,
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
      final value = items[i]['value']!;

      final img = gameRef.images.fromCache(path);

      final double ratio = img.width / img.height;
      final double iconW = iconH * ratio;

      final double cellX = marginSide + cellW * i;
      final double iconX = cellX + (cellW - iconW) / 2;

      final iconPos = Vector2(iconX, startY);

      // ICONO

      add(
        SpriteComponent()
          ..sprite = Sprite(gameRef.images.fromCache(path))
          ..size = Vector2(iconW, iconH)
          ..position = iconPos,
      );

      final bool selected;
      switch (filterType) {
        case 'category':
          selected = _selectedCategory == value;
          break;
        case 'stage':
          selected = _selectedStage == value;
          break;
        case 'urgency':
          selected = _selectedUrgency == value;
          break;
        default:
          selected = false;
      }

      // BOTON TOCABLE

      add(
        _FilterButton(
          position: iconPos,
          size: Vector2(iconW, iconH),
          selected: selected,
          onPressed: () {
            switch (filterType) {
              case 'category':
                _selectedCategory = _selectedCategory == value ? null : value;
                onCategorySelected?.call(_selectedCategory);
                break;
              case 'stage':
                _selectedStage = _selectedStage == value ? null : value;
                onStageSelected?.call(_selectedStage);
                break;
              case 'urgency':
                _selectedUrgency = _selectedUrgency == value ? null : value;
                onUrgencySelected?.call(_selectedUrgency);
                break;
            }
            rebuild();
          },
        ),
      );

      // TEXTO

      add(
        TextComponent(
          text: label,
          anchor: Anchor.topCenter,
          position: Vector2(
            cellX + cellW / 2,
            startY + iconH + labelGap,
          ),
          textRenderer: TextPaint(
            style: TextStyle(
              fontSize: labelFontSize,
              fontFamily: 'Press Start 2P',
              color: const Color(0xFF3E2A1F),
            ),
          ),
        ),
      );
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