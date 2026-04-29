import 'package:flame/components.dart';

class Animation_water extends SpriteAnimationComponent {
  final String plantType;

  Animation_water(this.plantType, Vector2 position)
      : super(
          position: position,
          size: Vector2(300, 300),
          removeOnFinish: true,
        );

  @override
  Future<void> onLoad() async {
    animation = await SpriteAnimation.load(
      'Animations/Water.png',
      SpriteAnimationData.sequenced(
        amount: 16,
        stepTime: 0.1,
        textureSize: Vector2(500, 500),
        loop: false,
      ),
    );
  }
}