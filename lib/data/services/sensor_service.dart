import 'dart:async';
import 'package:sensors_plus/sensors_plus.dart';

/// **SensorService (Model/Data/Sensor)**
///
/// Serviço encarregado de processar leituras em tempo real dos acelerômetros físicos do dispositivo.
/// Permite estimar a qualidade/rugosidade do pavimento percorrido pelo ciclista (RNF003/RNF010).
class SensorService {
  StreamSubscription<bool>? _subscription;

  /// Limiar de intensidade de trepidação (m/s²) para classificar a pavimentação como lisa ou rugosa.
  final double threshold = 20.0; 

  /// Provê um fluxo reativo contínuo indicando se a pavimentação é lisa (`true`) ou rugosa (`false`).
  Stream<bool> get pathQualityStream {
    return userAccelerometerEventStream()
        .map((event) {
          final intensity = event.x * event.x + event.y * event.y + event.z * event.z;
          // Se a intensidade for maior que o limite, indica pavimentação ruim
          return intensity < threshold; // Retorna true se for asfalto liso
        });
  }

  /// Inicia a escuta ativa do acelerômetro, chamando o retorno de chamada a cada atualização de rugosidade.
  ///
  /// Parâmetros:
  /// - [onUpdate]: Função callback a ser acionada a cada leitura física (`Function(bool isSmooth)`).
  void startListening(Function(bool isSmooth) onUpdate) {
    _subscription = pathQualityStream.listen(onUpdate);
  }

  /// Encerra e cancela a escuta do acelerômetro, liberando recursos do hardware.
  void stopListening() {
    _subscription?.cancel();
  }
}
