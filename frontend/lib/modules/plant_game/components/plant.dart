import 'package:flame/components.dart';
import 'package:flame/flame.dart';
import 'package:flame/components.dart';

enum PlantStage { seed, bush, tree, ent }

class PlantComponent extends SpriteAnimationGroupComponent<PlantStage> {
  final String plantType;
  final int initialStage;

  PlantComponent(
    this.plantType,
    this.initialStage,
    Vector2 position,
  ) : super(
          position: position,
          size: Vector2(250, 250),
        );

  @override
  Future<void> onLoad() async {
    final stageEnum = _intToStage(initialStage);
    animations = {
      stageEnum: await _loadStageAnimation(stageEnum),
    };

    current = stageEnum;
  
  switch (stageEnum) {
      case PlantStage.seed:
        scale = Vector2.all(1.8);
        position += Vector2(0, -80);
        break;
      case PlantStage.bush:
        scale = Vector2.all(1.5);
        position += Vector2(0, -50);
        break;
      case PlantStage.tree:
        scale = Vector2.all(1.0);
        position += Vector2(0, 20);
        break;
      case PlantStage.ent:
        scale = Vector2.all(0.7);
        position += Vector2(0, 50);
        break;
    }
  }

  PlantStage _intToStage(int stage) {
    switch (stage) {
      case 1:
        return PlantStage.seed;
      case 2:
        return PlantStage.bush;
      case 3:
        return PlantStage.tree;
      case 4:
        return PlantStage.ent;
      default:
        throw Exception('Fase inválida: $stage');
    }
  }


  Future<SpriteAnimation> _loadStageAnimation(PlantStage stage) async {
    switch (stage) {
      case PlantStage.seed:
        return _loadAnim('Pasto/fase1_ss.png', 18);

      case PlantStage.bush:
        return _loadAnim('Pasto/fase2_ss.png', 18);

      case PlantStage.tree:
        return _loadAnim('Pasto/fase3_ss.png', 18);

      case PlantStage.ent:
        return _loadAnim('Pasto/fase4_ss.png', 18);
    }
  }

  Future<SpriteAnimation> _loadAnim(String file, int frames,) async {
    return SpriteAnimation.load(
      'Planta/$file',
      SpriteAnimationData.sequenced(
        amount: frames,
        stepTime: 0.1,
        textureSize: Vector2(500, 500),
      ),
    );
  }
}