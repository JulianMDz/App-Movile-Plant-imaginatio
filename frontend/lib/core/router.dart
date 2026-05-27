import 'package:flame/game.dart';
import 'package:frontend/modules/main_menu/login_screen.dart';
import 'package:frontend/modules/plant_game/mini_games/sync/sync_flutter_overlay.dart';
import 'package:go_router/go_router.dart';

import 'package:frontend/modules/plant_game/plant_screen.dart';
import 'package:frontend/modules/inventory/inventory_screen.dart';

GoRouter createRouter(String initialLocation) {
  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: '/',
        redirect: (_, __) => initialLocation,
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
}