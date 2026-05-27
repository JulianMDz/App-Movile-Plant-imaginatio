import 'package:flame/components.dart';

class Background extends SpriteComponent with HasGameRef {
  @override
  Future<void> onLoad() async {
    // Cargar la imagen
    sprite = await Sprite.load('Escenarios/Escenario_Opcion_05.png');
    _resizeBackground(gameRef.size);
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    _resizeBackground(size);
  }

  void _resizeBackground(Vector2 gameSize) {
    if (sprite == null) return;
    
    // Ajustar el alto al tamaño del juego
    final double scaleFactor = gameSize.y / sprite!.image.height;

    // Escalar proporcionalmente
    size = Vector2(
      sprite!.image.width * scaleFactor,
      sprite!.image.height * scaleFactor,
    );

    // Centrar en pantalla
    position = Vector2(
      (gameSize.x - size.x) / 2,
      (gameSize.y - size.y) / 2,
    );
  }
}
