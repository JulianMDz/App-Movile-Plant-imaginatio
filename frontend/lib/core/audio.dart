import 'package:flame_audio/flame_audio.dart';

class AudioManager {

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
    await FlameAudio.play('click_general.mp3');
  }

  static Future<void> regar() async {
    await FlameAudio.play('regar.mp3');
  }

  static Future<void> sol() async {
    await FlameAudio.play('sol.mp3');
  }

  static Future<void> abono() async {
    await FlameAudio.play('abono.mp3');
  }

  static Future<void> recolectarAgua() async {
    await FlameAudio.play('agua_recoleccion.mp3');
  }

  static Future<void> recolectarComposta() async {
    await FlameAudio.play('composta_recoleccion.mp3');
  }

  static Future<void> recolectarSoles() async {
    await FlameAudio.play('soles_recoleccion.mp3');
  }

  static Future<void> musicaMiniGames() async {
    await FlameAudio.bgm.play('timer_minigames.mp3', volume: 0.5);
  }

  // =========================
  // MÚSICA (BGM)
  // =========================

  static Future<void> musicaPrincipal() async {
    await FlameAudio.bgm.play('principal.mp3', volume: 0.5);
  }

  static Future<void> musicaInventario() async {
    await FlameAudio.bgm.play('inventario.mp3', volume: 0.5);
  }

  static void stopMusica() {
    FlameAudio.bgm.stop();
  }
}