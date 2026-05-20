import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/theme/colors.dart';
import '../../../data/remote/poi_service.dart';
import '../../../domain/models/safety_evaluation.dart';
import '../../../core/services/crypto_identity_service.dart';
import '../../providers/app_state_provider.dart';
import '../../../core/services/haptic_service.dart';

class PoiDetailsSheet extends StatelessWidget {
  final PoiResult poi;
  final bool isDark;
  final Color surfaceColor;
  final Color textColor;
  final Color poiColor;
  final IconData poiIconData;
  final Function(LatLng, {String? title, String? subtitle}) onAddressSelected;

  const PoiDetailsSheet({
    super.key,
    required this.poi,
    required this.isDark,
    required this.surfaceColor,
    required this.textColor,
    required this.poiColor,
    required this.poiIconData,
    required this.onAddressSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 8, 20, MediaQuery.of(context).padding.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40, height: 4, margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: isDark ? AppColors.border : AppColors.lightBorder, 
              borderRadius: BorderRadius.circular(2)
            )
          ),
          // Cabeçalho com ícone + nome
          Row(
            children: [
              Container(
                width: 52, height: 52,
                decoration: BoxDecoration(shape: BoxShape.circle, color: poiColor),
                child: Icon(poiIconData, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(poi.name, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: textColor)),
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(color: poiColor.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(12)),
                      child: Text(poi.category.label,
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: poiColor)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Botão Traçar Rota
          SizedBox(
            width: double.infinity,
            height: 52,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: isDark ? AppColors.purpleGradient : null,
                color: isDark ? null : AppColors.lightPrimary,
                borderRadius: BorderRadius.circular(20),
                boxShadow: isDark
                    ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.4), blurRadius: 14)]
                    : [],
              ),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  onAddressSelected(poi.point, title: poi.name, subtitle: poi.category.label);
                },
                icon: const Icon(Icons.directions_bike_rounded, color: Colors.white),
                label: const Text('Traçar Rota até aqui',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

void showPoiDetailsSheet({
  required BuildContext context,
  required PoiResult poi,
  required bool isDark,
  required Color surfaceColor,
  required Color textColor,
  required Color poiColor,
  required IconData poiIconData,
  required Function(LatLng, {String? title, String? subtitle}) onAddressSelected,
}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: surfaceColor,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (ctx) => PoiDetailsSheet(
      poi: poi,
      isDark: isDark,
      surfaceColor: surfaceColor,
      textColor: textColor,
      poiColor: poiColor,
      poiIconData: poiIconData,
      onAddressSelected: onAddressSelected,
    ),
  );
}

class CoordinateDetailsSheet extends ConsumerStatefulWidget {
  final LatLng point;
  final Future<String> addressFuture;
  final bool isDark;
  final Color surfaceColor;
  final Color textColor;
  final Color accentColor;
  final Function(LatLng, {String? title, String? subtitle}) onAddressSelected;

  const CoordinateDetailsSheet({
    super.key,
    required this.point,
    required this.addressFuture,
    required this.isDark,
    required this.surfaceColor,
    required this.textColor,
    required this.accentColor,
    required this.onAddressSelected,
  });

  @override
  ConsumerState<CoordinateDetailsSheet> createState() => _CoordinateDetailsSheetState();
}

class _CoordinateDetailsSheetState extends ConsumerState<CoordinateDetailsSheet> {
  String? _resolvedAddress;

  void _showEvaluationDialog(BuildContext context) {
    int safetyScore = 5;
    int lightingScore = 5;
    int trafficScore = 3;
    int accidentScore = 1;
    bool hasCycleway = true;
    String safeTimePeriod = 'sempre';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: widget.surfaceColor,
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            children: [
              Icon(Icons.rate_review_rounded, color: widget.accentColor),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Avaliação Colaborativa (P2P)',
                  style: TextStyle(color: widget.textColor, fontSize: 18, fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sua avaliação será assinada criptograficamente offline e enviada aos ciclistas próximos via Nearby Connections.',
                  style: TextStyle(color: widget.isDark ? Colors.white70 : Colors.black87, fontSize: 12, height: 1.4),
                ),
                const SizedBox(height: 16),
                
                // 1. Segurança Geral
                _buildCriterionRow(
                  label: 'Segurança Geral:',
                  value: safetyScore,
                  onChanged: (val) => setDialogState(() => safetyScore = val),
                ),
                
                // 2. Iluminação
                _buildCriterionRow(
                  label: 'Nível de Iluminação:',
                  value: lightingScore,
                  onChanged: (val) => setDialogState(() => lightingScore = val),
                ),
                
                // 3. Tráfego de Veículos
                _buildCriterionRow(
                  label: 'Intensidade de Trânsito:',
                  value: trafficScore,
                  onChanged: (val) => setDialogState(() => trafficScore = val),
                ),
                
                // 4. Risco de Assaltos/Acidentes
                _buildCriterionRow(
                  label: 'Risco de Crime/Acidentes:',
                  value: accidentScore,
                  onChanged: (val) => setDialogState(() => accidentScore = val),
                ),
                
                const Divider(height: 24),
                
                // 5. Presença de Ciclovia
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Possui Ciclovia/Ciclofaixa:',
                      style: TextStyle(color: widget.textColor, fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                    Switch(
                      value: hasCycleway,
                      activeThumbColor: widget.accentColor,
                      onChanged: (val) => setDialogState(() => hasCycleway = val),
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // 6. Horário Recomendado
                Text(
                  'Período mais Seguro:',
                  style: TextStyle(color: widget.textColor, fontSize: 13, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: widget.isDark ? AppColors.cardDark : AppColors.lightBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: widget.isDark ? AppColors.border : AppColors.lightBorder),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: safeTimePeriod,
                      dropdownColor: widget.surfaceColor,
                      style: TextStyle(color: widget.textColor, fontSize: 13, fontWeight: FontWeight.w600),
                      isExpanded: true,
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() => safeTimePeriod = val);
                        }
                      },
                      items: const [
                        DropdownMenuItem(value: 'sempre', child: Text('Seguro a Qualquer Horário')),
                        DropdownMenuItem(value: 'dia', child: Text('Seguro Apenas de Dia')),
                        DropdownMenuItem(value: 'noite', child: Text('Seguro Apenas à Noite')),
                        DropdownMenuItem(value: 'evitar_noite', child: Text('Evitar Pedal Noturno')),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancelar', style: TextStyle(color: widget.textColor, fontWeight: FontWeight.w700)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.accentColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                HapticService().selectionClick();
                
                // 1. Resolve o ID do trecho da rua
                final segmentId = _resolvedAddress ?? 'Via Marcada';
                final timestamp = DateTime.now().millisecondsSinceEpoch;
                
                // 2. Cria a mensagem bruta de integridade para assinatura
                final rawMsg = '${segmentId}_${widget.point.latitude}_${widget.point.longitude}_${safetyScore}_$timestamp';
                
                // 3. Assina usando a chave privada local do WoT
                final crypto = CryptoIdentityService();
                final signature = crypto.sign(rawMsg);
                final myPublicKey = crypto.publicKey;

                // 4. Salva a nova avaliação estruturada
                final newEval = SafetyEvaluation(
                  segmentId: segmentId,
                  latitude: widget.point.latitude,
                  longitude: widget.point.longitude,
                  safetyScore: safetyScore,
                  lightingScore: lightingScore,
                  trafficScore: trafficScore,
                  accidentScore: accidentScore,
                  hasCycleway: hasCycleway,
                  safeTimePeriod: safeTimePeriod,
                  timestamp: timestamp,
                  creatorPublicKey: myPublicKey,
                  signature: signature,
                );

                ref.read(safetyEvaluationsProvider.notifier).addEvaluation(newEval);
                
                Navigator.pop(ctx); // fecha diálogo
                Navigator.pop(context); // fecha coordinate sheet

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const Icon(Icons.check_circle_rounded, color: Colors.greenAccent, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Avaliação de segurança assinada e salva na rede local P2P!',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: widget.isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                    backgroundColor: widget.isDark ? AppColors.cardDark : Colors.white,
                    duration: const Duration(seconds: 4),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: widget.isDark ? AppColors.border : AppColors.lightBorder,
                        width: 1,
                      ),
                    ),
                  ),
                );
              },
              child: const Text('Enviar Avaliação', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900)),
            ),
          ],
        ),
      ),
    );
  }

  /// Construtor de estrelas neo-brutalistas com área de toque mínima de 48dp (RNF017)
  Widget _buildCriterionRow({
    required String label,
    required int value,
    required ValueChanged<int> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: widget.textColor, fontSize: 13, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Row(
            children: List.generate(5, (index) {
              final starValue = index + 1;
              final isSelected = starValue <= value;
              return InkWell(
                onTap: () {
                  HapticService().selectionClick();
                  onChanged(starValue);
                },
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  width: 48,
                  height: 48,
                  alignment: Alignment.center,
                  child: Icon(
                    isSelected ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: isSelected ? Colors.amber : Colors.grey.withValues(alpha: 0.5),
                    size: 32,
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 8, 20, MediaQuery.of(context).padding.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40, height: 4, margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: widget.isDark ? AppColors.border : AppColors.lightBorder, 
              borderRadius: BorderRadius.circular(2)
            )
          ),
          // Cabeçalho com ícone de pin + nome/endereço
          Row(
            children: [
              Container(
                width: 52, height: 52,
                decoration: BoxDecoration(shape: BoxShape.circle, color: widget.accentColor),
                child: const Icon(Icons.location_on_rounded, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Local Marcado', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: widget.isDark ? Colors.white54 : Colors.black54)),
                    const SizedBox(height: 2),
                    FutureBuilder<String>(
                      future: widget.addressFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Padding(
                            padding: EdgeInsets.only(top: 4),
                            child: SizedBox(
                              height: 14,
                              width: 14,
                              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryLight),
                            ),
                          );
                        }
                        if (snapshot.hasError || !snapshot.hasData) {
                          return Text('Coordenadas Marcadas', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: widget.textColor));
                        }
                        _resolvedAddress = snapshot.data;
                        return Text(
                          snapshot.data!,
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: widget.textColor),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Botão Traçar Rota
          SizedBox(
            width: double.infinity,
            height: 52,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: widget.isDark ? AppColors.purpleGradient : null,
                color: widget.isDark ? null : AppColors.lightPrimary,
                borderRadius: BorderRadius.circular(20),
                boxShadow: widget.isDark
                    ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.4), blurRadius: 14)]
                    : [],
              ),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  final addressStr = _resolvedAddress ?? 'Local Marcado';
                  widget.onAddressSelected(widget.point, title: 'Local Marcado', subtitle: addressStr);
                },
                icon: const Icon(Icons.directions_bike_rounded, color: Colors.white),
                label: const Text('Traçar Rota até aqui',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
              ),
            ),
          ),
          const Divider(height: 32),
          
          // Seção de Avaliação P2P Multicritério com área de toque mínima expandida (RNF017)
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: widget.accentColor, width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              onPressed: () {
                HapticService().selectionClick();
                _showEvaluationDialog(context);
              },
              icon: Icon(Icons.rate_review_rounded, color: widget.accentColor, size: 20),
              label: Text(
                'Avaliar Segurança da Via (P2P)',
                style: TextStyle(color: widget.accentColor, fontWeight: FontWeight.w800, fontSize: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

void showCoordinateDetailsSheet({
  required BuildContext context,
  required LatLng point,
  required Future<String> addressFuture,
  required bool isDark,
  required Color surfaceColor,
  required Color textColor,
  required Color accentColor,
  required Function(LatLng, {String? title, String? subtitle}) onAddressSelected,
}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: surfaceColor,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (ctx) => CoordinateDetailsSheet(
      point: point,
      addressFuture: addressFuture,
      isDark: isDark,
      surfaceColor: surfaceColor,
      textColor: textColor,
      accentColor: accentColor,
      onAddressSelected: onAddressSelected,
    ),
  );
}

