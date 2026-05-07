import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:frontend/modules/plant_game/plant_controller.dart';

class CooldownIndicator extends PositionComponent {
  final BuildContext context;
  final String gameType; // 'sun', 'water', 'compost'
  late TextComponent _textComponent;
  int _lastSecond = -1;

  CooldownIndicator({
    required this.context,
    required this.gameType,
    required Vector2 position,
  }) : super(position: position);

  @override
  Future<void> onLoad() async {
    _textComponent = TextComponent(
      text: '',
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontFamily: 'Press Start 2P',
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(color: Colors.black, blurRadius: 4, offset: Offset(2, 2)),
          ],
        ),
      ),
    )
      ..anchor = Anchor.center
      ..position = Vector2(0, 0);

    add(_textComponent);
  }

  @override
  void update(double dt) {
    super.update(dt);

    final now = DateTime.now().second;
    if (now == _lastSecond) return;
    _lastSecond = now;

    _updateCooldownText();
  }

  void _updateCooldownText() {
    try {
      final controller = Provider.of<PlantController>(context, listen: false);

      Duration? remaining;
      switch (gameType) {
        case 'sun':
          remaining = controller.getSunGameRemainingCooldown();
          break;
        case 'water':
          remaining = controller.getWaterGameRemainingCooldown();
          break;
        case 'compost':
          remaining = controller.getCompostGameRemainingCooldown();
          break;
        default:
          remaining = null;
      }

      if (remaining != null) {
        _textComponent.text = controller.formatRemainingCooldown(remaining);
      } else {
        _textComponent.text = '';
      }
    } catch (e) {
      _textComponent.text = '';
    }
  }
}