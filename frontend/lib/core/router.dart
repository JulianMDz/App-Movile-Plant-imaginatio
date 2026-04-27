
import 'package:flame/game.dart';
import 'package:go_router/go_router.dart';

import 'package:frontend/modules/plant_game/plant_screen.dart';
import 'package:frontend/modules/main_menu/main_menu.dart';
import 'package:frontend/modules/main_menu/login_screen.dart';

final router = GoRouter(
  initialLocation: '/menu', // ← Esto define la ruta inicial
  routes: [
    GoRoute(
      path: '/',
      redirect: (_, __) => '/menu', // ← Redirige la raíz a /menu
    ),
    GoRoute(
      path: '/menu',
      builder: (context, state) => const MainMenuScreen(),
    ),
    GoRoute(
      path: '/login',
    builder: (context, state) => GameWidget(game: LoginScreen(context),),
    ),
    GoRoute(
      path: '/plant_game',
      builder: (context, state) => GameWidget(game: PlantGameScreen(),),
    ),
  ],
);

