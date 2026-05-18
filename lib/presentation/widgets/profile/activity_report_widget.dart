import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/models/activity_record.dart';
import '../../providers/app_state_provider.dart';

enum ReportPeriod { dia, semana, mes, ano }

class ActivityReportWidget extends ConsumerStatefulWidget {
  final bool isDark;
  final Color surfaceColor;
  final Color textColor;
  final Color subtextColor;
  final Color borderColor;
  final Color primaryColor;

  const ActivityReportWidget({
    super.key,
    required this.isDark,
    required this.surfaceColor,
    required this.textColor,
    required this.subtextColor,
    required this.borderColor,
    required this.primaryColor,
  });

  @override
  ConsumerState<ActivityReportWidget> createState() => _ActivityReportWidgetState();
}

class _ActivityReportWidgetState extends ConsumerState<ActivityReportWidget> {
  ReportPeriod _selectedPeriod = ReportPeriod.semana;

  @override
  Widget build(BuildContext context) {
    final prefService = ref.watch(preferencesServiceProvider);
    final List<ActivityRecord> records = prefService.loadActivityRecords();

    // Dados do período selecionado
    final reportData = _calculateReportData(records);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: widget.surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: widget.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Relatório de Atividades',
                style: TextStyle(
                  color: widget.textColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Icon(Icons.bar_chart_rounded, color: widget.primaryColor, size: 20),
            ],
          ),
          const SizedBox(height: 16),

          // Seletor de Período Neo-Brutalista
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: widget.isDark ? Colors.black26 : Colors.black.withOpacity(0.04),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: ReportPeriod.values.map((period) {
                final isSelected = _selectedPeriod == period;
                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedPeriod = period;
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? (widget.isDark ? Colors.white : Colors.black)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          _getPeriodLabel(period),
                          style: TextStyle(
                            color: isSelected
                                ? (widget.isDark ? Colors.black : Colors.white)
                                : widget.subtextColor,
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 20),

          // Resumo Numérico do Período
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                reportData.totalDistanceKm.toStringAsFixed(1),
                style: TextStyle(
                  color: widget.textColor,
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                'km',
                style: TextStyle(
                  color: widget.subtextColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${reportData.totalCalories.toStringAsFixed(0)} kcal',
                    style: TextStyle(
                      color: widget.textColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    _getDurationString(reportData.totalDurationSeconds),
                    style: TextStyle(
                      color: widget.subtextColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Gráfico de Barras Neo-Brutalista
          SizedBox(
            height: 120,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: reportData.bars.map((bar) {
                final maxBarValue = reportData.bars.map((b) => b.value).fold(0.0, math.max);
                final double percent = maxBarValue > 0 ? (bar.value / maxBarValue) : 0.0;
                final double barHeight = 8 + (percent * 75); // Altura mínima de 8px, máxima de 83px

                return Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Dica flutuante no topo da barra
                      if (bar.value > 0)
                        Text(
                          bar.value < 1.0
                              ? '${(bar.value * 1000).toStringAsFixed(0)}m'
                              : '${bar.value.toStringAsFixed(1)}k',
                          style: TextStyle(
                            color: widget.textColor,
                            fontSize: 8,
                            fontWeight: FontWeight.w800,
                          ),
                          textAlign: TextAlign.center,
                        )
                      else
                        const SizedBox(height: 10),
                      const SizedBox(height: 4),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: 14,
                        height: barHeight,
                        decoration: BoxDecoration(
                          color: bar.value > 0
                              ? widget.primaryColor
                              : (widget.isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.06)),
                          borderRadius: BorderRadius.circular(4),
                          border: bar.value > 0
                              ? Border.all(color: widget.textColor, width: 1.5)
                              : null,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        bar.label,
                        style: TextStyle(
                          color: widget.subtextColor,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.clip,
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  String _getPeriodLabel(ReportPeriod period) {
    switch (period) {
      case ReportPeriod.dia:
        return 'Dia';
      case ReportPeriod.semana:
        return 'Semana';
      case ReportPeriod.mes:
        return 'Mês';
      case ReportPeriod.ano:
        return 'Ano';
    }
  }

  String _getDurationString(double seconds) {
    if (seconds < 60) return '${seconds.toStringAsFixed(0)} seg';
    final minutes = seconds / 60;
    if (minutes < 60) return '${minutes.toStringAsFixed(0)} min';
    final hours = minutes / 60;
    return '${hours.toStringAsFixed(1)} horas';
  }

  _ReportData _calculateReportData(List<ActivityRecord> records) {
    final now = DateTime.now();
    double totalDistanceKm = 0.0;
    double totalDurationSeconds = 0.0;
    double totalCalories = 0.0;
    final List<_BarData> bars = [];

    switch (_selectedPeriod) {
      case ReportPeriod.dia:
        // Dia de hoje: divide em 4 períodos (Manhã, Tarde, Noite, Madrugada)
        final periods = [
          _BarData(label: 'Madru.', value: 0.0),
          _BarData(label: 'Manhã', value: 0.0),
          _BarData(label: 'Tarde', value: 0.0),
          _BarData(label: 'Noite', value: 0.0),
        ];

        for (var r in records) {
          if (r.timestamp.year == now.year &&
              r.timestamp.month == now.month &&
              r.timestamp.day == now.day) {
            totalDistanceKm += r.distanceMeters / 1000;
            totalDurationSeconds += r.durationSeconds;
            totalCalories += r.calories;

            final hour = r.timestamp.hour;
            if (hour >= 0 && hour < 6) {
              periods[0].value += r.distanceMeters / 1000;
            } else if (hour >= 6 && hour < 12) {
              periods[1].value += r.distanceMeters / 1000;
            } else if (hour >= 12 && hour < 18) {
              periods[2].value += r.distanceMeters / 1000;
            } else {
              periods[3].value += r.distanceMeters / 1000;
            }
          }
        }
        bars.addAll(periods);
        break;

      case ReportPeriod.semana:
        // Semana atual: de Segunda a Domingo (7 dias)
        final weekdayLabels = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];
        final weekdayValues = List.generate(7, (_) => 0.0);

        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        final startOfMon = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);

        for (var r in records) {
          if (r.timestamp.isAfter(startOfMon) || r.timestamp.isAtSameMomentAs(startOfMon)) {
            totalDistanceKm += r.distanceMeters / 1000;
            totalDurationSeconds += r.durationSeconds;
            totalCalories += r.calories;

            final dayIndex = r.timestamp.weekday - 1;
            if (dayIndex >= 0 && dayIndex < 7) {
              weekdayValues[dayIndex] += r.distanceMeters / 1000;
            }
          }
        }

        for (int i = 0; i < 7; i++) {
          bars.add(_BarData(label: weekdayLabels[i], value: weekdayValues[i]));
        }
        break;

      case ReportPeriod.mes:
        // Mês atual: agrupa em 4 semanas
        final weekLabels = ['Sem 1', 'Sem 2', 'Sem 3', 'Sem 4'];
        final weekValues = List.generate(4, (_) => 0.0);

        for (var r in records) {
          if (r.timestamp.year == now.year && r.timestamp.month == now.month) {
            totalDistanceKm += r.distanceMeters / 1000;
            totalDurationSeconds += r.durationSeconds;
            totalCalories += r.calories;

            final weekIndex = ((r.timestamp.day - 1) / 7).floor().clamp(0, 3);
            weekValues[weekIndex] += r.distanceMeters / 1000;
          }
        }

        for (int i = 0; i < 4; i++) {
          bars.add(_BarData(label: weekLabels[i], value: weekValues[i]));
        }
        break;

      case ReportPeriod.ano:
        // Ano atual: agrupa nos 12 meses
        final monthLabels = [
          'Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun',
          'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'
        ];
        final monthValues = List.generate(12, (_) => 0.0);

        for (var r in records) {
          if (r.timestamp.year == now.year) {
            totalDistanceKm += r.distanceMeters / 1000;
            totalDurationSeconds += r.durationSeconds;
            totalCalories += r.calories;

            final monthIndex = r.timestamp.month - 1;
            if (monthIndex >= 0 && monthIndex < 12) {
              monthValues[monthIndex] += r.distanceMeters / 1000;
            }
          }
        }

        for (int i = 0; i < 12; i++) {
          bars.add(_BarData(label: monthLabels[i], value: monthValues[i]));
        }
        break;
    }

    return _ReportData(
      totalDistanceKm: totalDistanceKm,
      totalDurationSeconds: totalDurationSeconds,
      totalCalories: totalCalories,
      bars: bars,
    );
  }
}

class _BarData {
  final String label;
  double value;

  _BarData({required this.label, required this.value});
}

class _ReportData {
  final double totalDistanceKm;
  final double totalDurationSeconds;
  final double totalCalories;
  final List<_BarData> bars;

  _ReportData({
    required this.totalDistanceKm,
    required this.totalDurationSeconds,
    required this.totalCalories,
    required this.bars,
  });
}
