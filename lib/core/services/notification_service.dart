import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// **NotificationService (Model/Service)**
///
/// Serviço encarregado pelo acionamento de notificações locais no sistema operacional (Android e iOS).
/// Mantém o ciclista informado com notificações flutuantes (Heads-Up) e em segundo plano de forma contínua (RF003).
class NotificationService {
  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  /// Inicializa e configura os canais de notificação nativos e solicita as permissões necessárias.
  Future<void> init() async {
    if (_initialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(
      settings: initSettings,
    );

    // Solicitar permissões no Android 13+ (SDK 33+)
    final androidImplementation = _notificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidImplementation != null) {
      await androidImplementation.requestNotificationsPermission();
    }

    _initialized = true;
  }

  /// Dispara e exibe uma notificação do sistema operacional de forma imediata.
  ///
  /// Parâmetros:
  /// - [id]: Identificador numérico exclusivo da notificação (`int`).
  /// - [title]: Rótulo de título em negrito da notificação (`String`).
  /// - [body]: Corpo textual descritivo detalhado (`String`).
  /// - [ongoing]: Determina se a notificação é persistente/não-removível pelo usuário (`bool`).
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    bool ongoing = false,
  }) async {
    await init();

    final androidDetails = AndroidNotificationDetails(
      'rastro_channel_id_v2',
      'Rastro Navegação',
      channelDescription: 'Canal de instruções de navegação em tempo real do Rastro',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      ongoing: ongoing,
      autoCancel: !ongoing,
      onlyAlertOnce: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notificationsPlugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: details,
    );
  }

  /// Cancela e remove uma notificação ativa específica com base em seu identificador único.
  ///
  /// Parâmetros:
  /// - [id]: O identificador numérico da notificação a ser cancelada (`int`).
  Future<void> cancel(int id) async {
    await _notificationsPlugin.cancel(id: id);
  }

  /// Cancela e remove instantaneamente todas as notificações ativas emitidas pelo Rastro.
  Future<void> cancelAll() async {
    await _notificationsPlugin.cancelAll();
  }
}

/// Provedor Riverpod (ViewModel/Service Provider) que expõe o Singleton de `NotificationService`.
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});
