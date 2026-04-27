
import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'package:frontend/modules/main_menu/components/PanelName.dart';
import 'package:go_router/go_router.dart';

import 'package:flame/components.dart';
import 'components/ButtonEnter.dart';
import 'components/PanelEnter.dart';


class LoginScreen extends FlameGame {
  final BuildContext context;

  LoginScreen(this.context);
   @override
  Color backgroundColor() => const Color.fromARGB(255, 60, 67, 17);
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
        GoRouter.of(context).go('/plant_game');
      },)
      ..anchor = Anchor.bottomCenter
      ..position = Vector2(size.x / 2, size.y / 2+90);
  
  add(buttonEnter);

  @override
  void onMount() {
  super.onMount();
  overlays.add('input'); // ✔️ aquí sí funciona
  } 
  }  
}
