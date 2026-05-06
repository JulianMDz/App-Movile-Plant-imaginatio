import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';

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
    // Capturamos referencias antes del gap asíncrono para evitar use_build_context_synchronously
    final controller = Provider.of<PlantController>(widget.contextApp, listen: false);
    final router = GoRouter.of(widget.contextApp);

    await controller.loadCurrentTree();

    if (mounted) {
      router.go('/plant_game');
    }
  }

  void _clearSessionDebug() async {
    final authStorage = LocalStorageService();
    final treeStorage = TreeStorageService();

    await treeStorage.clearTree();
    await authStorage.clearSession();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sesión de debug reiniciada')),
      );
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
            // Align centra el TextField en pantalla, igual que el panel del juego.
            // Ajusta el offset Y si tu panel no está exactamente centrado.
            return Align(
              alignment: const Alignment(0, -0.1), // X=centro, Y=-0.1 sube más para coincidir con el panel
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
            );
          },
          'debug_clear': (context, game) {
            if (kDebugMode) {
              // Positioned necesita un Stack padre — el overlay builder debe
              // retornar un widget raíz completo, no un Positioned suelto.
              return Stack(
                children: [
                  Positioned(
                    right: 10,
                    bottom: 10,
                    child: TextButton(
                      onPressed: _clearSessionDebug,
                      child: const Text(
                        '🔧 Debug Reset',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ),
                ],
              );
            }
            return const SizedBox.shrink();
          },
        },
        // 🔥 y asegúrate de esto
        initialActiveOverlays: const ['input', 'debug_clear'],
      ),
    );
  }
}