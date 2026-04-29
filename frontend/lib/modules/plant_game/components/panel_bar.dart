import 'package:flame/components.dart';
import 'package:flame/experimental.dart';
import 'package:flame/flame.dart';
import 'package:flutter/material.dart';

class PanelLayout extends PositionComponent {
  @override
Future<void> onLoad() async {
  await super.onLoad();
  Future<PositionComponent> buildItem(String path, double progress, Color color) async {
    final img = await Flame.images.load(path);

    final sprite = SpriteComponent(
      sprite: Sprite(img),
      size: Sprite(img).srcSize / 2,
    );

    final barra = BarraCarga(
      fillColor: color,
    )
      ..size = Vector2(40, 5)
      ..progress = progress;

    return RowComponent(
      children: [sprite, barra],
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
    );
     
  }
  
  final item1 = await buildItem(
    'Iconos/Icono_Sol_01.png',
    0.8,
    Color.fromARGB(255, 228, 110, 0),
  );

  final item2 = await buildItem(
    'Iconos/Icono_Agua_01.png',
    0.5,
    Color.fromARGB(255, 28, 87, 120),
  );

  final item3 = await buildItem(
    'Iconos/Icono_Abono_01.png',
    0.3,
    Color.fromARGB(255, 67, 27, 4),
  );

  final column = ColumnComponent(
    children: [
      PaddingComponent(
        padding: EdgeInsets.only(bottom: 5),
        child: item1,
      ),
      PaddingComponent(
        padding: EdgeInsets.only(bottom: 5),
        child: item2,
      ),
      item3,
    ],
  ) 
    ..anchor = Anchor.center;

  await add(column);
}
}


class BarraCarga extends PositionComponent {
  double progress = 0.5;
  Color fillColor;

  BarraCarga({this.fillColor = Colors.green});

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final bgPaint = Paint()..color = Color.fromARGB(255, 119, 193, 215);
    final fillPaint = Paint()..color = fillColor;

    canvas.drawRect(size.toRect(), bgPaint);

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.x * progress, size.y),
      fillPaint,
    );
  }
}