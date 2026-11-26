import 'dart:async';

import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';

final rootScaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

class PushNotificationService {
  PushNotificationService(this._dio);
  final Dio _dio;
  StreamSubscription<String>? _installationSubscription;
  StreamSubscription<RemoteMessage>? _messageSubscription;
  StreamSubscription<RemoteMessage>? _openedSubscription;
  String? _installationId;
  bool _syncing = false;

  bool get _supported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  void initialize({void Function(RemoteMessage message)? onNotificationTap}) {
    if (!_supported) return;
    _messageSubscription ??= FirebaseMessaging.onMessage.listen((message) {
      final title = message.notification?.title ?? 'LostFound';
      final body =
          message.notification?.body ?? 'Vous avez une nouvelle notification.';
      rootScaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text('$title : $body')),
      );
    });
    if (onNotificationTap != null) {
      _openedSubscription ??= FirebaseMessaging.onMessageOpenedApp.listen(
        onNotificationTap,
      );
    }
  }

  Future<bool> initialNotificationIsClaim() async {
    if (!_supported) return false;
    try {
      final message = await FirebaseMessaging.instance.getInitialMessage();
      return message?.data['type'] == 'claim';
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, String>?> initialNotificationData() async {
    if (!_supported) return null;
    try {
      final message = await FirebaseMessaging.instance.getInitialMessage();
      return message == null ? null : Map<String, String>.from(message.data);
    } catch (_) {
      return null;
    }
  }

  Future<void> registerForCurrentUser() async {
    if (!_supported || _syncing) return;
    _syncing = true;
    try {
      final settings = await FirebaseMessaging.instance.requestPermission();
      if (settings.authorizationStatus == AuthorizationStatus.denied) return;

      final messaging = FirebaseMessaging.instance;
      _installationSubscription ??= messaging.onRegistered.listen((fid) {
        _installationId = fid;
        unawaited(_saveInstallationId(fid));
      });
      await messaging.register();
    } catch (_) {
      // Push notifications are optional and must not block sign-in.
    } finally {
      _syncing = false;
    }
  }

  Future<void> unregisterForCurrentUser() async {
    if (!_supported) return;
    await _installationSubscription?.cancel();
    _installationSubscription = null;
    try {
      final installationId = _installationId;
      if (installationId != null) {
        await _dio.delete<void>(
          '/auth/device-installation',
          data: {'installationId': installationId},
        );
      }
      _installationId = null;
    } catch (_) {
      // A failed unregister must not prevent the user from signing out.
    }
  }

  Future<void> _saveInstallationId(String installationId) async {
    try {
      await _dio.put<void>(
        '/auth/device-installation',
        data: {'installationId': installationId},
      );
    } catch (_) {
      // The next sign-in or token refresh will retry registration.
    }
  }
}
