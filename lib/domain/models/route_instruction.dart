class RouteInstruction {
  final String instruction;
  final double distance;
  final String name;

  RouteInstruction({
    required this.instruction,
    required this.distance,
    this.name = '',
  });

  /// Factory manual para ler o JSON "maneuver" do OSRM.
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
