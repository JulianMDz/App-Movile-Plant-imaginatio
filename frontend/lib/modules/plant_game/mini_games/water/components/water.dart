import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flame/events.dart';

class ButtonResourceWater extends PositionComponent with TapCallbacks {
  late Sprite normal;
  late Sprite pressed;
  late Sprite disabled;

  int state = 0; // 0 = normal, 1 = pressed, 2 = disabled
  final void Function()? onPressed;

  ButtonResourceWater({this.onPressed});

  @override
  Future<void> onLoad() async {
    normal = await Sprite.load('Minijuegos/Panel_GotaAgua_01.png');
    pressed = await Sprite.load('Minijuegos/Panel_GotaAgua_01b.png');
    disabled = await Sprite.load('Minijuegos/Panel_GotaAgua_02.png');

    size = normal.srcSize / 2;
  }

  @override
  void render(Canvas canvas) {
    Sprite current;
    if (state == 1) {
      current = pressed;
    } else if (state == 2) {
      current = disabled;
    } else {
      current = normal;
    }
    current.render(canvas, size: size);
  }

  @override
  void onTapDown(TapDownEvent event) {
    if (state == 2) return; // Si está deshabilitado, no hace nada
    state = 1; // Cambia a presionado
    onPressed?.call(); // Llama a la función que cuenta los clics
  }

  @override
  void onTapUp(TapUpEvent event) {
    if (state == 2) return;
    state = 0; // Vuelve al estado normal al soltar
  }

  @override
  void onTapCancel(TapCancelEvent event) {
    if (state == 2) return;
    state = 0;
  }
}