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
        scale = stageScale;
        break;
      case PlantStage.bush:
        scale = stageScale;
        break;
      case PlantStage.tree:
        scale = stageScale;
        break;
      case PlantStage.ent:
        scale = stageScale;
        break;
    }
  }

  PlantStage get _activeStage => current ?? _intToStage(initialStage);

  Vector2 get stageOffset {
    switch (_activeStage) {
      case PlantStage.seed:
        return Vector2(0, -80);
      case PlantStage.bush:
        return Vector2(0, -50);
      case PlantStage.tree:
        return Vector2(0, 20);
      case PlantStage.ent:
        return Vector2(0, 50);
      default:
        return Vector2.zero();
    }
  }

  Vector2 get stageScale {
    switch (_activeStage) {
      case PlantStage.seed:
        return Vector2.all(0.3);
      case PlantStage.bush:
        return Vector2.all(1.5);
      case PlantStage.tree:
        return Vector2.all(1.0);
      case PlantStage.ent:
        return Vector2.all(0.7);
      default:
        return Vector2.all(1.0);
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


  String get folderName {
    if (plantType.isEmpty) return 'Pasto';
    return plantType[0].toUpperCase() + plantType.substring(1);
  }

  Future<SpriteAnimation> _loadStageAnimation(PlantStage stage) async {
    final folder = folderName;
    switch (stage) {
      case PlantStage.seed:
        return _loadAnim('$folder/fase1_ss.png', 18);

      case PlantStage.bush:
        return _loadAnim('$folder/fase2_ss.png', 18);

      case PlantStage.tree:
        return _loadAnim('$folder/fase3_ss.png', 18);

      case PlantStage.ent:
        return _loadAnim('$folder/fase4_ss.png', 18);
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