import 'package:flame/components.dart';

class Animation_critical extends SpriteAnimationComponent {
  final String plantType;

  Animation_critical(this.plantType, Vector2 position)
      : super(
          position: position,
          size: Vector2(300, 300),
        );

  @override
  Future<void> onLoad() async {
    animation = await SpriteAnimation.load(
      'Animations/Critical Particles.png',
      SpriteAnimationData.sequenced(
        amount: 13,
        stepTime: 0.1,
        textureSize: Vector2(500, 500),
      ),
    );
  }
}