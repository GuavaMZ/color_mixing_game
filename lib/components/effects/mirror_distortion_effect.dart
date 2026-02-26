import 'package:flame/components.dart';
import '../../color_mixer_game.dart';

/// A chaotic effect that periodically flips the game world horizontally or vertically.
class MirrorDistortionEffect extends Component
    with HasGameReference<ColorMixerGame> {
  double _timer = 0;
  bool _isFlippedX = false;
  bool _isFlippedY = false;

  @override
  void onMount() {
    super.onMount();
    game.isMirrored = true;
    _applyFlip();
  }

  @override
  void onRemove() {
    game.isMirrored = false;
    game.camera.viewfinder.transform.scale = Vector2.all(1.0);
    super.onRemove();
  }

  @override
  void update(double dt) {
    super.update(dt);
    _timer += dt;

    // Flip again every 2-3 seconds
    if (_timer >= 2.5) {
      _timer = 0;
      if (game.random.nextBool()) {
        _isFlippedX = !_isFlippedX;
      } else {
        _isFlippedY = !_isFlippedY;
      }
      _applyFlip();
    }
  }

  void _applyFlip() {
    game.camera.viewfinder.transform.scale = Vector2(
      _isFlippedX ? -1.0 : 1.0,
      _isFlippedY ? -1.0 : 1.0,
    );
  }
}
