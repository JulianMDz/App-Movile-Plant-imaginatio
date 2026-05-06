import 'package:flame/game.dart';
import 'package:frontend/modules/main_menu/login_screen.dart';
import 'package:frontend/modules/plant_game/mini_games/sync/sync_flutter_overlay.dart';
import 'package:go_router/go_router.dart';

import 'package:frontend/modules/plant_game/plant_screen.dart';
import 'package:frontend/modules/main_menu/main_menu.dart';
import 'package:frontend/modules/main_menu/components/loginComponent.dart';
import 'package:frontend/modules/inventory/inventory_screen.dart';

final router = GoRouter(
  initialLocation: '/menu', // ← Esto define la ruta inicial
  routes: [
    GoRoute(
      path: '/',
      redirect: (context, state) => '/menu', // ← Redirige la raíz a /menu
    ),
    GoRoute(
      path: '/menu',
      builder: (context, state) => const MainMenuScreen(),
    ),
    GoRoute(
      path: '/login',
    builder: (context, state) => LoginOverlay(contextApp: context),
    ),
    GoRoute(
      path: '/plant_game',
      builder: (context, state) => PlantGameWrapper(
        child: GameWidget<PlantGameScreen>(
          game: PlantGameScreen(context),
          overlayBuilderMap: {
            'sync': (ctx, game) => SyncFlutterOverlay(game: game),
          },
        ),
      ),
    ),
    GoRoute(
   path: '/inventory',
   builder: (context, state) => GameWidget(game: InventoryScreen(context),),
  ),
  ],
);