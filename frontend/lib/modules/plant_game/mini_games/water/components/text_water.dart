import 'package:flame/components.dart';
import 'package:flame/experimental.dart';
import 'package:flutter/material.dart';

class textWater extends PositionComponent with HasGameRef {
  @override
  Future<void> onLoad() async {

    // 🔹 Texto pequeño (arriba)
    final tiempo = TextBoxComponent(
      text: "5 SEC",
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Color.fromARGB(255, 29, 137, 159),
          fontSize: 20,
          fontFamily: 'Press Start 2P',
        ),
      ),
      align: Anchor.center,
    );

    // 🔹 Texto grande (abajo)
    final titulo = TextBoxComponent(
      text: "1 | 50",
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 28, // 🔥 más grande
          fontFamily: 'Press Start 2P',
        ),
      ),
      align: Anchor.center,
    );

    final rowText = RowComponent(
    children: [
     PaddingComponent(
              padding: EdgeInsets.only(right: 100),
              child: tiempo,
            ),
     titulo],
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
  );

  add(rowText);
    rowText
      ..position = gameRef.size / 2
      ..anchor = Anchor.center
      ..size = Vector2(gameRef.size.x * 0.8, 50);
  }
}