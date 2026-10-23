import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Notificaciones locales (aparecen en la barra del teléfono).
class NotificacionService {
  NotificacionService._();
  static final NotificacionService instance = NotificacionService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _listo = false;

  Future<void> init() async {
    if (_listo) return;
    try {
      const android = AndroidInitializationSettings('@mipmap/ic_launcher');
      await _plugin.initialize(
        settings: const InitializationSettings(android: android),
      );
      final impl = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      // Android 13+ pide permiso en tiempo de ejecución.
      await impl?.requestNotificationsPermission();
      _listo = true;
    } catch (e) {
      debugPrint('No se pudieron iniciar las notificaciones: $e');
    }
  }

  Future<void> mostrar({
    required int id,
    required String titulo,
    required String cuerpo,
  }) async {
    if (!_listo) return;
    try {
      const detalles = NotificationDetails(
        android: AndroidNotificationDetails(
          'stock_bajo',
          'Alertas de stock',
          channelDescription: 'Avisos cuando un producto llega a su mínimo',
          importance: Importance.high,
          priority: Priority.high,
        ),
      );
      await _plugin.show(
        id: id,
        title: titulo,
        body: cuerpo,
        notificationDetails: detalles,
      );
    } catch (e) {
      debugPrint('No se pudo mostrar la notificación: $e');
    }
  }
}
