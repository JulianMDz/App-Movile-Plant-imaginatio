
import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'package:go_router/go_router.dart';

import 'package:flame/components.dart';
import 'components/ButtonEnter.dart';
import 'components/background.dart';


class LoginScreen extends FlameGame {
  final BuildContext context;

  LoginScreen(this.context);

  @override
  Future<void> onLoad() async {
    add(Background());

    add(
      ButtonAction(
        onPressed: () {
          GoRouter.of(context).go('/plant_game');
        },
      )..position = Vector2(100, 100),
    );
  }
}
