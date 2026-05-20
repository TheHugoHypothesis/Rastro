/// **VibrationData**
///
/// Modela a leitura tridimensional do acelerômetro do smartphone do ciclista.
/// Utilizado para analisar a rugosidade do pavimento e classificar vias (RF005).
class VibrationData {
  /// Aceleração medida no eixo horizontal X.
  final double x;

  /// Aceleração medida no eixo de avanço Y.
  final double y;

  /// Aceleração medida no eixo vertical Z.
  final double z;

  /// O carimbo de data/hora da leitura física do sensor.
  final DateTime timestamp;

  /// Inicializa uma nova leitura de vibração com eixos e timestamp obrigatórios.
  VibrationData({
    required this.x,
    required this.y,
    required this.z,
    required this.timestamp,
  });

  /// Retorna o módulo da vibração (intensidade vetorial total do solavanco).
  ///
  /// Retorno:
  /// - A intensidade calculada (`double`).
  double get intensity => (x * x + y * y + z * z);
}
