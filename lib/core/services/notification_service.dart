import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum NotificationType { info, route, alert, success }

class NotificationModel {
  final String id;
  final String title;
  final String body;
  final NotificationType type;
  final DateTime timestamp;

  NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    this.type = NotificationType.info,
    required this.timestamp,
  });
}

class NotificationNotifier extends StateNotifier<NotificationModel?> {
  NotificationNotifier() : super(null);

  final List<NotificationModel> _history = [];
  List<NotificationModel> get history => List.unmodifiable(_history);

  final _historyController = StreamController<List<NotificationModel>>.broadcast();
  Stream<List<NotificationModel>> get historyStream => _historyController.stream;

  void showNotification({
    required String title,
    required String body,
    NotificationType type = NotificationType.info,
  }) {
    final notification = NotificationModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      body: body,
      type: type,
      timestamp: DateTime.now(),
    );

    _history.insert(0, notification);
    if (_history.length > 50) {
      _history.removeLast();
    }
    _historyController.add(_history);

    // Atualiza o estado da notificação ativa (para o banner de overlay)
    state = notification;

    // Fecha automaticamente o banner após 5 segundos
    Future.delayed(const Duration(seconds: 5), () {
      if (state?.id == notification.id) {
        state = null;
      }
    });
  }

  void clearActive() {
    state = null;
  }

  void clearHistory() {
    _history.clear();
    _historyController.add(_history);
  }
}

final notificationProvider = StateNotifierProvider<NotificationNotifier, NotificationModel?>((ref) {
  return NotificationNotifier();
});
