import 'dart:ui';
import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/events.dart';

class CompostGrid extends PositionComponent with TapCallbacks {
  late List<Sprite> sprites;

  final void Function(int row, int col, bool isCorrect) onCellTap;

  final int rows = 2;
  final int cols = 4;

  final double cellSize = 50;
  final double spacing = 40;

  late List<List<int>> gridState;
  late List<List<bool>> tapped;

  // índices
  final List<int> organicIndexes = [0, 1, 2];
  final List<int> inorganicIndexes = [3, 4, 5];

  CompostGrid({required this.onCellTap});
   int state = 0;

  @override
  Future<void> onLoad() async {
    // 🔹 cargar sprites
    sprites = [
      await Sprite.load('Minijuegos/Organico_Manzana_01.png'),
      await Sprite.load('Minijuegos/Organico_Hoja_01.png'),
      await Sprite.load('Minijuegos/Organico_Banana_01.png'),
      await Sprite.load('Minijuegos/Inorganico_Lata_01.png'),
      await Sprite.load('Minijuegos/Inorganico_Botella_01.png'),
      await Sprite.load('Minijuegos/Inorganico_Basura_01.png'),
    ];

    _generateGrid();

    // 🔹 evitar doble tap
    tapped = List.generate(
      rows,
      (_) => List.generate(cols, (_) => false),
    );

    // 🔹 tamaño total del grid
    size = Vector2(
      cols * cellSize + (cols - 1) * spacing,
      rows * cellSize + (rows - 1) * spacing,
    );
  }

  // --------------------------------------------------
  // 🎲 GENERAR GRID ALEATORIO
  // --------------------------------------------------
  void _generateGrid() {
  final random = Random();

  List<int> cells = [];

  // 🔹 ORGÁNICOS (3 únicos + 1 repetido)
  List<int> organicPool = List.from(organicIndexes);
  organicPool.shuffle();

  cells.addAll(organicPool); // agrega 3

  // agregar 1 extra aleatorio (puede repetir)
  cells.add(organicIndexes[random.nextInt(organicIndexes.length)]);

  // 🔹 INORGÁNICOS (igual lógica)
  List<int> inorganicPool = List.from(inorganicIndexes);
  inorganicPool.shuffle();

  cells.addAll(inorganicPool); // agrega 3

  // agregar 1 extra
  cells.add(inorganicIndexes[random.nextInt(inorganicIndexes.length)]);

  // 🔹 mezclar todo
  cells.shuffle();

  // 🔹 convertir a matriz
  gridState = List.generate(
    rows,
    (row) => List.generate(
      cols,
      (col) => cells[row * cols + col],
    ),
  );
}
  // --------------------------------------------------
  // 🎨 RENDER
  // --------------------------------------------------
  @override
  void render(Canvas canvas) {
    for (int row = 0; row < rows; row++) {
      for (int col = 0; col < cols; col++) {
        final posX = col * (cellSize + spacing);
        final posY = row * (cellSize + spacing);

        final spriteIndex = gridState[row][col];

        canvas.save();
        canvas.translate(posX, posY);

        final paint = Paint();
        // 🔹 si ya fue tocado → puedes cambiar visual
        if (tapped[row][col]) {
          // 🔻 opacidad (0.0 = invisible, 1.0 = normal)
          paint.color = const Color(0x88FFFFFF); // 50% opaco
        } else {
          paint.color = const Color(0xFFFFFFFF); // normal
        }

      sprites[spriteIndex].render(
        canvas,
        size: Vector2(cellSize, cellSize),
        overridePaint: paint,
      );

      canvas.restore();
    }
  }
}

  // --------------------------------------------------
  // 👆 INPUT
  // --------------------------------------------------
  @override
  void onTapUp(TapUpEvent event) {
    final local = event.localPosition;

    final col = (local.x / (cellSize + spacing)).floor();
    final row = (local.y / (cellSize + spacing)).floor();

    if (!_isValid(row, col)) return;

    if (tapped[row][col]) return; // ❌ evitar doble tap

    tapped[row][col] = true;

    final spriteIndex = gridState[row][col];

    final isOrganic = organicIndexes.contains(spriteIndex);

    onCellTap(row, col, isOrganic);
  }

  bool _isValid(int row, int col) {
    return row >= 0 && row < rows && col >= 0 && col < cols;
  }
}