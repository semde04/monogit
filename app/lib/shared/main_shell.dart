import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';

class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final path = GoRouterState.of(context).uri.path;
    final index = path.startsWith('/claims') || path.startsWith('/chat')
        ? 1
        : path.startsWith('/profile') || path.startsWith('/admin')
        ? 2
        : 0;
    return Scaffold(
      body: child,
      backgroundColor: const Color(0xfff8f9f7),
      floatingActionButton: path == '/discover'
          ? FloatingActionButton.extended(
              onPressed: () => context.go('/items/new'),
              icon: const Icon(Icons.add),
              label: const Text('Publier'),
              elevation: 3,
            )
          : null,
      bottomNavigationBar: NavigationBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        height: 72,
        indicatorColor: const Color(0xffe3f1ec),
        selectedIndex: index,
        onDestinationSelected: (value) => context.go(switch (value) {
          0 => '/discover',
          1 => '/claims',
          _ => '/profile',
        }),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.travel_explore_outlined),
            selectedIcon: Icon(Icons.travel_explore),
            label: 'Explorer',
          ),
          NavigationDestination(
            icon: Icon(Icons.forum_outlined),
            selectedIcon: Icon(Icons.forum),
            label: 'Échanges',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}
