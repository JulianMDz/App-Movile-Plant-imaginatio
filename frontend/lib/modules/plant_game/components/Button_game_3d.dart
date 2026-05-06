import 'package:flame/components.dart';
import 'package:flame/input.dart';

class Button_game_3d extends SpriteButtonComponent {
  Button_game_3d({
    required void Function() onPressed,
  }) : super(
          size: Vector2.zero(),
          button: null,       // se inicializa luego
          buttonDown: null,   // se inicializa luego
          onPressed: onPressed,
        );

  @override
  Future<void> onLoad() async {
    // Cargar sprites aquí
    button = await Sprite.load('Botones/Boton_App_01.png');
    buttonDown = await Sprite.load('Botones/Boton_App_01.png');

    size = button.srcSize/1.2;   
  }
}
