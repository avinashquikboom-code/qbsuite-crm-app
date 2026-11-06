import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker_android/image_picker_android.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import '../core/services/notification_service.dart';
import '../core/network/app_url.dart';
import '../firebase_options.dart';
import 'app.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) =>
    NotificationService.backgroundHandler(message);

Future<void> bootstrap() async {
  SharedPreferences? prefs;
  final buildMode = kReleaseMode
      ? 'RELEASE'
      : kProfileMode
      ? 'PROFILE'
      : 'DEBUG';
  final environment = kReleaseMode ? 'production' : 'development';
  const appVersion = '1.0.2+6';

  debugPrint('==================================================');
  debugPrint('[DEVICE DEBUG]');
  debugPrint('Build Mode: $buildMode');
  debugPrint('API Base URL: ${AppUrl.baseUrl}');
  debugPrint('Environment: $environment');
  debugPrint('App Version: $appVersion');
  debugPrint('==================================================');

  debugPrint('[STARTUP] app initialization started');
  debugPrint('[STARTUP] main started');
  WidgetsFlutterBinding.ensureInitialized();

  // Configure ImagePicker to explicitly use Android Photo Picker (Google Play Policy Compliance)
  final ImagePickerPlatform imagePickerImplementation =
      ImagePickerPlatform.instance;
  if (imagePickerImplementation is ImagePickerAndroid) {
    imagePickerImplementation.useAndroidPhotoPicker = true;
  }

  // Safely initialize Firebase with timeout and fallback
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      ).timeout(
        const Duration(seconds: 3),
        onTimeout: () {
          debugPrint('🚨🔥 [FCM] Firebase.initializeApp timed out after 3s');
          return Firebase.apps.isNotEmpty ? Firebase.app() : null as dynamic;
        },
      );
    }
    debugPrint('🔥 [FCM] Firebase Initialized');
  } catch (e, st) {
    debugPrint('🚨🔥 [FCM] Firebase Initialization FAILED: $e');
    debugPrintStack(stackTrace: st);
  }

  // Register background handler once Firebase is ready
  if (Firebase.apps.isNotEmpty &&
      !NotificationService.isBackgroundHandlerRegistered) {
    try {
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      NotificationService.isBackgroundHandlerRegistered = true;
      debugPrint('[FCM] Background handler registered');
    } catch (e) {
      debugPrint('[FCM] Background handler registration warning: $e');
    }
  }

  // Launch notification service non-blockingly so main() never hangs
  try {
    unawaited(
      NotificationService.instance.initialize().catchError((e) {
        debugPrint('[STARTUP_ERROR] NotificationService.initialize error: $e');
      }),
    );
  } catch (e) {
    debugPrint('[STARTUP_ERROR] NotificationService launch error: $e');
  }
  debugPrint('[STARTUP] Flutter binding initialized');

  debugPrint('[STARTUP] Storage initialization started');
  try {
    prefs = await SharedPreferences.getInstance().timeout(
      const Duration(seconds: 2),
      onTimeout: () {
        debugPrint('[STARTUP_WARN] SharedPreferences timeout after 2s');
        return null as dynamic;
      },
    );
    debugPrint('[STARTUP] local storage initialized');
    debugPrint('[STARTUP] Storage initialization completed');
  } catch (e, st) {
    debugPrint('[STARTUP_ERROR] Storage error: $e');
    debugPrint('[STARTUP_ERROR] $st');
  }

  // Location service startup check (non-blocking, never blocks UI)
  debugPrint('[STARTUP] location initialization started');
  try {
    debugPrint('[STARTUP] location initialization completed');
  } catch (e) {
    debugPrint('[STARTUP_ERROR] Location initialization error: $e');
    debugPrint('[STARTUP] location initialization completed');
  }

  try {
    await SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.edgeToEdge,
      overlays: SystemUiOverlay.values,
    );

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
  } catch (e) {
    debugPrint('[STARTUP_ERROR] SystemUI error: $e');
  }

  debugPrint('[STARTUP] initialization completed');
  runApp(ProviderScope(child: MyApp(preferences: prefs)));
  debugPrint('[STARTUP] runApp completed');
}
