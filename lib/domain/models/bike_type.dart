import 'package:flutter/material.dart';

enum BikeType {
  comum('Comum', Icons.pedal_bike),
  corrida('Corrida', Icons.directions_bike),
  dobravel('Dobrável', Icons.electric_bike), // Alternativa visual para dobrável
  eletrica('Elétrica', Icons.electric_moped);

  final String label;
  final IconData icon;
  const BikeType(this.label, this.icon);
}
