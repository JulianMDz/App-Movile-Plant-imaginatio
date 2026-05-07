import 'package:flame_audio/flame_audio.dart';

class AudioManager {

  // Estado de mute global
  static bool _muted = false;
  static bool get isMuted => _muted;

  static void toggleMute() {
    _muted = !_muted;
    if (_muted) {
      FlameAudio.bgm.audioPlayer.setVolume(0);
    } else {
      FlameAudio.bgm.audioPlayer.setVolume(0.5);
    }
  }

  // CARGAR TODOS LOS AUDIOS
static Future<void> init() async {
  await FlameAudio.audioCache.loadAll([
    'abono.mp3',
    'agua_recoleccion.mp3',
    'click_general.mp3',
    'composta_recoleccion.mp3',
    'inventario.mp3',
    'principal.mp3',
    'regar.mp3',
    'sol.mp3',
    'soles_recoleccion.mp3',
    'timer_minigames.mp3',
  ]);
}

  // =========================
  // EFECTOS
  // =========================

  static Future<void> click() async {
    if (_muted) return;
    await FlameAudio.play('click_general.mp3');
  }

  static Future<void> regar() async {
    if (_muted) return;
    await FlameAudio.play('regar.mp3');
  }

  static Future<void> sol() async {
    if (_muted) return;
    await FlameAudio.play('sol.mp3');
  }

  static Future<void> abono() async {
    if (_muted) return;
    await FlameAudio.play('abono.mp3');
  }

  static Future<void> recolectarAgua() async {
    if (_muted) return;
    await FlameAudio.play('agua_recoleccion.mp3');
  }

  static Future<void> recolectarComposta() async {
    if (_muted) return;
    await FlameAudio.play('composta_recoleccion.mp3');
  }

  static Future<void> recolectarSoles() async {
    if (_muted) return;
    await FlameAudio.play('soles_recoleccion.mp3');
  }

  static Future<void> miniGames() async {
    if (_muted) return;
    await FlameAudio.play('timer_minigames.mp3');
  }

  // =========================
  // MÚSICA (BGM)
  // =========================

  static Future<void> musicaPrincipal() async {
    if (_muted) return;
    await FlameAudio.bgm.play('principal.mp3', volume: 0.5);
  }

  static Future<void> musicaInventario() async {
    if (_muted) return;
    await FlameAudio.bgm.play('inventario.mp3', volume: 0.5);
  }

  static void stopMusica() {
    FlameAudio.bgm.stop();
  }
}