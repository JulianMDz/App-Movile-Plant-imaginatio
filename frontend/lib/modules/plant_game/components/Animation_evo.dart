import 'package:flame/components.dart';

class Animation_evolution extends SpriteAnimationComponent {
  final String plantType;

  Animation_evolution(this.plantType, Vector2 position)
      : super(
          position: position,
          size: Vector2(300, 300),
        );

  @override
  Future<void> onLoad() async {
    animation = await SpriteAnimation.load(
      'Animations/Evo.png',
      SpriteAnimationData.sequenced(
        amount: 25,
        stepTime: 0.1,
        textureSize: Vector2(500, 500),
      ),
    );
  }
}