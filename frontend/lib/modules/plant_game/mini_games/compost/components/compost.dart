import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flame/events.dart';

class CompostGrid extends PositionComponent with TapCallbacks {
  late List<Sprite> sprites;

  final int rows = 2;
  final int cols = 4;
  final double cellSize = 50;

  final double spacing = 40;

  late List<List<int>> gridState;

  @override
  Future<void> onLoad() async {
    // cargar las 6 imágenes
    sprites = [
      await Sprite.load('Minijuegos/Organico_Manzana_01.png'),
      await Sprite.load('Minijuegos/Organico_Hoja_01.png'),
      await Sprite.load('Minijuegos/Organico_Banana_01.png'),
      await Sprite.load('Minijuegos/Inorganico_Lata_01.png'),
      await Sprite.load('Minijuegos/Inorganico_Botella_01.png'),
      await Sprite.load('Minijuegos/Inorganico_Basura_01.png'),
    ];

    // matriz inicial
    gridState = List.generate(
      rows,
      (_) => List.generate(cols, (_) => 0),
    );

    size = Vector2(
      cols * cellSize + (cols - 1) * spacing,
      rows * cellSize + (rows - 1) * spacing,
    );
        
  }

 @override
void render(Canvas canvas) {
  for (int row = 0; row < rows; row++) {
    for (int col = 0; col < cols; col++) {
      final posX = col * (cellSize+spacing);
      final posY = row * (cellSize+spacing);

      final spriteIndex = gridState[row][col];

      canvas.save();
      canvas.translate(posX, posY);

      sprites[spriteIndex].render(
        canvas,
        size: Vector2(cellSize, cellSize), // 👈 AQUÍ defines el tamaño
      );

      canvas.restore();
    }
  }
}
  @override
  void onTapUp(TapUpEvent event) {
    final local = event.localPosition;

    final col = (local.x / (cellSize + spacing)).floor();
    final row = (local.y / (cellSize + spacing)).floor();

    if (row >= 0 && row < rows && col >= 0 && col < cols) {
      // cambia al siguiente estado (ciclo 0→5)
      gridState[row][col] =
          (gridState[row][col] + 1) % sprites.length;
    }
  }
}