import 'dart:convert';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../domain/entities/admin_overview.dart';
import '../bloc/moderation_bloc.dart';

class AdminPage extends StatelessWidget {
  const AdminPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => getIt<ModerationBloc>()..add(const AdminOverviewRequested()),
    child: const _AdminView(),
  );
}

class _AdminView extends StatelessWidget {
  const _AdminView();

  @override
  Widget build(
    BuildContext context,
  ) => BlocListener<ModerationBloc, ModerationState>(
    listenWhen: (previous, current) =>
        previous.failure != current.failure && current.failure != null,
    listener: (context, state) =>
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(state.failure!.message))),
    child: Scaffold(
      appBar: AppBar(
        title: const Text('Supervision'),
        actions: [
          IconButton(
            tooltip: 'Actualiser',
            onPressed: () => context.read<ModerationBloc>().add(
              const AdminOverviewRequested(),
            ),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: BlocBuilder<ModerationBloc, ModerationState>(
        builder: (context, state) {
          final overview = state.overview;
          if (state.loading && overview == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (overview == null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(state.failure?.message ?? 'Données indisponibles.'),
                  const SizedBox(height: 8),
                  FilledButton.tonal(
                    onPressed: () => context.read<ModerationBloc>().add(
                      const AdminOverviewRequested(),
                    ),
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => context.read<ModerationBloc>().add(
              const AdminOverviewRequested(),
            ),
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1280),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
                  children: [
                    Text(
                      'Portail web de supervision',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xff087765),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Vue générale',
                      style: Theme.of(context).textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _Metric(label: 'Comptes', value: overview.userCount),
                        _Metric(label: 'Annonces', value: overview.itemCount),
                        _Metric(
                          label: 'Réclamations',
                          value: overview.claimCount,
                        ),
                        _Metric(
                          label: 'En attente',
                          value: overview.pendingClaimCount,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Annonces récentes',
                      style: Theme.of(context).textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 10),
                    if (overview.items.isEmpty)
                      const _HintCard(
                        message: 'Aucune annonce publiée pour le moment.',
                      )
                    else
                      ...overview.items.map(
                        (item) => _ModerationItemCard(
                          item: item,
                          busy: state.busyItemId == item.id,
                        ),
                      ),
                    const SizedBox(height: 20),
                    Text(
                      'Étudiants et comptes inscrits (${overview.users.length})',
                      style: Theme.of(context).textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 10),
                    if (overview.users.isEmpty)
                      const _HintCard(message: 'Aucun compte inscrit.')
                    else
                      ...overview.users.map((user) => _UserCard(user: user)),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    ),
  );
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: (MediaQuery.sizeOf(context).width - 46) / 2,
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 4),
            Text(
              '$value',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: const Color(0xff087765),
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _ModerationItemCard extends StatelessWidget {
  const _ModerationItemCard({required this.item, required this.busy});
  final AdminItemSummary item;
  final bool busy;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (item.imageData != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: SizedBox(
                height: 150,
                width: double.infinity,
                child: Image.memory(
                  base64Decode(item.imageData!.split(',').last),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          if (item.imageData != null) const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  item.title,
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              Chip(
                label: Text(item.isRemoved ? 'Masquée' : 'Visible'),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(item.description, maxLines: 3, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 8),
          Text(
            '${item.ownerName} · Matricule ${item.ownerMatricule}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          Text(
            item.location,
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: Colors.black54),
          ),
          if (item.moderationReason != null) ...[
            const SizedBox(height: 6),
            Text(
              'Motif : ${item.moderationReason}',
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: const Color(0xff9b3838)),
            ),
          ],
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: busy
                  ? null
                  : () => item.isRemoved
                        ? context.read<ModerationBloc>().add(
                            AdminItemModerationChanged(
                              itemId: item.id,
                              isRemoved: false,
                            ),
                          )
                        : _requestRemoval(context, item),
              icon: busy
                  ? const SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(item.isRemoved ? Icons.restore : Icons.visibility_off),
              label: Text(item.isRemoved ? 'Rétablir' : 'Masquer l’annonce'),
            ),
          ),
        ],
      ),
    ),
  );

  Future<void> _requestRemoval(
    BuildContext context,
    AdminItemSummary item,
  ) async {
    final reasonController = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Masquer cette annonce ?'),
        content: TextField(
          controller: reasonController,
          autofocus: true,
          minLines: 2,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: 'Motif du retrait',
            hintText: 'Expliquez brièvement la décision',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(dialogContext, reasonController.text.trim()),
            child: const Text('Masquer'),
          ),
        ],
      ),
    );
    reasonController.dispose();
    if (reason == null || reason.trim().length < 3 || !context.mounted) return;
    context.read<ModerationBloc>().add(
      AdminItemModerationChanged(
        itemId: item.id,
        isRemoved: true,
        reason: reason.trim(),
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  const _UserCard({required this.user});
  final AdminUserSummary user;

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      leading: CircleAvatar(
        child: Text(user.name.isEmpty ? '?' : user.name[0].toUpperCase()),
      ),
      title: Text(user.name),
      subtitle: Text('${user.email}\nMatricule : ${user.matricule}'),
      isThreeLine: true,
      trailing: Text(user.role == 'admin' ? 'Admin' : 'Étudiant'),
    ),
  );
}

class _HintCard extends StatelessWidget {
  const _HintCard({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Text(message, textAlign: TextAlign.center),
    ),
  );
}
