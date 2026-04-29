import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'package:frontend/modules/main_menu/components/loginComponent.dart';
class LoginOverlay extends StatelessWidget {
  final BuildContext contextApp;

  const LoginOverlay({super.key, required this.contextApp});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GameWidget<LoginScreen>(
        game: LoginScreen(contextApp),

        // 🔥 AQUÍ VA TU CÓDIGO
        overlayBuilderMap: {
          'input': (context, game) {
            return Stack(
              children: [
                Positioned(
                  left: MediaQuery.of(context).size.width / 2 - 125,
                  top: MediaQuery.of(context).size.height / 2 - 20,
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
                        fillColor: Colors.transparent,
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        },

        // 🔥 y asegúrate de esto
        initialActiveOverlays: const ['input'],
      ),
    );
  }
}