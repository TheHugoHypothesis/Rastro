class VibrationData {
  final double x;
  final double y;
  final double z;
  final DateTime timestamp;

  VibrationData({
    required this.x,
    required this.y,
    required this.z,
    required this.timestamp,
  });

  /// Retorna o módulo da vibração (intensidade total do solavanco).
  double get intensity => (x * x + y * y + z * z);
}
