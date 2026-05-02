import 'package:flame/components.dart';

class PanelSun extends SpriteComponent with HasGameRef {
  int estado = 0;

  final List<String> spritesList = [
    'Minijuegos/Panel_RecolectarSol_01.png',
    'Minijuegos/Panel_MinijuegoSol_01.png',
    'Minijuegos/Panel_MinijuegoSol_02.png',
    'Minijuegos/Panel_MinijuegoSol_03.png',
    'Minijuegos/Panel_MinijuegoSol_04.png',
  ];

  @override
  Future<void> onLoad() async {
    await _loadSprite();
    size = sprite!.srcSize / 2;
    position = (gameRef.size - size) / 2;
  }

  Future<void> _loadSprite() async {
    sprite = await Sprite.load(spritesList[estado]);
  }

  void cambiarEstado(int nuevoEstado) async {
    estado = nuevoEstado.clamp(0, spritesList.length - 1);
    await _loadSprite();
  }
}