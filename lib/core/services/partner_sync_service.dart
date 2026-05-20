import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../domain/models/partner_establishment.dart';
import '../../core/services/crypto_identity_service.dart';

/// **PartnerSyncService**
///
/// Serviço responsável pela sincronização online e atualização dinâmica da base de dados
/// de estabelecimentos parceiros bike-friendly chancelados oficialmente pela administração do aplicativo.
///
/// Implementa o padrão de projeto Singleton para garantir ponto único de sincronização.
class PartnerSyncService {
  static final PartnerSyncService _instance = PartnerSyncService._internal();

  /// Cria ou recupera a instância única e compartilhada de [PartnerSyncService].
  factory PartnerSyncService() => _instance;

  PartnerSyncService._internal();

  /// URL de API pública e estática gratuita no GitHub do Rastro para sincronização segura de parceiros.
  static const String _syncUrl = 'https://raw.githubusercontent.com/TheHugoHypothesis/Rastro/main/assets/partners.json';

  /// Realiza uma requisição HTTP para baixar a lista oficial de parceiros cadastrados.
  ///
  /// O método realiza o download de dados JSON de forma assíncrona, faz a desserialização
  /// e valida individualmente a assinatura digital criptográfica do administrador antes de
  /// incluir o parceiro na lista ativa. Se a assinatura for inválida ou corrompida, o local é descartado.
  ///
  /// Retorno:
  /// - `Future<List<PartnerEstablishment>>`: Uma lista contendo os estabelecimentos parceiros validados criptograficamente.
  ///
  /// Exceções:
  /// - Trata de forma silenciosa quaisquer exceções de conexão de rede, timeouts, ou erros de formato JSON
  ///   retornando uma lista vazia, garantindo resiliência offline do aplicativo.
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
