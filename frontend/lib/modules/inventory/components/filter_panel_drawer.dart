// -------------------------------------------------------
// Drawer
// -------------------------------------------------------
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

class FilterDrawer extends PositionComponent with TapCallbacks {
  final FlameGame gameRef;
  bool isVisible = false;
  double drawerH = 0;

  FilterDrawer({required this.gameRef});

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