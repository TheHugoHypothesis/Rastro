import 'dart:async';
import 'dart:convert';
import 'package:nearby_connections/nearby_connections.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/safety_evaluation.dart';
import '../../data/local/preferences_service.dart';
import '../../presentation/providers/app_state_provider.dart';
import 'crypto_identity_service.dart';

class P2PMeshSyncService {
  static final P2PMeshSyncService _instance = P2PMeshSyncService._internal();
  factory P2PMeshSyncService() => _instance;
  P2PMeshSyncService._internal();

  late PreferencesService _prefsService;
  late Ref _ref;
  bool _isInitialized = false;
  
  final Map<String, String> _connectedPeers = {};
  final _syncEventController = StreamController<String>.broadcast();
  Stream<String> get syncEvents => _syncEventController.stream;

  void init(PreferencesService prefsService, Ref ref) {
    _prefsService = prefsService;
    _ref = ref;
    _isInitialized = true;
    startSyncProcess();
  }

  Future<void> stopSyncProcess() async {
    try {
      await Nearby().stopAdvertising();
      await Nearby().stopDiscovery();
      await Nearby().stopAllEndpoints();
      _connectedPeers.clear();
      _syncEventController.add('Rede P2P offline: compartilhamento desativado.');
    } catch (e) {
      // Ignora falhas na parada
    }
  }

  Future<void> startSyncProcess() async {
    if (!_isInitialized) return;
    
    final isP2PEnabled = _ref.read(p2pEnabledProvider);
    if (!isP2PEnabled) {
      stopSyncProcess();
      return;
    }
    
    final granted = await requestPermissions();
    if (!granted) {
      _syncEventController.add('Permissões de pareamento Bluetooth/Wi-Fi recusadas.');
      return;
    }

    final isLocationEnabled = await Geolocator.isLocationServiceEnabled();
    if (!isLocationEnabled) {
      _syncEventController.add('Ative o GPS para trocar dados de rotas seguras.');
      return;
    }

    try {
      final myName = _prefsService.prefs.getString('user_name_pref') ?? 'Ciclista Rastro';
      const serviceId = 'com.rastro.safety.sync';
      const strategy = Strategy.P2P_CLUSTER;

      await Nearby().stopAdvertising();
      await Nearby().stopDiscovery();

      // 1. Inicia o Anúncio (Advertising)
      await Nearby().startAdvertising(
        myName,
        strategy,
        onConnectionInitiated: _onConnectionInitiated,
        onConnectionResult: _onConnectionResult,
        onDisconnected: _onDisconnected,
        serviceId: serviceId,
      );

      // 2. Inicia a Descoberta (Discovery)
      await Nearby().startDiscovery(
        myName,
        strategy,
        onEndpointFound: (id, name, sId) {
          Nearby().requestConnection(
            myName,
            id,
            onConnectionInitiated: _onConnectionInitiated,
            onConnectionResult: _onConnectionResult,
            onDisconnected: _onDisconnected,
          );
        },
        onEndpointLost: (id) {},
        serviceId: serviceId,
      );

      _syncEventController.add('Rede P2P ativa: escaneando ciclistas próximos via Bluetooth/Wi-Fi...');
    } catch (e) {
      _syncEventController.add('Erro ao iniciar Nearby: $e');
    }
  }

  void _onConnectionInitiated(String endpointId, ConnectionInfo info) {
    _connectedPeers[endpointId] = info.endpointName;
    Nearby().acceptConnection(
      endpointId,
      onPayLoadRecieved: _onPayloadReceived,
      onPayloadTransferUpdate: (epId, update) {},
    );
  }

  void _onConnectionResult(String endpointId, Status status) {
    final peerName = _connectedPeers[endpointId] ?? 'Ciclista Próximo';
    if (status == Status.CONNECTED) {
      _syncEventController.add('Sincronizando dados com ciclista $peerName!');
      _sendLocalEvaluations(endpointId);
    } else {
      _connectedPeers.remove(endpointId);
    }
  }

  void _onDisconnected(String endpointId) {
    final peerName = _connectedPeers.remove(endpointId) ?? 'Ciclista';
    _syncEventController.add('Ciclista $peerName desconectado da rede.');
  }

  Future<void> _sendLocalEvaluations(String endpointId) async {
    final local = _prefsService.loadSafetyEvaluations();
    final jsonStr = jsonEncode(local.map((e) => e.toJson()).toList());
    final bytes = utf8.encode(jsonStr);
    
    await Nearby().sendBytesPayload(endpointId, bytes);
  }

  void _onPayloadReceived(String endpointId, Payload payload) {
    if (payload.type != PayloadType.BYTES || payload.bytes == null) return;

    try {
      final jsonStr = utf8.decode(payload.bytes!);
      final List<dynamic> decoded = jsonDecode(jsonStr);
      final receivedEvaluations = decoded.map((e) => SafetyEvaluation.fromJson(e as Map<String, dynamic>)).toList();

      final crypto = CryptoIdentityService();
      final local = _prefsService.loadSafetyEvaluations();
      final peerName = _connectedPeers[endpointId] ?? 'Ciclista';
      int addedCount = 0;

      for (final eval in receivedEvaluations) {
        final exists = local.any((e) => 
          e.segmentId == eval.segmentId && 
          e.creatorPublicKey == eval.creatorPublicKey && 
          e.timestamp == eval.timestamp
        );
        if (exists) continue;

        // 1. Verificação Criptográfica da Assinatura
        final rawMsg = '${eval.segmentId}_${eval.latitude}_${eval.longitude}_${eval.safetyScore}_${eval.timestamp}';
        final isValid = crypto.verify(rawMsg, eval.signature, eval.creatorPublicKey);
        if (!isValid) continue;

        // 2. Prevenção Sybil: Limite de 3 votos por hora por chave pública
        final hourWindow = 3600000;
        final countInHour = receivedEvaluations.where((e) =>
          e.creatorPublicKey == eval.creatorPublicKey &&
          (e.timestamp - eval.timestamp).abs() < hourWindow
        ).length;

        if (countInHour > 3) continue;

        // 3. Mescla na base local e atualiza o estado Riverpod em tempo real
        _ref.read(safetyEvaluationsProvider.notifier).addEvaluation(eval);
        addedCount++;
      }

      if (addedCount > 0) {
        _syncEventController.add('Sucesso P2P: Sincronizadas $addedCount avaliações com ciclista $peerName via WiFi Direct!');
      } else {
        _syncEventController.add('P2P: Banco de rotas seguras com $peerName atualizado.');
      }
    } catch (e) {
      _syncEventController.add('Erro na recepção dos dados P2P.');
    }
  }

  Future<bool> requestPermissions() async {
    final locStatus = await Permission.location.request();
    
    await [
      Permission.bluetooth,
      Permission.bluetoothAdvertise,
      Permission.bluetoothConnect,
      Permission.bluetoothScan,
      Permission.nearbyWifiDevices,
    ].request();

    // Retorna verdadeiro se a localização (essencial para o pareamento) estiver concedida.
    // Falhas de Bluetooth/Wi-Fi específicas da versão da API do Android são capturadas 
    // e tratadas no bloco try/catch do startSyncProcess.
    return locStatus.isGranted || locStatus.isLimited;
  }
}
