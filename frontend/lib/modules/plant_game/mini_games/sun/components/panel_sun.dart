import 'package:flame/components.dart';

class panelSun extends SpriteComponent with HasGameRef {
  @override
  Future<void> onLoad() async {
    // Cargar la imagen
    sprite = await Sprite.load('Minijuegos/Panel_RecolectarSol_01.png');

    // Escalar proporcionalmente
     size = sprite!.srcSize/2;  

    // Centrar en pantalla
    position = (gameRef.size - size) / 2;
  }
}
