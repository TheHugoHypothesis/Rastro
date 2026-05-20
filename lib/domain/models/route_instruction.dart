/// **RouteInstruction**
///
/// Representa uma instrução de navegação passo a passo (passo da rota)
/// contendo orientações textuais em português (Pt-BR) e distância a percorrer até a manobra.
class RouteInstruction {
  /// O texto legível em português descrevendo a manobra física a ser feita (ex: "Vire à esquerda na Av. Paulista").
  final String instruction;

  /// A distância parcial em metros até que a manobra seja de fato efetuada.
  final double distance;

  /// O nome da via onde a manobra ocorre (ex: "Avenida Paulista").
  final String name;

  /// Inicializa uma nova instrução de rota.
  RouteInstruction({
    required this.instruction,
    required this.distance,
    this.name = '',
  });

  /// Factory manual para analisar os passos brutos de manobra retornados da API do OSRM.
  ///
  /// Parâmetros:
  /// - [step]: Mapa correspondente a um objeto "step" da resposta HTTP do OSRM.
  ///
  /// Retorno:
  /// - Uma nova instância traduzida e estruturada de [RouteInstruction].
  factory RouteInstruction.fromOSRM(Map<String, dynamic> step) {
    final maneuver = step['maneuver'] as Map<String, dynamic>? ?? {};
    final type = maneuver['type'] ?? 'continue';
    final modifier = maneuver['modifier'] ?? 'straight';
    final name = step['name'] as String? ?? '';
    final distance = (step['distance'] as num?)?.toDouble() ?? 0.0;

    String instrucaoBase = '';
    // Traduz o modificador para Pt-BR globalmente, eliminando "left" / "right"
    final modifierStr = _translateModifier(modifier);

    // Tradução simples do roteador OSRM
    switch (type) {
      case 'depart':
        instrucaoBase = 'Siga $modifierStr';
        break;
      case 'turn':
        instrucaoBase = 'Vire $modifierStr';
        break;
      case 'continue':
        instrucaoBase = 'Continue em frente';
        break;
      case 'roundabout':
        instrucaoBase = 'Na rotatória, pegue a saída para $name';
        break;
      case 'arrive':
        instrucaoBase = 'Você chegou ao seu destino!';
        break;
      default:
        instrucaoBase = 'Siga $modifierStr';
    }

    if (name.isNotEmpty && type != 'arrive' && type != 'roundabout') {
      instrucaoBase += ' na $name';
    }

    return RouteInstruction(
      instruction: instrucaoBase,
      distance: distance,
      name: name,
    );
  }

  /// Serializa o objeto instrução em um formato JSON compatível.
  ///
  /// Retorno:
  /// - `Map<String, dynamic>` serializado.
  Map<String, dynamic> toJson() {
    return {
      'instruction': instruction,
      'distance': distance,
      'name': name,
    };
  }

  /// Desserializa um mapa JSON recriando uma instância de [RouteInstruction].
  ///
  /// Parâmetros:
  /// - [json]: O mapa de chaves JSON desserializado.
  ///
  /// Retorno:
  /// - Instância válida de [RouteInstruction].
  factory RouteInstruction.fromJson(Map<String, dynamic> json) {
    return RouteInstruction(
      instruction: json['instruction'] as String,
      distance: (json['distance'] as num).toDouble(),
      name: json['name'] as String? ?? '',
    );
  }

  /// Traduz a direção de manobra do inglês para o português formal.
  static String _translateModifier(String modifier) {
    switch (modifier) {
      case 'right': return 'à direita';
      case 'left': return 'à esquerda';
      case 'slight right': return 'levemente à direita';
      case 'slight left': return 'levemente à esquerda';
      case 'sharp right': return 'acentuadamente à direita';
      case 'sharp left': return 'acentuadamente à esquerda';
      case 'straight': return 'em frente';
      case 'uturn': return 'fazendo o retorno';
      default: return 'na direção $modifier';
    }
  }
}
