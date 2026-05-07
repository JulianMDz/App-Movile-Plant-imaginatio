import 'package:flame/components.dart';
import 'package:flame/input.dart';

class Button_profile extends SpriteButtonComponent {
  Button_profile({
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
    button = await Sprite.load('Botones/Boton_Perfil_01.png');
    buttonDown = await Sprite.load('Botones/Boton_Perfil_02.png');

    size = button.srcSize/2.5;   
  }
}
