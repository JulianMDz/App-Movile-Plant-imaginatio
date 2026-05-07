import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/input.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:frontend/core/audio.dart';

class Button_credit extends SpriteButtonComponent with HasGameRef {
  Button_credit({
    required void Function() onPressed,
  }) : super(
          size: Vector2.zero(),
          button: null,
          buttonDown: null,
          onPressed: onPressed,
        );

  @override
  Future<void> onLoad() async {
    button = await Sprite.load('Botones/Boton_Creditos_01.png');
    buttonDown = await Sprite.load('Botones/Boton_Creditos_02.png');
    size = button.srcSize / 2.5;

    // Sobreescribe onPressed para mostrar el panel de créditos
    onPressed = () {
      AudioManager.click(); 
      gameRef.add(_CreditsOverlay(gameRef: gameRef));
    };
  }
}

// -------------------------------------------------------
// Overlay de créditos
// -------------------------------------------------------
class _CreditsOverlay extends PositionComponent with TapCallbacks {
  final FlameGame gameRef;

  _CreditsOverlay({required this.gameRef});

  @override
  Future<void> onLoad() async {
    size = gameRef.size;
    priority = 50;

    // Panel de créditos centrado
    final panelSprite = await Sprite.load('Paneles/Panel_Creditos.png');
    final double panelW = gameRef.size.x * 0.37;
    final double panelH = panelW * (panelSprite.srcSize.y / panelSprite.srcSize.x);
    final double panelX = (gameRef.size.x - panelW) / 2;
    final double panelY = (gameRef.size.y - panelH) / 2;

    add(SpriteComponent()
      ..sprite = panelSprite
      ..size = Vector2(panelW, panelH)
      ..position = Vector2(panelX, panelY));

    // Botón cerrar — esquina superior derecha del panel
    add(_CloseButton(
      onClose: () => removeFromParent(),
    )
      ..position = Vector2(panelX + panelW - 28, panelY + 45)
      ..size = Vector2(33, 33));
  }

  @override
  void onTapDown(TapDownEvent event) {
    // Absorbe taps para que no pasen al fondo
    event.continuePropagation = false;
  }
}

// -------------------------------------------------------
// Botón cerrar del overlay
// -------------------------------------------------------
class _CloseButton extends SpriteComponent with TapCallbacks {
  final VoidCallback onClose;

  _CloseButton({required this.onClose});

  @override
  Future<void> onLoad() async {
    sprite = await Sprite.load('Botones/Boton_Cerrar_01.png');
  }

  @override
  void onTapDown(TapDownEvent event) {
    AudioManager.click(); 
    onClose();
    event.continuePropagation = false;
  }
}
