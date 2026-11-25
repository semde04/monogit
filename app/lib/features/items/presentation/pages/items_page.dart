import 'dart:convert';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/item.dart';
import '../bloc/items_bloc.dart';

class ItemsPage extends StatelessWidget {
  const ItemsPage({super.key});
  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => getIt<ItemsBloc>()..add(const ItemsRequested()),
    child: const _ItemsView(),
  );
}

class _ItemsView extends StatefulWidget {
  const _ItemsView();
  @override
  State<_ItemsView> createState() => _ItemsViewState();
}

class _ItemsViewState extends State<_ItemsView> {
  final _search = TextEditingController();
  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => BlocBuilder<ItemsBloc, ItemsState>(
    builder: (context, state) => RefreshIndicator(
      onRefresh: () async =>
          context.read<ItemsBloc>().add(const ItemsRequested()),
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'LOSTFOUND',
                              style: Theme.of(context).textTheme.labelMedium
                                  ?.copyWith(
                                    letterSpacing: 2,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primary,
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Retrouvons\nce qui compte.',
                              style: Theme.of(context).textTheme.headlineMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    height: 1.05,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xffe1eee9),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.volunteer_activism_outlined,
                          color: Color(0xff236b5d),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _search,
                    onChanged: (value) =>
                        context.read<ItemsBloc>().add(ItemSearchChanged(value)),
                    decoration: const InputDecoration(
                      hintText: 'Chercher un objet, un lieu…',
                      prefixIcon: Icon(Icons.search),
                      suffixIcon: Icon(Icons.tune),
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 42,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _FilterChip(
                          label: 'Tout',
                          selected: state.category == null,
                          onTap: () => _filter(context, null),
                        ),
                        _FilterChip(
                          label: 'Sacs',
                          selected: state.category == 'BAGS',
                          onTap: () => _filter(context, 'BAGS'),
                        ),
                        _FilterChip(
                          label: 'Électronique',
                          selected: state.category == 'ELECTRONICS',
                          onTap: () => _filter(context, 'ELECTRONICS'),
                        ),
                        _FilterChip(
                          label: 'Vêtements',
                          selected: state.category == 'CLOTHING',
                          onTap: () => _filter(context, 'CLOTHING'),
                        ),
                        _FilterChip(
                          label: 'Autre',
                          selected: state.category == 'OTHER',
                          onTap: () => _filter(context, 'OTHER'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Text(
                        'Récemment signalés',
                        style: Theme.of(context).textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const Spacer(),
                      PopupMenuButton<String?>(
                        tooltip: 'Filtrer par type',
                        onSelected: (value) => context.read<ItemsBloc>().add(
                          ItemFiltersChanged(
                            category: state.category,
                            type: value,
                          ),
                        ),
                        itemBuilder: (_) => const [
                          PopupMenuItem(value: null, child: Text('Tous')),
                          PopupMenuItem(value: 'LOST', child: Text('Perdus')),
                          PopupMenuItem(value: 'FOUND', child: Text('Trouvés')),
                        ],
                        child: const Padding(
                          padding: EdgeInsets.all(8),
                          child: Row(
                            children: [
                              Text('Type'),
                              SizedBox(width: 4),
                              Icon(Icons.keyboard_arrow_down),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${state.items.length} annonce${state.items.length == 1 ? '' : 's'}',
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: Colors.black54),
                  ),
                ],
              ),
            ),
          ),
          if (state.failure != null && state.items.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _FailureView(
                failure: state.failure!,
                onRetry: () =>
                    context.read<ItemsBloc>().add(const ItemsRequested()),
              ),
            )
          else if (state.loading && state.items.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: CircularProgressIndicator()),
            )
          else if (state.items.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: _EmptyItems(),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 96),
              sliver: SliverList.separated(
                itemCount: state.items.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) => _ItemCard(
                  item: state.items[index],
                  onTap: () => context.push('/items/${state.items[index].id}'),
                ),
              ),
            ),
        ],
      ),
    ),
  );

  void _filter(BuildContext context, String? category) =>
      context.read<ItemsBloc>().add(
        ItemFiltersChanged(
          category: category,
          type: context.read<ItemsBloc>().state.type,
        ),
      );
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(right: 8),
    child: ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
    ),
  );
}

class _ItemCard extends StatelessWidget {
  const _ItemCard({required this.item, required this.onTap});
  final Item item;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final found = item.type == 'FOUND';
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 86,
                height: 92,
                decoration: BoxDecoration(
                  color: found
                      ? const Color(0xffe1eee9)
                      : const Color(0xfff8eadc),
                  borderRadius: BorderRadius.circular(17),
                ),
                clipBehavior: Clip.antiAlias,
                child: item.imageData != null
                    ? Image.memory(
                        base64Decode(item.imageData!.split(',').last),
                        fit: BoxFit.cover,
                      )
                    : Icon(
                        _categoryIcon(item.category),
                        size: 34,
                        color: found
                            ? const Color(0xff236b5d)
                            : const Color(0xffa96839),
                      ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: found
                                ? const Color(0xffe6f3ed)
                                : const Color(0xffffeee2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            found ? 'TROUVÉ' : 'PERDU',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: .6,
                              color: found
                                  ? const Color(0xff236b5d)
                                  : const Color(0xffa96839),
                            ),
                          ),
                        ),
                        const Spacer(),
                        const Icon(
                          Icons.more_horiz,
                          size: 19,
                          color: Colors.black45,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      item.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(height: 1.35, color: Colors.black54),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(
                          Icons.place_outlined,
                          size: 15,
                          color: Color(0xff68736e),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            item.location,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.labelMedium,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _date(item.createdAt),
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(color: Colors.black45),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

IconData _categoryIcon(String category) {
  final value = category.toLowerCase();
  if (value.contains('bag') || value.contains('sac')) {
    return Icons.backpack_outlined;
  }
  if (value.contains('electron') || value.contains('phone')) {
    return Icons.devices_other;
  }
  if (value.contains('cloth') || value.contains('vet')) {
    return Icons.checkroom_outlined;
  }
  if (value.contains('key')) return Icons.key_outlined;
  return Icons.inventory_2_outlined;
}

String _date(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';

class _EmptyItems extends StatelessWidget {
  const _EmptyItems();
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(36),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.search_off_rounded,
            size: 50,
            color: Color(0xff8b9992),
          ),
          const SizedBox(height: 16),
          Text(
            'Rien pour le moment',
            style: Theme.of(context).textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          const Text(
            'Les nouvelles annonces apparaîtront ici. Vous pouvez aussi publier un objet retrouvé.',
          ),
        ],
      ),
    ),
  );
}

class _FailureView extends StatelessWidget {
  const _FailureView({required this.failure, required this.onRetry});
  final Failure failure;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.wifi_off_rounded,
            size: 46,
            color: Color(0xff8b9992),
          ),
          const SizedBox(height: 14),
          Text(failure.message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Réessayer'),
          ),
        ],
      ),
    ),
  );
}
