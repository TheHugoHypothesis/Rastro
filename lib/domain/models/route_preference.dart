enum RouteStrategy {
  seguranca('Segurança'),
  rapidez('Rapidez'),
  menorEsforco('Menor Esforço'),
  maiorEsforco('Maior Esforço');

  final String label;
  const RouteStrategy(this.label);
}

class RoutePreference {
  final RouteStrategy strategy;
  final bool avoidPavingStones;

  RoutePreference({
    required this.strategy,
    this.avoidPavingStones = false,
  });
}
