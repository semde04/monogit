import 'dart:convert';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../claims/presentation/bloc/claims_bloc.dart';
import '../../domain/entities/item.dart';
import '../bloc/items_bloc.dart';

class ItemDetailPage extends StatelessWidget {
  const ItemDetailPage({super.key, required this.id});
  final String id;
  @override
  Widget build(BuildContext context) => MultiBlocProvider(
    providers: [
      BlocProvider(
        create: (_) => getIt<ItemsBloc>()..add(ItemDetailRequested(id)),
      ),
      BlocProvider(create: (_) => getIt<ClaimsBloc>()),
    ],
    child: const _ItemDetailView(),
  );
}

class _ItemDetailView extends StatelessWidget {
  const _ItemDetailView();
  @override
  Widget build(BuildContext context) => BlocListener<ClaimsBloc, ClaimsState>(
    listenWhen: (a, b) =>
        a.created?.id != b.created?.id && b.created != null ||
        a.failure != b.failure && b.failure != null,
    listener: (context, state) {
      if (state.created != null) context.go('/claims');
      if (state.failure != null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(state.failure!.message)));
      }
    },
    child: BlocConsumer<ItemsBloc, ItemsState>(
      listenWhen: (a, b) => a.failure != b.failure && b.failure != null,
      listener: (context, state) =>
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(state.failure!.message))),
      builder: (context, state) {
        final item = state.selected;
        return Scaffold(
          appBar: AppBar(title: const Text('Détail de l’annonce')),
          body: state.loading && item == null
              ? const Center(child: CircularProgressIndicator())
              : item == null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(state.failure?.message ?? 'Annonce introuvable'),
                      TextButton(
                        onPressed: () => context.pop(),
                        child: const Text('Retour'),
                      ),
                    ],
                  ),
                )
              : _details(context, item),
        );
      },
    ),
  );

  Widget _details(BuildContext context, Item item) {
    final me = context.watch<AuthBloc>().state.user;
    final isOwner = me?.id == item.ownerId;
    final found = item.type == 'FOUND';
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      children: [
        Container(
          height: 220,
          decoration: BoxDecoration(
            color: found ? const Color(0xffe1eee9) : const Color(0xfff8eadc),
            borderRadius: BorderRadius.circular(26),
          ),
          clipBehavior: Clip.antiAlias,
          child: item.imageData != null
              ? Image.memory(
                  base64Decode(item.imageData!.split(',').last),
                  fit: BoxFit.cover,
                )
              : Icon(
                  _detailIcon(item.category),
                  size: 76,
                  color: found
                      ? const Color(0xff236b5d)
                      : const Color(0xffa96839),
                ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            _Tag(
              label: found ? 'OBJET TROUVÉ' : 'OBJET PERDU',
              color: found ? const Color(0xffe6f3ed) : const Color(0xffffeee2),
            ),
            const Spacer(),
            Text(
              _fullDate(item.createdAt),
              style: Theme.of(context).textTheme.labelMedium
                  ?.copyWith(color: Colors.black54),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          item.title,
          style: Theme.of(context).textTheme.headlineSmall
              ?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 14),
        _InfoLine(
          icon: Icons.place_outlined,
          label: 'Lieu',
          value: item.location,
        ),
        _InfoLine(
          icon: Icons.category_outlined,
          label: 'Catégorie',
          value: item.category,
        ),
        const SizedBox(height: 12),
        Text(
          'Description',
          style: Theme.of(context).textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Text(
          item.description,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.5),
        ),
        const SizedBox(height: 24),
        if (item.isClosed)
          const _Tag(label: 'OBJET RESTITUÉ', color: Color(0xffe5e7eb))
        else if (isOwner)
          FilledButton.icon(
            onPressed: () => context.read<ItemsBloc>().add(ItemClosed(item.id)),
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('Marquer comme restitué'),
          )
        else if (me != null)
          FilledButton.icon(
            onPressed: () => _showClaimDialog(context, item),
            icon: const Icon(Icons.volunteer_activism_outlined),
            label: const Text('Réclamer cet objet'),
          ),
      ],
    );
  }

  Future<void> _showClaimDialog(BuildContext context, Item item) async {
    final answer = await showDialog<String>(
      context: context,
      builder: (_) => _ClaimProofDialog(item: item),
    );
    if (answer != null && context.mounted) {
      context.read<ClaimsBloc>().add(ClaimCreated(item.id, answer));
    }
  }
}

class _ClaimProofDialog extends StatefulWidget {
  const _ClaimProofDialog({required this.item});
  final Item item;

  @override
  State<_ClaimProofDialog> createState() => _ClaimProofDialogState();
}

class _ClaimProofDialogState extends State<_ClaimProofDialog> {
  final _form = GlobalKey<FormState>();
  final _answer = TextEditingController();

  @override
  void dispose() {
    _answer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    scrollable: true,
    title: const Text('Prouvez que c’est le vôtre'),
    content: ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * .45,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.item.proofQuestion ?? 'Décrivez un détail que seul le propriétaire peut connaître.',
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _answer,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'Votre réponse'),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Une réponse est nécessaire.'
                    : null,
              ),
            ],
          ),
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Annuler'),
      ),
      FilledButton(
        onPressed: () {
          if (_form.currentState!.validate()) {
            Navigator.pop(context, _answer.text.trim());
          }
        },
        child: const Text('Envoyer'),
      ),
    ],
  );
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label, required this.color});
  final String label;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(30),
    ),
    child: Text(
      label,
      style: const TextStyle(
        fontSize: 10,
        letterSpacing: .6,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label, value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 13),
    child: Row(
      children: [
        Icon(icon, size: 19, color: const Color(0xff236b5d)),
        const SizedBox(width: 10),
        Text(
          '$label  ',
          style: Theme.of(context).textTheme.labelLarge
              ?.copyWith(color: Colors.black54),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.labelLarge
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ),
  );
}

IconData _detailIcon(String category) =>
    category.toLowerCase().contains('bag') ||
        category.toLowerCase().contains('sac')
    ? Icons.backpack_outlined
    : category.toLowerCase().contains('electron')
    ? Icons.devices_other
    : Icons.inventory_2_outlined;
String _fullDate(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
