import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'package:frontend/modules/main_menu/login_screen.dart';
class LoginOverlay extends StatelessWidget {
  final BuildContext contextApp;

  const LoginOverlay({super.key, required this.contextApp});

  @override
  Widget build(BuildContext context) {
    return GameWidget<LoginScreen>(
      game: LoginScreen(contextApp),
      overlayBuilderMap: {
        'input': (context, game) {
          return Center(
            child: SizedBox(
              width: 250,
              child: TextField(
                style: const TextStyle(
                  fontFamily: 'Press Start 2P',
                  fontSize: 12,
                  color: Colors.black,
                ),
                decoration: const InputDecoration(
                  hintText: 'Escribe tu nombre...',
                  filled: true,
                  fillColor: Color.fromARGB(255, 255, 0, 0),
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          );
        },
      },
    );
  }
}