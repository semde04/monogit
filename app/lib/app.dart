import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/di/injection.dart';
import 'core/notifications/push_notification_service.dart';
import 'core/router/app_router.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';

class LostFoundApp extends StatefulWidget {
  const LostFoundApp({super.key});
  @override
  State<LostFoundApp> createState() => _LostFoundAppState();
}

class _LostFoundAppState extends State<LostFoundApp> {
  late final AuthBloc _auth = getIt<AuthBloc>();
  late final _router = createAppRouter(_auth);
  late final StreamSubscription<AuthState> _authSubscription;
  String? _pendingNotificationPath;

  @override
  void initState() {
    super.initState();
    getIt<PushNotificationService>().initialize(
      onNotificationTap: (message) {
        final path = _notificationPath(message.data);
        if (_auth.state.status == AuthStatus.authenticated) {
          _router.go(path);
        } else {
          _pendingNotificationPath = path;
        }
      },
    );
    _authSubscription = _auth.stream.listen((state) {
      if (state.status == AuthStatus.authenticated) {
        unawaited(getIt<PushNotificationService>().registerForCurrentUser());
        if (_pendingNotificationPath case final path?) {
          _pendingNotificationPath = null;
          _router.go(path);
        }
      }
    });
    if (_auth.state.status == AuthStatus.authenticated) {
      unawaited(getIt<PushNotificationService>().registerForCurrentUser());
    }
    unawaited(_handleInitialNotification());
  }

  Future<void> _handleInitialNotification() async {
    final data = await getIt<PushNotificationService>()
        .initialNotificationData();
    if (data == null || !mounted) return;
    final path = _notificationPath(data);
    if (_auth.state.status == AuthStatus.authenticated) {
      _router.go(path);
    } else {
      _pendingNotificationPath = path;
    }
  }

  String _notificationPath(Map<String, dynamic> data) {
    final itemId = data['itemId']?.toString();
    if (data['type'] == 'possible_match' &&
        itemId != null &&
        itemId.isNotEmpty) {
      return '/items/$itemId';
    }
    return '/claims';
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => BlocProvider.value(
    value: _auth,
    child: MaterialApp.router(
      title: 'LostFound',
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: rootScaffoldMessengerKey,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xff087765),
          primary: const Color(0xff087765),
          surface: const Color(0xfff8f9f7),
        ),
        scaffoldBackgroundColor: const Color(0xfff8f9f7),
        textTheme: ThemeData.light().textTheme.apply(
          bodyColor: const Color(0xff202624),
          displayColor: const Color(0xff202624),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xfff8f9f7),
          centerTitle: false,
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 18,
          ),
          labelStyle: const TextStyle(color: Color(0xff58625e)),
          hintStyle: const TextStyle(color: Color(0xff909995)),
          prefixIconColor: const Color(0xff53605b),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: Color(0xffe3e8e4)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: Color(0xffe3e8e4)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: Color(0xff087765), width: 1.5),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(54),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            textStyle: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(0, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
            side: const BorderSide(color: Color(0xffe8ece9)),
          ),
        ),
      ),
      routerConfig: _router,
    ),
  );
}
