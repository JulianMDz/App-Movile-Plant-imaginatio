// -------------------------------------------------------
// Panel de filtros
// -------------------------------------------------------
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:frontend/core/audio.dart';
import 'package:frontend/modules/inventory/components/filter_panel_drawer.dart';

// -------------------------------------------------------
// Panel de filtros
// -------------------------------------------------------
class FilterPanelComponent extends PositionComponent {
  final FlameGame gameRef;
  bool _isOpen = false;
  late FilterDrawer _drawer;
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

    _drawer = FilterDrawer(gameRef: gameRef)
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
    // Click al abrir/cerrar el drawer
    AudioManager.click();
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
