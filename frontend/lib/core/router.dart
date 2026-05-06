import 'package:flame/game.dart';
import 'package:frontend/modules/main_menu/login_screen.dart';
import 'package:go_router/go_router.dart';

import 'package:frontend/modules/plant_game/plant_screen.dart';
import 'package:frontend/modules/main_menu/components/loginComponent.dart';
import 'package:frontend/modules/inventory/inventory_screen.dart';

final router = GoRouter(
  initialLocation: '/login', // ← Esto define la ruta inicial
  routes: [
    GoRoute(
      path: '/',
      redirect: (_, __) => '/login', // ← Redirige la raíz a /login
    ),
    GoRoute(
      path: '/login',
    builder: (context, state) => LoginOverlay(contextApp: context),
    ),
    GoRoute(
      path: '/plant_game',
      builder: (context, state) => GameWidget(game: PlantGameScreen(context),),
    ),
    GoRoute(
   path: '/inventory',
   builder: (context, state) => GameWidget(game: InventoryScreen(context),),
  ),
  ],
);