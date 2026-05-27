
import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'package:frontend/modules/main_menu/components/PanelName.dart';

import 'package:flame/components.dart';
import 'ButtonEnter.dart';
import 'PanelEnter.dart';


class LoginScreen extends FlameGame {
  final BuildContext context;
  final VoidCallback onLogin;

  PanelEnter? panelEnter;
  PanelName? panelName;
  ButtonEnter? buttonEnter;

  LoginScreen(this.context, {required this.onLogin});

  @override
  Color backgroundColor() => const Color.fromARGB(255, 61, 67, 17);

  @override
  Future<void> onLoad() async {
    panelEnter = PanelEnter()..anchor = Anchor.center;
    panelName = PanelName()..anchor = Anchor.center;
    buttonEnter = ButtonEnter(
      onPressed: onLogin,
    )..anchor = Anchor.bottomCenter;

    add(panelEnter!);
    add(panelName!);
    add(buttonEnter!);
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);

    final centerX = size.x / 2;
    final centerY = size.y / 2;

    panelEnter?.position = Vector2(centerX, centerY);
    panelName?.position = Vector2(centerX, centerY);
    buttonEnter?.position = Vector2(centerX, centerY + 90);
  }
}
