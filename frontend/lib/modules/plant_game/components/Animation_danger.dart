import 'package:flame/components.dart';

class Animation_danger extends SpriteAnimationComponent {
  final String plantType;

  Animation_danger(this.plantType, Vector2 position)
      : super(
          position: position,
          size: Vector2(300, 300),
        );

  @override
  Future<void> onLoad() async {
    animation = await SpriteAnimation.load(
      'Animations/Danger Particles.png',
      SpriteAnimationData.sequenced(
        amount: 25,
        stepTime: 0.1,
        textureSize: Vector2(500, 500),
      ),
    );
  }
}