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
      _ => 'En attente',
    };
    final statusColor = switch (claim.status) {
      'accepted' => const Color(0xff236b5d),
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
            const SizedBox(height: 12),
            Row(
              children: [
                if (incoming && claim.status == 'pending') ...[
                  OutlinedButton(
                    onPressed: busy
                        ? null
                        : () => context.read<ClaimsBloc>().add(
                            ClaimStatusChanged(claim.id, 'rejected'),
                          ),
                    child: const Text('Refuser'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: busy
                        ? null
                        : () => context.read<ClaimsBloc>().add(
                            ClaimStatusChanged(claim.id, 'accepted'),
                          ),
                    child: busy
                        ? const SizedBox.square(
                            dimension: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Accepter'),
                  ),
                  const Spacer(),
                ] else
                  const Spacer(),
                TextButton.icon(
                  onPressed: () => context.push('/chat/${claim.id}'),
                  icon: const Icon(Icons.chat_bubble_outline, size: 18),
                  label: const Text('Message'),
                ),
              ],
            ),
          ],
        ),
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
