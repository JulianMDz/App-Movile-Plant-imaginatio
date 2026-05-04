import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:frontend/modules/main_menu/components/loginComponent.dart';
import 'package:frontend/services/local_storage_service.dart';
import 'package:frontend/services/tree_storage_service.dart';
import 'package:frontend/models/models.dart';
import 'package:frontend/modules/plant_game/plant_controller.dart';

class LoginOverlay extends StatefulWidget {
  final BuildContext contextApp;

  const LoginOverlay({super.key, required this.contextApp});

  @override
  State<LoginOverlay> createState() => _LoginOverlayState();
}

class _LoginOverlayState extends State<LoginOverlay> {
  final TextEditingController _nameController = TextEditingController();

  void _handleLogin() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Por favor, ingresa tu nombre')),
        );
      }
      return;
    }

    final userId = name.toLowerCase().replaceAll(' ', '_');

    // 1. Guardar la sesión en LocalStorageService (sistema legado compatible)
    final authStorage = LocalStorageService();
    await authStorage.saveCurrentSession(userId);

    UserModel? user = await authStorage.getUser(userId);
    if (user == null) {
      user = UserModel(
        userId: userId,
        username: name,
        unlockedPlants: ['solar'],
        plants: [],
        resources: UserResources(),
      );
      await authStorage.saveUser(user);
    }

    // 2. Si ya hay un archivo .tree, actualizar el nombre del usuario para que se refleje.
    // Si no hay, el PlantController lo creará basándose en el UserModel cuando cargue.
    final treeStorage = TreeStorageService();
    final tree = await treeStorage.loadTree();
    if (tree != null) {
      tree.usuario = tree.usuario.copyWithFlutter(id: userId, nombre: name);
      await treeStorage.saveTreeLocally(flutterData: tree);
    }

    // 3. Recargar el controlador de estado y navegar al juego
    if (mounted) {
      final controller = Provider.of<PlantController>(widget.contextApp, listen: false);
      await controller.loadCurrentTree();
      GoRouter.of(widget.contextApp).go('/plant_game');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GameWidget<LoginScreen>(
        game: LoginScreen(widget.contextApp, onLogin: _handleLogin),

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
                      controller: _nameController,
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
                      onSubmitted: (_) => _handleLogin(),
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