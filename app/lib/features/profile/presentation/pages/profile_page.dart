import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/notifications/push_notification_service.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});
  @override
  Widget build(BuildContext context) => BlocBuilder<AuthBloc, AuthState>(
    builder: (context, state) {
      final user = state.user;
      return Scaffold(
        appBar: AppBar(title: const Text('Mon profil')),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: const Color(0xffe1eee9),
                borderRadius: BorderRadius.circular(26),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 38,
                    backgroundColor: const Color(0xff236b5d),
                    child: Text(
                      (user?.name.isNotEmpty == true ? user!.name[0] : 'L')
                          .toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    user?.name ?? 'Utilisateur',
                    style: Theme.of(context).textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user?.email ?? '',
                    style: Theme.of(context).textTheme.bodyMedium
                        ?.copyWith(color: Colors.black54),
                  ),
                  if (user?.matricule != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Matricule : ${user!.matricule}',
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: Colors.black54),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Chip(
                    label: Text(
                      user?.role == 'admin' ? 'Administrateur' : 'Membre',
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            if (user?.role == 'admin') ...[
              Card(
                child: ListTile(
                  leading: const Icon(
                    Icons.admin_panel_settings_outlined,
                    color: Color(0xff087765),
                  ),
                  title: const Text(
                    'Espace d’administration',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: const Text('Comptes, annonces et modération'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.go('/admin'),
                ),
              ),
              const SizedBox(height: 10),
            ],
            const _ProfileInfo(
              icon: Icons.privacy_tip_outlined,
              title: 'Vos échanges sont privés',
              subtitle: 'Seuls les participants d’une réclamation peuvent lire leurs messages.',
            ),
            const SizedBox(height: 10),
            const _ProfileInfo(
              icon: Icons.shield_outlined,
              title: 'Vos coordonnées restent privées',
              subtitle: 'Aucune coordonnée personnelle n’est publiée dans les annonces.',
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () async {
                await getIt<PushNotificationService>()
                    .unregisterForCurrentUser();
                if (!context.mounted) return;
                context.read<AuthBloc>().add(const AuthLogoutRequested());
                context.go('/login');
              },
              icon: const Icon(Icons.logout),
              label: const Text('Se déconnecter'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xff9b3838),
                padding: const EdgeInsets.all(15),
              ),
            ),
          ],
        ),
      );
    },
  );
}

class _ProfileInfo extends StatelessWidget {
  const _ProfileInfo({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
  final IconData icon;
  final String title, subtitle;
  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      leading: Icon(icon, color: const Color(0xff236b5d)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(subtitle),
    ),
  );
}
