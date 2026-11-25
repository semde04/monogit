import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/claims/presentation/pages/claims_page.dart';
import '../../features/items/presentation/pages/create_item_page.dart';
import '../../features/items/presentation/pages/item_detail_page.dart';
import '../../features/items/presentation/pages/items_page.dart';
import '../../features/messages/presentation/pages/chat_page.dart';
import '../../features/moderation/presentation/pages/admin_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../shared/main_shell.dart';

class _AuthRefresh extends ChangeNotifier {
  _AuthRefresh(AuthBloc bloc) {
    _subscription = bloc.stream.listen((_) => notifyListeners());
  }
  late final StreamSubscription<AuthState> _subscription;
  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

GoRouter createAppRouter(AuthBloc auth) => GoRouter(
  initialLocation: '/splash',
  refreshListenable: _AuthRefresh(auth),
  redirect: (context, state) {
    final authState = auth.state;
    final path = state.uri.path;
    final isPublic =
        path == '/login' || path == '/register' || path == '/splash';
    if (authState.status == AuthStatus.checking) {
      return path == '/splash' ? null : '/splash';
    }
    if (authState.status == AuthStatus.unauthenticated) {
      return isPublic && path != '/splash' ? null : '/login';
    }
    if (path == '/admin' && authState.user?.role != 'admin') {
      return '/discover';
    }
    if (isPublic) return '/discover';
    return null;
  },
  routes: [
    GoRoute(path: '/splash', builder: (context, state) => const _SplashPage()),
    GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterPage(),
    ),
    ShellRoute(
      builder: (context, state, child) => MainShell(child: child),
      routes: [
        GoRoute(
          path: '/discover',
          builder: (context, state) => const ItemsPage(),
        ),
        GoRoute(
          path: '/claims',
          builder: (context, state) => const ClaimsPage(),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfilePage(),
        ),
        GoRoute(
          path: '/admin',
          builder: (context, state) => const AdminPage(),
        ),
        GoRoute(
          path: '/items/new',
          builder: (context, state) => const CreateItemPage(),
        ),
        GoRoute(
          path: '/items/:id',
          builder: (context, state) =>
              ItemDetailPage(id: state.pathParameters['id']!),
        ),
        GoRoute(
          path: '/chat/:claimId',
          builder: (context, state) =>
              ChatPage(claimId: state.pathParameters['claimId']!),
        ),
      ],
    ),
  ],
);

class _SplashPage extends StatelessWidget {
  const _SplashPage();
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: CircularProgressIndicator()));
}
