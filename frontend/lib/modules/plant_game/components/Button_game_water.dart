import 'package:flame/components.dart';
import 'package:flame/input.dart';

class Button_water_game extends SpriteButtonComponent {
  Button_water_game({
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
    button = await Sprite.load('Botones/Boton_MinijuegoAgua_02.png');
    buttonDown = await Sprite.load('Botones/Boton_MinijuegoAgua_01.png');

    size = button.srcSize/2.5; 
  }
}
