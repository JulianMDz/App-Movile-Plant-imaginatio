import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import 'core/router.dart';
import 'modules/plant_game/plant_controller.dart';
import 'services/local_storage_service.dart';
import 'services/tree_storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  final authStorage = LocalStorageService();
  final treeStorage = TreeStorageService();
  
  final sessionId = await authStorage.getCurrentSession();
  bool isUserRegistered = false;

  if (sessionId != null) {
    // 1. Verificar si el .tree existe y tiene un nombre de usuario
    final tree = await treeStorage.loadTree();
    if (tree != null && tree.usuario.nombre.trim().isNotEmpty) {
      isUserRegistered = true;
    } else {
      // 2. Fallback: Verificar si el usuario legado existe y tiene nombre
      final user = await authStorage.getUser(sessionId);
      if (user != null && user.username.trim().isNotEmpty) {
        isUserRegistered = true;
      }
    }
  }

  final initialRoute = isUserRegistered ? '/plant_game' : '/login';

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PlantController()),
      ],
      child: MyApp(initialRoute: initialRoute),
    ),
  );
}

class MyApp extends StatelessWidget {
  final String initialRoute;
  late final GoRouter router;

  MyApp({super.key, required this.initialRoute}) {
    router = createRouter(initialRoute);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: router,
    );
  }
}
