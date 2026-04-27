import 'package:flame/components.dart';

class Background extends SpriteComponent with HasGameRef {
  @override
  Future<void> onLoad() async {
    // Cargar la imagen
    sprite = await Sprite.load('Escenarios/Escenario_Opcion_02.png');

    // Ajustar el alto al tamaño del juego
    final double scaleFactor = gameRef.size.y / sprite!.image.height;

    // Escalar proporcionalmente
    size = Vector2(
      sprite!.image.width * scaleFactor,
      sprite!.image.height * scaleFactor,
    );

    // Centrar en pantalla
    position = (gameRef.size - size) / 2;
  }
}
