/// **RouteStrategy**
///
/// Enumeração das heurísticas de inteligência e estratégias de roteamento para
/// o ciclista (RF003).
enum RouteStrategy {
  /// Prioriza vias com maior pontuação média de segurança e iluminação a partir de relatos P2P.
  seguranca('Segurança'),

  /// Prioriza a rota geométrica mais curta ou rápida.
  rapidez('Rapidez'),

  /// Prioriza trechos lineares planos, estáveis e com menor densidade de manobras por km.
  menorEsforco('Menor Esforço'),

  /// Prioriza subidas e caminhos curtos e diretos para maior intensidade de treino.
  maiorEsforco('Maior Esforço');

  /// Rótulo legível por humanos para exibição nas telas do aplicativo.
  final String label;

  /// Construtor privado para inicialização das propriedades do enum.
  const RouteStrategy(this.label);
}

/// **RoutePreference**
///
/// Modela as preferências e critérios de roteamento ativos selecionados pelo usuário.
class RoutePreference {
  /// A estratégia principal de seleção de trajetos.
  final RouteStrategy strategy;

  /// Indica se o ciclista deseja ativamente desviar de vias com paralelepípedos ou lajotas.
  final bool avoidPavingStones;

  /// Inicializa uma nova preferência de rota do ciclista.
  RoutePreference({
    required this.strategy,
    this.avoidPavingStones = false,
  });
}
