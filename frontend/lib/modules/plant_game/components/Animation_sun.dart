import 'package:flame/components.dart';

class Animation_sun extends SpriteAnimationComponent {
  final String plantType;

  Animation_sun(this.plantType, Vector2 position)
      : super(
          position: position,
          size: Vector2(300, 300),
          removeOnFinish: true,
        );

  @override
  Future<void> onLoad() async {
    animation = await SpriteAnimation.load(
      'Animations/Sol.png',
      SpriteAnimationData.sequenced(
        amount: 35,
        stepTime: 0.1,
        textureSize: Vector2(500, 500),
        loop: false,
      ),
    );
  }
}