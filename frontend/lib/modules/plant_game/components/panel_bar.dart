import 'package:flame/components.dart';
import 'package:flame/experimental.dart';
import 'package:flame/flame.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:frontend/modules/plant_game/plant_controller.dart';

// ─────────────────────────────────────────────────────────────────────────────
// PanelLayout — columna lateral izquierda con las barras de recursos
//               de la planta activa (Sol, Agua, Composta).
//
// Lee los recursos_aplicados de la planta activa desde PlantController.
// Se suscribe a notifyListeners() para actualizar automáticamente en tiempo real.
// ─────────────────────────────────────────────────────────────────────────────
class PanelLayout extends PositionComponent {
  final BuildContext context;

  late BarraCarga _barraSol;
  late BarraCarga _barraAgua;
  late BarraCarga _barraComposta;

  /// Máximo de recursos aplicados representado como 100% de la barra.
  /// Ajustar según la lógica de negocio (ej: máximo 100 unidades por tipo).
  static const double _maxRecurso = 100.0;

  PanelLayout({required this.context});

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    Future<PositionComponent> buildItem(
      String path,
      BarraCarga barra,
    ) async {
      final img = await Flame.images.load(path);
      final sprite = SpriteComponent(
        sprite: Sprite(img),
        size: Sprite(img).srcSize / 1.5,
      )..anchor = Anchor.centerLeft;

      barra
        ..size = Vector2(70, 10)
        ..anchor = Anchor.centerLeft;

      return RowComponent(
        children: [
          PaddingComponent(padding: const EdgeInsets.only(right: 10), child: sprite),
          barra,
        ],
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
      );
    }

    _barraSol = BarraCarga(fillColor: const Color.fromARGB(255, 228, 110, 0));
    _barraAgua = BarraCarga(fillColor: const Color.fromARGB(255, 28, 87, 120));
    _barraComposta = BarraCarga(fillColor: const Color.fromARGB(255, 67, 27, 4));

    final itemSol = await buildItem('Iconos/Icono_Sol_01.png', _barraSol);
    final itemAgua = await buildItem('Iconos/Icono_Agua_01.png', _barraAgua);
    final itemComposta = await buildItem('Iconos/Icono_Abono_01.png', _barraComposta);

    final column = ColumnComponent(
      children: [
        PaddingComponent(padding: const EdgeInsets.only(bottom: 10), child: itemSol),
        PaddingComponent(padding: const EdgeInsets.only(bottom: 10), child: itemAgua),
        itemComposta,
      ],
    )..anchor = Anchor.center;

    await add(column);

    // Carga inicial
    _syncFromController();

    // Suscribirse a cambios del PlantController
    final controller = Provider.of<PlantController>(context, listen: false);
    controller.addListener(_syncFromController);
  }

  @override
  void onRemove() {
    // Desuscribirse al destruir el componente
    try {
      final controller = Provider.of<PlantController>(context, listen: false);
      controller.removeListener(_syncFromController);
    } catch (_) {}
    super.onRemove();
  }

  /// Actualiza las barras con los valores actuales del PlantController.
  void _syncFromController() {
    try {
      final controller = Provider.of<PlantController>(context, listen: false);
      final aplicados = controller.activePlantResources;

      _barraSol.progress =
          (aplicados.sol / _maxRecurso).clamp(0.0, 1.0);
      _barraAgua.progress =
          (aplicados.agua / _maxRecurso).clamp(0.0, 1.0);
      _barraComposta.progress =
          (aplicados.composta / _maxRecurso).clamp(0.0, 1.0);
    } catch (_) {}
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BarraCarga — barra de progreso horizontal dibujada con Canvas.
// ─────────────────────────────────────────────────────────────────────────────
class BarraCarga extends PositionComponent {
  double progress = 0.0;
  Color fillColor;

  BarraCarga({this.fillColor = Colors.green});

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final bgPaint = Paint()..color = const Color.fromARGB(255, 119, 193, 215);
    final fillPaint = Paint()..color = fillColor;

    canvas.drawRect(size.toRect(), bgPaint);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.x * progress, size.y),
      fillPaint,
    );
  }
}