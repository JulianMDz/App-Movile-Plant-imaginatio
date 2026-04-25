import 'package:flame/components.dart';
import 'package:flame/input.dart';

class Button_resource_water extends SpriteButtonComponent {
  Button_resource_water({
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
    button = await Sprite.load('Botones/Boton_RecursoAgua_02.png');
    buttonDown = await Sprite.load('Botones/Boton_RecursoAgua_01.png');
    
    size = button.srcSize/2;
  }
}
