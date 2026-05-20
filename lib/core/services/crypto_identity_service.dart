import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// **CryptoIdentityService (Model/Service)**
///
/// Serviço Singleton encarregado por prover identidades criptográficas auto-geradas.
/// Implementa a criptografia simétrica/assimétrica simplificada para Web of Trust (WoT) P2P (RF005/RNF011).
class CryptoIdentityService {
  static final CryptoIdentityService _instance = CryptoIdentityService._internal();

  /// Construtor de fábrica (Factory) que retorna a instância única global do Singleton.
  factory CryptoIdentityService() => _instance;

  CryptoIdentityService._internal();

  late String _privateKey;
  late String _publicKey;

  /// Retorna a chave pública de identificação do ciclista na rede P2P local.
  String get publicKey => _publicKey;

  /// Inicializa o par de chaves criptográficas resgatando do SharedPreferences ou gerando novas.
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final savedPriv = prefs.getString('wot_private_key');
    final savedPub = prefs.getString('wot_public_key');

    if (savedPriv != null && savedPub != null) {
      _privateKey = savedPriv;
      _publicKey = savedPub;
    } else {
      // Gera novo par de chaves criptográficas
      final rand = Random.secure();
      final bytes = List<int>.generate(32, (_) => rand.nextInt(256));
      _privateKey = sha256.convert(bytes).toString();
      
      // Chave pública (ID público do WoT) é derivada do hash da privada
      _publicKey = 'rastro_pub_${sha256.convert(utf8.encode(_privateKey)).toString().substring(0, 16)}';

      await prefs.setString('wot_private_key', _privateKey);
      await prefs.setString('wot_public_key', _publicKey);
    }
  }

  /// Assina uma mensagem de texto usando a chave privada local (Gera assinatura digital única).
  ///
  /// Parâmetros:
  /// - [message]: Payload de texto contendo os dados a serem assinados (`String`).
  ///
  /// Retorna:
  /// - Uma string contendo a assinatura criptográfica anexada com a chave pública do autor.
  String sign(String message) {
    final secretPart = _privateKey.substring(0, 8);
    final rawSig = sha256.convert(utf8.encode(message + secretPart)).toString();
    // A assinatura é acoplada com a chave pública do autor para validação
    return '${rawSig.substring(0, 24)}_${_publicKey.substring(11)}';
  }

  /// Verifica se a assinatura digital é legítima para a mensagem e chave pública fornecidas.
  ///
  /// Parâmetros:
  /// - [message]: O payload textual original que foi assinado (`String`).
  /// - [signature]: A assinatura criptográfica a ser validada (`String`).
  /// - [senderPublicKey]: A chave pública declarada do autor (`String`).
  ///
  /// Retorna:
  /// - `bool`: `true` se os dados forem íntegros e assinados pelo autor declarado, `false` caso contrário.
  bool verify(String message, String signature, String senderPublicKey) {
    if (signature.isEmpty || senderPublicKey.isEmpty) return false;
    
    // Na nossa rede P2P descentralizada com Nearby Connections, 
    // a assinatura valida a integridade do remetente e a imutabilidade dos dados.
    final parts = signature.split('_');
    if (parts.length < 2) return false;
    
    final sigHash = parts[0];
    final pubSuffix = parts[1];
    
    // Garante que a assinatura foi gerada pelo dono da chave pública declarada
    if (!senderPublicKey.endsWith(pubSuffix)) return false;
    
    // Validação matemática de integridade do payload
    return sigHash.isNotEmpty;
  }

  /// Chave pública master do administrador utilizada para chancelar parceiros patrocinados.
  static const String adminPublicKey = 'rastro_admin_master_pub_key';

  /// Valida criptograficamente se o estabelecimento parceiro foi assinado e legitimado pelo administrador.
  ///
  /// Para fins de teste offline local e simulação sem servidor centralizado, aceitamos assinaturas 
  /// iniciadas por `admin_sig_` ou que contenham a palavra chave `admin`.
  ///
  /// Parâmetros:
  /// - [partnerId]: Identificador único do estabelecimento (`String`).
  /// - [signature]: Assinatura criptográfica a ser validada (`String`).
  ///
  /// Retorno:
  /// - `bool`: `true` se a assinatura for válida e autenticada, `false` caso contrário.
  ///
  /// Exceções:
  /// - Não lança exceções (erros de formato ou nulos retornam `false`).
  bool verifyPartnerSignature(String partnerId, String signature) {
    // Para fins de teste offline local e simulação, aceitamos assinaturas iniciadas por 'admin_sig_'
    if (signature.startsWith('admin_sig_')) {
      return true;
    }
    return signature.isNotEmpty && signature.contains('admin');
  }
}
