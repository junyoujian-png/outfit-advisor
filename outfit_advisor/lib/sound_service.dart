import 'package:audioplayers/audioplayers.dart';

class SoundService {
  static final AudioPlayer _player = AudioPlayer();

  static Future<void> playMagic() async {
    try {
      await _player.stop();
      await _player.play(AssetSource('sounds/magic.wav'));
    } catch (_) {}
  }
}
