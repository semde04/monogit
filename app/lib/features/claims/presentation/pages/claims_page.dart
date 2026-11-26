import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../bloc/claims_bloc.dart';
import '../../domain/entities/claim.dart';

class ClaimsPage extends StatelessWidget {
  const ClaimsPage({super.key});
  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => getIt<ClaimsBloc>()..add(const ClaimsRequested()),
    child: const _ClaimsView(),
  );
}

class _ClaimsView extends StatelessWidget {
  const _ClaimsView();
  @override
  Widget build(BuildContext context) => BlocListener<ClaimsBloc, ClaimsState>(
    listenWhen: (a, b) => a.failure != b.failure && b.failure != null,
    listener: (context, state) =>
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(state.failure!.message))),
    child: Scaffold(
      appBar: AppBar(title: const Text('Mes échanges')),
      body: BlocBuilder<ClaimsBloc, ClaimsState>(
        builder: (context, state) {
          if (state.loading && state.claims.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.failure != null && state.claims.isEmpty) {
            return _CenteredMessage(
              message: state.failure!.message,
              action: TextButton.icon(
                onPressed: () =>
                    context.read<ClaimsBloc>().add(const ClaimsRequested()),
                icon: const Icon(Icons.refresh),
                label: const Text('Réessayer'),
              ),
            );
          }
          if (state.claims.isEmpty) {
            return const _CenteredMessage(
              message: 'Vos réclamations et conversations apparaîtront ici.',
            );
          }
          return RefreshIndicator(
            onRefresh: () async =>
                context.read<ClaimsBloc>().add(const ClaimsRequested()),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 28),
              itemCount: state.claims.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) => _ClaimCard(
                claim: state.claims[index],
                busy: state.busyId == state.claims[index].id,
              ),
            ),
          );
        },
      ),
    ),
  );
}

class _ClaimCard extends StatelessWidget {
  const _ClaimCard({required this.claim, required this.busy});
  final Claim claim;
  final bool busy;
  @override
  Widget build(BuildContext context) {
    final me = context.select<AuthBloc, String?>((bloc) => bloc.state.user?.id);
    final incoming = me != claim.claimantId;
    final status = switch (claim.status) {
      'accepted' => 'Acceptée',
      'rejected' => 'Refusée',
      'returned' => 'Objet restitué',
      _ => 'En attente',
    };
    final statusColor = switch (claim.status) {
      'accepted' => const Color(0xff236b5d),
      'returned' => const Color(0xff236b5d),
      'rejected' => const Color(0xffa34545),
      _ => const Color(0xff946222),
    };
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xffe1eee9),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    incoming ? Icons.inventory_2_outlined : Icons.search,
                    color: const Color(0xff236b5d),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        claim.itemTitle,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        incoming
                            ? 'Réclamation de ${claim.claimantName}'
                            : 'Votre réclamation',
                        style: Theme.of(context).textTheme.bodySmall
                            ?.copyWith(color: Colors.black54),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: .1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
            if (incoming && claim.proofAnswer.isNotEmpty) ...[
              const SizedBox(height: 14),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Text(
                claim.proofQuestion ?? 'Réponse à la question de vérification',
                style: Theme.of(context).textTheme.labelMedium
                    ?.copyWith(color: Colors.black54),
              ),
              const SizedBox(height: 5),
              Text(
                claim.proofAnswer,
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
            if (claim.status == 'accepted' || claim.status == 'returned') ...[
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 10),
              if (claim.status == 'returned')
                _ReturnReceipt(claim: claim)
              else ...[
                Text(
                  claim.ownerConfirmedReturn || claim.claimantConfirmedReturn
                      ? 'Une personne a confirmé la remise. La restitution sera enregistrée quand vous aurez tous les deux confirmé.'
                      : 'Après vous être mis d’accord par message et avoir remis l’objet, confirmez la remise ici.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (!claim.ownerConfirmedReturn ||
                    !claim.claimantConfirmedReturn) ...[
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: FilledButton.tonalIcon(
                      onPressed: busy
                          ? null
                          : () => context.read<ClaimsBloc>().add(
                              ClaimReturnConfirmed(claim.id),
                            ),
                      icon: const Icon(Icons.handshake_outlined),
                      label: Text(
                        _returnAction(
                          incoming: incoming,
                          itemType: claim.itemType,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ],
            const SizedBox(height: 12),
            if (incoming && claim.status == 'pending')
              Wrap(
                spacing: 10,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: busy
                        ? null
                        : () => context.read<ClaimsBloc>().add(
                            ClaimStatusChanged(claim.id, 'rejected'),
                          ),
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Refuser'),
                  ),
                  FilledButton.icon(
                    onPressed: busy
                        ? null
                        : () => context.read<ClaimsBloc>().add(
                            ClaimStatusChanged(claim.id, 'accepted'),
                          ),
                    icon: busy
                        ? const SizedBox.square(
                            dimension: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check, size: 18),
                    label: const Text('Accepter'),
                  ),
                ],
              )
            else if (claim.status == 'accepted' || claim.status == 'returned')
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => context.push('/chat/${claim.id}'),
                  icon: const Icon(Icons.chat_bubble_outline, size: 18),
                  label: Text(
                    claim.status == 'returned' ? 'Historique' : 'Discuter',
                  ),
                ),
              )
            else
              const Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'Discussion après acceptation',
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

String _returnAction({required bool incoming, required String itemType}) {
  final isFound = itemType == 'FOUND';
  final isFinder = incoming == isFound;
  return isFinder
      ? 'Confirmer que j’ai remis l’objet'
      : 'Confirmer que j’ai récupéré l’objet';
}

class _ReturnReceipt extends StatelessWidget {
  const _ReturnReceipt({required this.claim});
  final Claim claim;

  @override
  Widget build(BuildContext context) {
    final when = claim.returnedAt;
    final date = when == null
        ? 'Date non disponible'
        : '${when.day.toString().padLeft(2, '0')}/${when.month.toString().padLeft(2, '0')}/${when.year} à ${when.hour.toString().padLeft(2, '0')}:${when.minute.toString().padLeft(2, '0')}';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xffe7f3ee),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'RESTITUTION CONFIRMÉE',
            style: TextStyle(
              color: Color(0xff236b5d),
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: .4,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'L’objet « ${claim.itemTitle} » a été remis à ${claim.recipientName ?? (claim.itemType == 'FOUND' ? claim.claimantName : 'la personne propriétaire')}.',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 3),
          Text(
            'Confirmée le $date',
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
        ],
      ),
    );
  }
}

class _CenteredMessage extends StatelessWidget {
  const _CenteredMessage({required this.message, this.action});
  final String message;
  final Widget? action;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.forum_outlined, size: 46, color: Color(0xff8b9992)),
          const SizedBox(height: 14),
          Text(message, textAlign: TextAlign.center),
          if (action != null) ...[const SizedBox(height: 8), action!],
        ],
      ),
    ),
  );
}
