
import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'package:frontend/modules/main_menu/components/PanelName.dart';

import 'package:flame/components.dart';
import 'ButtonEnter.dart';
import 'PanelEnter.dart';


class LoginScreen extends FlameGame {
  final BuildContext context;
  final VoidCallback onLogin;

  LoginScreen(this.context, {required this.onLogin});
   @override
  Color backgroundColor() => const Color.fromARGB(255, 61, 67, 17);
  @override
  Future<void> onLoad() async {
  final panelEnter = PanelEnter()
    ..anchor = Anchor.center
    ..position = Vector2(size.x/2, size.y /2);
  add(panelEnter);

  final panelName = PanelName()
    ..anchor = Anchor.center
    ..position = Vector2(size.x/2, size.y /2);
  add(panelName);

  final buttonEnter = ButtonEnter(
      onPressed: () {
        onLogin();
      },)
      ..anchor = Anchor.bottomCenter
      ..position = Vector2(size.x / 2, size.y / 2+90);
  
  add(buttonEnter);

  
  } 
}
