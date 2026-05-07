import 'package:flame/components.dart';
import 'package:flame/flame.dart';
import 'package:flutter/foundation.dart';
import 'package:flame/game.dart';

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
    
    // Mapear IDs de planta a nombres de carpetas
    final lowerId = plantType.toLowerCase();
    
    // HIDRO
    if (lowerId.contains('aliso')) return 'Aliso';
    if (lowerId.contains('cedrillo')) return 'Cedrillo';
    if (lowerId.contains('cucharo')) return 'Cucharo';
    
    // SOLAR
    if (lowerId.contains('alcaparro grande')) return 'Alcaparro grande';
    if (lowerId.contains('alcaparro')) return 'Alcaparro';
    if (lowerId.contains('cajeto')) return 'Cajeto';
    if (lowerId.contains('espino')) return 'Espino';
    if (lowerId.contains('drago')) return 'Drago';
    
    // XEROFITO
    if (lowerId.contains('alcaparro enano')) return 'Alcaparro enano';
    if (lowerId.contains('dividivi')) return 'Dividivi';
    
    // MONTAÑA
    if (lowerId.contains('pino')) return 'Pino romerón';
    if (lowerId.contains('roble')) return 'Roble';
    if (lowerId.contains('nogal')) return 'Nogal';
    if (lowerId.contains('duraznillo')) return 'Duraznillo';
    
    // TEMPLADO
    if (lowerId.contains('manzano')) return 'Manzano';
    if (lowerId.contains('mangle')) return 'Mangle';
    if (lowerId.contains('sietecueros')) return 'Sietecueros';
    if (lowerId.contains('cedro')) return 'Cedro';
    
    // PASTO (default)
    if (lowerId.contains('pasto')) return 'Pasto';
    
    // Si no hay match, usar el ID tal cual
    return plantType;
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
    try {
      final anim = await SpriteAnimation.load(
        'Planta/$file',
        SpriteAnimationData.sequenced(
          amount: frames,
          stepTime: 0.1,
          textureSize: Vector2(500, 500),
        ),
      );
      debugPrint('[PlantComponent] ✅ Cargado: $file');
      return anim;
    } catch (e) {
      // Si falla, intentar cargar Pasto como fallback
      debugPrint('[PlantComponent] Error cargando $file, usando Pasto como fallback');
      
      // Determinar qué fase usar según el stage
      String fallbackFile;
      switch (file) {
        case _ when file.contains('fase1'):
          fallbackFile = 'Planta/Pasto/fase1_ss.png';
          break;
        case _ when file.contains('fase3'):
          fallbackFile = 'Planta/Pasto/fase3_ss.png';
          break;
        case _ when file.contains('fase4'):
          fallbackFile = 'Planta/Pasto/fase4_ss.png';
          break;
        default:
          fallbackFile = 'Planta/Pasto/fase2_ss.png';
      }
      
      try {
        return await SpriteAnimation.load(
          fallbackFile,
          SpriteAnimationData.sequenced(
            amount: frames,
            stepTime: 0.1,
            textureSize: Vector2(500, 500),
          ),
        );
      } catch (e2) {
        debugPrint('[PlantComponent] Error crítico: Fallback de Pasto falló');
        // Crear una animación vacía como último recurso
        return SpriteAnimation.fromFrameData(
          await Flame.images.load('Planta/Pasto/fase2_ss.png'),
          SpriteAnimationData.sequenced(
            amount: 1,
            stepTime: 1.0,
            textureSize: Vector2(500, 500),
          ),
        );
      }
    }
  }
}