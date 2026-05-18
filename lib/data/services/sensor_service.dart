import 'dart:async';
import 'package:sensors_plus/sensors_plus.dart';

class SensorService {
  StreamSubscription<bool>? _subscription;

  // Limite de trepidação para classificar como "paralelepípedo" ou terra
  final double threshold = 20.0; 

  Stream<bool> get pathQualityStream {
    return userAccelerometerEventStream()
        .map((event) {
          final intensity = event.x * event.x + event.y * event.y + event.z * event.z;
          // Se a intensidade for maior que o limite, indica pavimentação ruim
          return intensity < threshold; // Retorna true se for asfalto liso
        });
  }

  void startListening(Function(bool isSmooth) onUpdate) {
    _subscription = pathQualityStream.listen(onUpdate);
  }

  void stopListening() {
    _subscription?.cancel();
  }
}
