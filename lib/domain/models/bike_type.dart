import 'package:flutter/material.dart';

/// **BikeType**
///
/// Enumeração dos tipos de bicicletas suportadas pelo Rastro para fins de
/// estimativa de tempo e adaptação de roteamento na malha viária (RF004).
enum BikeType {
  /// Bicicleta de passeio padrão com velocidade média estimada de 18 km/h.
  comum('Comum', Icons.pedal_bike),

  /// Bicicleta esportiva/speed com velocidade média estimada de 25 km/h, priorizando asfalto liso.
  corrida('Corrida', Icons.directions_bike),

  /// Bicicleta dobrável urbana compacta com velocidade média estimada de 14 km/h.
  dobravel('Dobrável', Icons.electric_bike),

  /// Bicicleta elétrica ou assistida com velocidade média estimada de 22 km/h.
  eletrica('Elétrica', Icons.electric_moped);

  /// Rótulo legível por humanos para exibição nas telas do aplicativo.
  final String label;

  /// Ícone do Flutter associado a este tipo de bicicleta para renderização visual.
  final IconData icon;

  /// Construtor privado para inicialização das propriedades do enum.
  const BikeType(this.label, this.icon);
}
