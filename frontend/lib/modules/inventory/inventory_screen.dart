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
      'Botones/Boton_Estado_02.png',
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
        position: Vector2(slotW / 2, slotH * 0.07),
        textRenderer: TextPaint(
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF3E2A1F),
            fontWeight: FontWeight.bold,
          ),
        ),
      ));

      // Una sola planta recortando el primer frame del spritesheet
      final img = images.fromCache('Planta/pasto_fase_02.png');
      final double plantSize = slotW * 0.50;
      slot.add(SpriteComponent()
        ..sprite = Sprite(
          img,
          srcPosition: Vector2(0, 0),
          srcSize: Vector2(img.width / 3, img.height.toDouble()),
        )
        ..size = Vector2(plantSize, plantSize)
        ..anchor = Anchor.center
        ..position = Vector2(slotW / 2, slotH * 0.45));

      final double iconSize = slotW * 0.17;
      final double iconY = slotH - iconSize - slotH * 0.07;
      final double gap = 6.0;
      final double totalW = iconSize * 3 + gap * 2;
      double ix = (slotW - totalW) / 2;

      for (final path in [
        'Botones/Boton_Categoría_01.png',
        'Botones/Boton_Estado_02.png',
        'Iconos/Icono_Semaforo_01.png',
      ]) {
        slot.add(SpriteComponent()
          ..sprite = Sprite(images.fromCache(path))
          ..size = Vector2(iconSize, iconSize)
          ..position = Vector2(ix, iconY));
        ix += iconSize + gap;
      }

      slot.add(_TappableSlot(
        slotSize: Vector2(slotW, slotH),
        gameRef: this,
      )..size = Vector2(slotW, slotH));
    }

    add(slot);
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
      position: Vector2(gameRef.size.x / 2, panelY + panelH * 0.07),
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 20,
          fontFamily: 'Press Start 2P',
          color: Color(0xFF3E2A1F),
          fontWeight: FontWeight.bold,
          letterSpacing: 2,
        ),
      ),
    ));

    // Una sola planta recortando el primer frame del spritesheet
    final img = gameRef.images.fromCache('Planta/pasto_fase_02.png');
    final double plantSize = panelW * 0.50;
    add(SpriteComponent()
      ..sprite = Sprite(
        img,
        srcPosition: Vector2(0, 0),
        srcSize: Vector2(img.width / 3, img.height.toDouble()),
      )
      ..size = Vector2(plantSize, plantSize)
      ..anchor = Anchor.center
      ..position = Vector2(gameRef.size.x / 2, panelY + panelH * 0.48));

    final double iconSize = panelW * 0.14;
    final double iconY = panelY + panelH - iconSize - panelH * 0.08;
    final double gap = 8.0;
    final double totalW = iconSize * 3 + gap * 2;
    double ix = (gameRef.size.x - totalW) / 2;

    for (final path in [
      'Botones/Boton_Categoría_01.png',
      'Botones/Boton_Estado_02.png',
      'Iconos/Icono_Semaforo_01.png',
    ]) {
      add(SpriteComponent()
        ..sprite = Sprite(gameRef.images.fromCache(path))
        ..size = Vector2(iconSize, iconSize)
        ..position = Vector2(ix, iconY));
      ix += iconSize + gap;
    }

    final double btnY = panelY + panelH + 14;
    final double btnW = panelW * 0.42;
    const double btnH = 42.0;

    add(_SimpleButton(
      label: 'Volver',
      position: Vector2(panelX, btnY),
      btnSize: Vector2(btnW, btnH),
      onTap: () {
        gameRef.remove(this);
        onClose();
      },
    ));

    add(_SimpleButton(
      label: 'Seleccionar',
      position: Vector2(panelX + panelW - btnW, btnY),
      btnSize: Vector2(btnW, btnH),
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

class _SimpleButton extends PositionComponent with TapCallbacks {
  final String label;
  final VoidCallback onTap;
  final Vector2 btnSize;

  _SimpleButton({
    required this.label,
    required Vector2 position,
    required this.btnSize,
    required this.onTap,
  }) {
    this.position = position;
    size = btnSize;
  }

  @override
  Future<void> onLoad() async {
    add(RectangleComponent(
      size: btnSize,
      paint: Paint()..color = const Color(0xFF4CAF50),
    ));
    add(RectangleComponent(
      size: btnSize,
      paint: Paint()
        ..color = const Color(0xFF2E7D32)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    ));
    add(TextComponent(
      text: label,
      anchor: Anchor.center,
      position: btnSize / 2,
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 15,
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