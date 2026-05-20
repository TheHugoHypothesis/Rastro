import 'package:flutter_tts/flutter_tts.dart';

/// **TtsService (Model/Service)**
///
/// Serviço Singleton encarregado pela síntese de fala e narração de áudio.
/// Fornece instruções por áudio passo a passo de rotas para ciclistas em português (RF003).
class TtsService {
  static final TtsService _instance = TtsService._internal();

  /// Construtor de fábrica (Factory) que retorna a instância única global do Singleton.
  factory TtsService() => _instance;

  late FlutterTts _flutterTts;
  bool _isInitialized = false;

  /// Indica se a narração de voz está habilitada reativamente.
  bool isEnabled = true;

  TtsService._internal() {
    _flutterTts = FlutterTts();
  }

  /// Inicializa e configura os motores de fala do dispositivo no idioma português brasileiro (`pt-BR`).
  Future<void> init() async {
    if (_isInitialized) return;
    await _flutterTts.setLanguage("pt-BR");
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
    _isInitialized = true;
  }

  /// Narra o texto fornecido por voz sintetizada se o áudio estiver habilitado.
  ///
  /// Parâmetros:
  /// - [text]: O texto da instrução ou aviso a ser narrado (`String`).
  Future<void> speak(String text) async {
    if (!isEnabled) return;
    if (!_isInitialized) await init();
    await _flutterTts.speak(text);
  }

  /// Encerra imediatamente qualquer emissão de áudio ou narração em andamento.
  Future<void> stop() async {
    await _flutterTts.stop();
  }
}
