import 'package:flame/components.dart';
/*
enum PlantStage { seed, bush, tree, ENT }

class PlantComponent extends SpriteAnimationGroupComponent<PlantStage> {
  final String plantType;

  PlantComponent(this.plantType, Vector2 position)
      : super(
          position: position,
          size: Vector2(64, 64),
          current: PlantStage.seed,
        );

  @override
  Future<void> onLoad() async {
    animations = {
      PlantStage.seed: await _loadAnim('${plantType}_semilla.png', 4),
      PlantStage.bush: await _loadAnim('${plantType}_fase_02.png', 6),
      PlantStage.tree: await _loadAnim('${plantType}_fase_02.png', 8),
      PlantStage.ENT: await _loadAnim('${plantType}_ENT.png', 10),
    };
  }

  Future<SpriteAnimation> _loadAnim(String file, int frames) async {
    return SpriteAnimation.load(
      ('Planta/$file'),
      SpriteAnimationData.sequenced(
        amount: frames,
        stepTime: 0.1,
        textureSize: Vector2(64, 64),
      ),
    );
  }

}
*/
enum PlantStage { seed /*bush, tree, ENT*/ }

class PlantComponent extends SpriteAnimationGroupComponent<PlantStage> {
  final String plantType;

  PlantComponent(this.plantType, Vector2 position)
      : super(position: position, size: Vector2(500, 500));

  @override
  Future<void> onLoad() async {
    // Animaciones por estado
    animations = {
      PlantStage.seed: await _loadAnim('${plantType}_semilla.png', 6),
      /*PlantStage.bush: await _loadAnim('${plantType}_fase_02.png', 6),
      PlantStage.tree: await _loadAnim('${plantType}_fase_03.png', 8),
      PlantStage.ENT: await _loadAnim('${plantType}_ENT.png', 10),*/
    };

    // Estado inicial
    current = PlantStage.seed;
  }

  Future<SpriteAnimation> _loadAnim(String file, int frames) async {
    return SpriteAnimation.load(
      ('Planta/$file'),
      SpriteAnimationData.sequenced(
        amount: frames,
        stepTime: 0.1,
        textureSize: Vector2(1000, 1000),
      ),
    );
  }
}
