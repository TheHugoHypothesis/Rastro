/// **ActivityRecord**
///
/// Modela o registro consolidado de uma atividade física ou pedalada concluída pelo ciclista.
/// Usado para popular a aba de Perfil com histórico e estatísticas de progresso (RF001).
class ActivityRecord {
  /// Identificador único da atividade finalizada.
  final String id;

  /// Data e hora de encerramento do percurso.
  final DateTime timestamp;

  /// Distância total percorrida convertida para metros.
  final double distanceMeters;

  /// Duração total acumulada em segundos.
  final double durationSeconds;

  /// Estimativa aproximada de calorias ativas queimadas com base no esforço e tempo.
  final double calories;

  /// Construtor para inicialização das propriedades do histórico de atividade.
  ActivityRecord({
    required this.id,
    required this.timestamp,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.calories,
  });

  /// Converte a instância atual em um mapa de chave-valor JSON serializável.
  ///
  /// Retorno:
  /// - `Map<String, dynamic>` contendo as propriedades serializadas da atividade.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'distanceMeters': distanceMeters,
      'durationSeconds': durationSeconds,
      'calories': calories,
    };
  }

  /// Cria uma nova instância de [ActivityRecord] a partir de dados serializados JSON.
  ///
  /// Parâmetros:
  /// - [json]: Mapa JSON desserializado contendo as chaves necessárias.
  ///
  /// Retorno:
  /// - Uma nova instância válida de [ActivityRecord].
  ///
  /// Exceções:
  /// - Lança [FormatException] se a data não puder ser parseada ou [TypeError] se tipos divergirem.
  factory ActivityRecord.fromJson(Map<String, dynamic> json) {
    return ActivityRecord(
      id: json['id'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      distanceMeters: (json['distanceMeters'] as num).toDouble(),
      durationSeconds: (json['durationSeconds'] as num).toDouble(),
      calories: (json['calories'] as num).toDouble(),
    );
  }
}
