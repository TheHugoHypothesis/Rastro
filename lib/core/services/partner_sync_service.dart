import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../domain/models/partner_establishment.dart';
import '../../core/services/crypto_identity_service.dart';

class PartnerSyncService {
  static final PartnerSyncService _instance = PartnerSyncService._internal();
  factory PartnerSyncService() => _instance;
  PartnerSyncService._internal();

  // URL de API pública e estática gratuita no GitHub do Rastro para sincronização
  static const String _syncUrl = 'https://raw.githubusercontent.com/TheHugoHypothesis/Rastro/main/assets/partners.json';

  Future<List<PartnerEstablishment>> fetchOfficialPartners() async {
    try {
      final response = await http.get(Uri.parse(_syncUrl))
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final List<dynamic> decoded = jsonDecode(response.body);
        final crypto = CryptoIdentityService();
        final List<PartnerEstablishment> verifiedPartners = [];

        for (final item in decoded) {
          try {
            final partner = PartnerEstablishment.fromJson(item as Map<String, dynamic>);
            // Valida que o parceiro foi de fato chancelado com a assinatura da administração
            if (crypto.verifyPartnerSignature(partner.id, partner.adminSignature)) {
              verifiedPartners.add(partner);
            }
          } catch (_) {}
        }
        return verifiedPartners;
      }
    } catch (e) {
      debugPrint('PartnerSyncService: Usando cache de parceiros local/offline: $e');
    }
    return [];
  }
}
