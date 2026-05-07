import 'dart:ui';
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
    try {
      debugPrint('[PlantComponent] 🌿 plantType: $plantType -> folderName: $folderName');
      final stageEnum = _intToStage(initialStage);
      final animation = await _loadStageAnimation(stageEnum);
      animations = {stageEnum: animation};
      current = stageEnum;
    } catch (e, stack) {
      debugPrint('[PlantComponent] ❌ Error en onLoad: $e');
      debugPrint('[PlantComponent] Stack: $stack');
      animations = {_intToStage(initialStage): SpriteAnimation(<SpriteAnimationFrame>[], loop: true)};
    }
  }

  /// Actualiza la planta mostrada y carga sus imágenes bajo demanda
  Future<void> updatePlant(String newPlantType, int newStage) async {
    debugPrint('[PlantComponent] 🔄 Actualizando planta: $newPlantType, fase: $newStage');
    
    try {
      final stageEnum = _intToStage(newStage);
      // Pasar el nuevo tipo de planta para que use el folder correcto
      animations = {
        stageEnum: await _loadStageAnimation(stageEnum, newPlantType),
      };
      current = stageEnum;
      debugPrint('[PlantComponent] ✅ Planta actualizada a: $newPlantType');
    } catch (e, stack) {
      debugPrint('[PlantComponent] ❌ Error al actualizar planta: $e');
    }
  }

  PlantStage get _activeStage => current ?? _intToStage(initialStage);

  Vector2 get stageOffset {
    switch (_activeStage) {
      case PlantStage.seed:
        return Vector2(size.x / 2, size.y / 2+120);
      case PlantStage.bush:
        return Vector2(size.x / 2, size.y / 2+60);
      case PlantStage.tree:
        return Vector2(size.x / 2, size.y / 2+60);
      case PlantStage.ent:
        return Vector2(size.x / 2, size.y / 2+60);
      default:
        return Vector2.zero();
    }
  }

  Vector2 get stageScale {
    switch (_activeStage) {
      case PlantStage.seed:
        return Vector2.all(0.3);
      case PlantStage.bush:
        return Vector2.all(0.5);
      case PlantStage.tree:
        return Vector2.all(0.6);
      case PlantStage.ent:
        return Vector2.all(0.7);
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
    
    // XEROFITO - primero los más específicos
    if (lowerId.contains('alcaparro enano')) return 'Alcaparro enano';
    if (lowerId.contains('dividivi')) return 'Dividivi';
    
    // SOLAR - primero los más específicos
    if (lowerId.contains('alcaparro grande')) return 'Alcaparro grande';
    if (lowerId.contains('alcaparro')) return 'Alcaparro';
    if (lowerId.contains('cajeto')) return 'Cajeto';
    if (lowerId.contains('espino')) return 'Espino';
    if (lowerId.contains('drago')) return 'Drago';
    
    // HIDRO
    if (lowerId.contains('aliso')) return 'Aliso';
    if (lowerId.contains('cedrillo')) return 'Cedrillo';
    if (lowerId.contains('cucharo')) return 'Cucharo';
    
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

  Future<SpriteAnimation> _loadStageAnimation(PlantStage stage, [String? overridePlantType]) async {
    final effectiveType = overridePlantType ?? plantType;
    final folder = _getFolderName(effectiveType);
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

  /// Mapea IDs de planta a nombres de carpetas (versión estática)
  String _getFolderName(String plantType) {
    if (plantType.isEmpty) return 'Pasto';
    
    final lowerId = plantType.toLowerCase();
    
    // XEROFITO - primero los más específicos
    if (lowerId.contains('alcaparro enano')) return 'Alcaparro enano';
    if (lowerId.contains('dividivi')) return 'Dividivi';
    
    // SOLAR - primero los más específicos
    if (lowerId.contains('alcaparro grande')) return 'Alcaparro grande';
    if (lowerId.contains('alcaparro')) return 'Alcaparro';
    if (lowerId.contains('cajeto')) return 'Cajeto';
    if (lowerId.contains('espino')) return 'Espino';
    if (lowerId.contains('drago')) return 'Drago';
    
    // HIDRO
    if (lowerId.contains('aliso')) return 'Aliso';
    if (lowerId.contains('cedrillo')) return 'Cedrillo';
    if (lowerId.contains('cucharo')) return 'Cucharo';
    
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

  Future<SpriteAnimation> _loadAnim(String file, int frames,) async {
    final imagePath = 'Planta/$file';
    
    try {
      // Usar Flame.images que es el cache global de imágenes
      final image = await Flame.images.load(imagePath);
      debugPrint('[PlantComponent] ✅ Cargado: $file');
      return SpriteAnimation.fromFrameData(
        image,
        SpriteAnimationData.sequenced(
          amount: frames,
          stepTime: 0.1,
          textureSize: Vector2(500, 500),
        ),
      );
    } catch (e) {
      debugPrint('[PlantComponent] ❌ Error cargando $file: $e');
    }
    
    // Si falla, intentar con Pasto como fallback
    String fallbackFile;
    if (file.contains('fase1')) {
      fallbackFile = 'Planta/Pasto/fase1_ss.png';
    } else if (file.contains('fase3')) {
      fallbackFile = 'Planta/Pasto/fase3_ss.png';
    } else if (file.contains('fase4')) {
      fallbackFile = 'Planta/Pasto/fase4_ss.png';
    } else {
      fallbackFile = 'Planta/Pasto/fase2_ss.png';
    }
    
    try {
      final fallbackImage = await Flame.images.load(fallbackFile);
      debugPrint('[PlantComponent] ✅ Fallback Pasto cargado');
      return SpriteAnimation.fromFrameData(
        fallbackImage,
        SpriteAnimationData.sequenced(
          amount: frames,
          stepTime: 0.1,
          textureSize: Vector2(500, 500),
        ),
      );
    } catch (e2) {
      debugPrint('[PlantComponent] ❌ Fallback Pasto también falló: $e2');
    }

    // Fallback final: animación vacía
    debugPrint('[PlantComponent] 🎨 Animación vacía (fallback final)');
    return SpriteAnimation(<SpriteAnimationFrame>[], loop: true);
  }
}