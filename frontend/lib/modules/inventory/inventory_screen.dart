import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import 'package:frontend/modules/inventory/components/button_close.dart';
import 'package:frontend/modules/inventory/components/filter_panel.dart';
import 'package:frontend/modules/inventory/components/image_button.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/core/audio.dart';

class InventoryScreen extends FlameGame {
  final BuildContext context;
  InventoryScreen(this.context);

  @override
  Future<void> onLoad() async {
    await images.loadAll([
      'Paneles/Fondo_Inv_01.png',
      'Inventario/Panel_InvEspacio_01.png',
      'Inventario/Panel_InvEspacio_02.png',
      'Planta/Pasto/fase2_ss.png',
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

    add(FilterPanelComponent(gameRef: this));

    final closeBtn = CloseButtonComponent(context);
    closeBtn.anchor = Anchor.topRight;
    closeBtn.position = Vector2(size.x - 82, 0);
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
      final double plantSize = slotW * 0.5;
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
// Slot tappable
// -------------------------------------------------------
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
    final double plantSize = panelSize * 0.8; 
    add(SpriteComponent()
      ..sprite = Sprite(
        img,
        srcPosition: Vector2(0, 0),
        srcSize: Vector2(img.width / 18, img.height.toDouble()),
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

    add(ImageButton(
      label: 'Volver',
      position: Vector2(panelX, btnY),
      btnSize: Vector2(btnW, btnH),
      gameRef: gameRef,
      onTap: () {
        gameRef.remove(this);
        onClose();
      },
    ));

    add(ImageButton(
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
