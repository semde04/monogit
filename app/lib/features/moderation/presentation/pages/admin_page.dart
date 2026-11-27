import 'dart:convert';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../domain/entities/admin_activity.dart';
import '../../domain/entities/admin_overview.dart';
import '../bloc/moderation_bloc.dart';

const _brand = Color(0xff087765);
const _brandSoft = Color(0xffe3f1ec);
const _ink = Color(0xff202624);
const _muted = Color(0xff58625e);
const _line = Color(0xffe8ece9);
const _surface = Color(0xfff6f8f7);
const _danger = Color(0xff9b3838);
const _dangerSoft = Color(0xfff7e7e7);
const _warning = Color(0xff9a6100);
const _warningSoft = Color(0xfff4ead6);

class AdminPage extends StatelessWidget {
  const AdminPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) {
      final bloc = getIt<ModerationBloc>()..add(const AdminOverviewRequested());
      bloc.add(const AdminActivityRequested());
      return bloc;
    },
    child: const _AdminView(),
  );
}

void _refreshAll(BuildContext context) {
  final bloc = context.read<ModerationBloc>();
  bloc
    ..add(const AdminOverviewRequested())
    ..add(const AdminActivityRequested());
}

const _activityFilters = <String?, String>{
  null: 'Tout',
  'auth.register': 'Comptes',
  'item.created': 'Annonces',
  'claim.created': 'Réclamations',
  'message.sent': 'Messages',
  'admin.moderation': 'Modération',
};

const _navItems = <_NavItem>[
  _NavItem(Icons.dashboard_outlined, 'Vue d’ensemble'),
  _NavItem(Icons.timeline_outlined, 'Activité'),
  _NavItem(Icons.inventory_2_outlined, 'Annonces'),
  _NavItem(Icons.people_outline, 'Comptes'),
];

String _formatDate(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year} '
    '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';

String _activityLabel(String type) =>
    _activityFilters[type] ??
    switch (type) {
      'auth.login' => 'Connexions',
      'item.updated' || 'item.closed' || 'item.deleted' => 'Annonces',
      'claim.status' || 'claim.returned' => 'Réclamations',
      _ => 'Autre',
    };

IconData _activityIcon(String type) => switch (type) {
  'auth.register' || 'auth.login' => Icons.person_add_outlined,
  'item.created' ||
  'item.updated' ||
  'item.closed' ||
  'item.deleted' => Icons.inventory_2_outlined,
  'claim.created' ||
  'claim.status' ||
  'claim.returned' => Icons.assignment_turned_in_outlined,
  'message.sent' => Icons.chat_bubble_outline,
  'admin.moderation' => Icons.shield_outlined,
  _ => Icons.bolt_outlined,
};

_Tone _activityTone(String type) => switch (type) {
  'auth.register' || 'auth.login' => const _Tone(_brandSoft, _brand),
  'item.created' ||
  'item.updated' ||
  'item.closed' ||
  'item.deleted' => const _Tone(Color(0xffe9f1fb), Color(0xff2563a6)),
  'claim.created' ||
  'claim.status' ||
  'claim.returned' => const _Tone(_warningSoft, _warning),
  'message.sent' => const _Tone(Color(0xfff0ebfa), Color(0xff6b45a8)),
  'admin.moderation' => const _Tone(_dangerSoft, _danger),
  _ => const _Tone(_surface, _muted),
};

_Tone _roleTone(String role) => role == 'admin'
    ? const _Tone(_brandSoft, _brand)
    : const _Tone(_surface, _muted);

_Tone _statusTone(bool removed) => removed
    ? const _Tone(_dangerSoft, _danger)
    : const _Tone(_brandSoft, _brand);

class _NavItem {
  const _NavItem(this.icon, this.label);
  final IconData icon;
  final String label;
}

class _Tone {
  const _Tone(this.background, this.foreground);
  final Color background;
  final Color foreground;
}

class _AdminView extends StatefulWidget {
  const _AdminView();

  @override
  State<_AdminView> createState() => _AdminViewState();
}

class _AdminViewState extends State<_AdminView> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  final _overviewKey = GlobalKey();
  final _activityKey = GlobalKey();
  final _itemsKey = GlobalKey();
  final _usersKey = GlobalKey();

  late final List<GlobalKey> _sectionKeys = [
    _overviewKey,
    _activityKey,
    _itemsKey,
    _usersKey,
  ];

  int _selectedIndex = 0;
  String _query = '';

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _selectDestination(int index) {
    setState(() => _selectedIndex = index);
    final context = _sectionKeys[index].currentContext;
    if (context == null) return;
    Scrollable.ensureVisible(
      context,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
      alignment: 0.02,
    );
  }

  void _updateSearch(String value) =>
      setState(() => _query = value.trim().toLowerCase());

  void _clearSearch() {
    _searchController.clear();
    _updateSearch('');
  }

  List<AdminItemSummary> _filterItems(List<AdminItemSummary> items) {
    if (_query.isEmpty) return items;
    return items.where((item) {
      return [
        item.title,
        item.description,
        item.location,
        item.ownerName,
        item.type,
      ].any((value) => value.toLowerCase().contains(_query));
    }).toList();
  }

  List<AdminUserSummary> _filterUsers(List<AdminUserSummary> users) {
    if (_query.isEmpty) return users;
    return users.where((user) {
      return [
        user.name,
        user.email,
        user.matricule,
        user.role,
      ].any((value) => value.toLowerCase().contains(_query));
    }).toList();
  }

  @override
  Widget build(BuildContext context) =>
      BlocListener<ModerationBloc, ModerationState>(
        listenWhen: (previous, current) =>
            previous.failure != current.failure && current.failure != null,
        listener: (context, state) =>
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(state.failure!.message))),
        child: Scaffold(
          appBar: _buildAppBar(context),
          body: LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 1080;
              return BlocBuilder<ModerationBloc, ModerationState>(
                builder: (context, state) => wide
                    ? Row(
                        children: [
                          _buildRail(),
                          const VerticalDivider(width: 1, color: _line),
                          Expanded(child: _buildState(context, state)),
                        ],
                      )
                    : _buildState(context, state),
              );
            },
          ),
          bottomNavigationBar: LayoutBuilder(
            builder: (context, constraints) => constraints.maxWidth >= 1080
                ? const SizedBox.shrink()
                : NavigationBar(
                    selectedIndex: _selectedIndex,
                    onDestinationSelected: _selectDestination,
                    backgroundColor: Colors.white,
                    destinations: [
                      for (final item in _navItems)
                        NavigationDestination(
                          icon: Icon(item.icon),
                          label: item.label,
                        ),
                    ],
                  ),
          ),
        ),
      );

  PreferredSizeWidget _buildAppBar(BuildContext context) => AppBar(
    titleSpacing: 16,
    title: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: _brandSoft,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.admin_panel_settings_outlined,
            color: _brand,
            size: 21,
          ),
        ),
        const SizedBox(width: 11),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'LostFound Admin',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
            ),
            Text(
              'Centre de supervision',
              style: TextStyle(color: _muted, fontSize: 11),
            ),
          ],
        ),
      ],
    ),
    actions: [
      const _LiveBadge(),
      IconButton(
        tooltip: 'Actualiser',
        onPressed: () => _refreshAll(context),
        icon: const Icon(Icons.refresh_outlined),
      ),
      const SizedBox(width: 10),
    ],
  );

  Widget _buildRail() => NavigationRail(
    selectedIndex: _selectedIndex,
    onDestinationSelected: _selectDestination,
    labelType: NavigationRailLabelType.all,
    backgroundColor: Colors.white,
    groupAlignment: -0.85,
    minWidth: 92,
    extended: false,
    destinations: [
      for (final item in _navItems)
        NavigationRailDestination(
          icon: Icon(item.icon),
          label: Text(item.label),
        ),
    ],
  );

  Widget _buildState(BuildContext context, ModerationState state) {
    final overview = state.overview;
    if (state.loading && overview == null) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 14),
            Text(
              'Chargement du tableau de bord…',
              style: TextStyle(color: _muted),
            ),
          ],
        ),
      );
    }
    if (overview == null) {
      return Center(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(30),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cloud_off_outlined, size: 40, color: _danger),
                const SizedBox(height: 12),
                Text(
                  state.failure?.message ?? 'Données indisponibles.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FilledButton.tonal(
                  onPressed: () => context.read<ModerationBloc>().add(
                    const AdminOverviewRequested(),
                  ),
                  child: const Text('Réessayer'),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return _buildDashboard(context, state, overview);
  }

  Widget _buildDashboard(
    BuildContext context,
    ModerationState state,
    AdminOverview overview,
  ) {
    return RefreshIndicator(
      onRefresh: () async => _refreshAll(context),
      child: ListView(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        children: [
          _DashboardIntro(
            key: _overviewKey,
            controller: _searchController,
            query: _query,
            onQueryChanged: _updateSearch,
            onClear: _clearSearch,
          ),
          const SizedBox(height: 16),
          _MetricGrid(overview: overview),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final activity = _ActivityPanel(key: _activityKey, state: state);
              final moderation = _ModerationPanel(
                key: _itemsKey,
                items: _filterItems(overview.items),
                busyItemId: state.busyItemId,
              );
              if (constraints.maxWidth >= 900) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: activity),
                    const SizedBox(width: 16),
                    Expanded(child: moderation),
                  ],
                );
              }
              return Column(
                children: [activity, const SizedBox(height: 16), moderation],
              );
            },
          ),
          const SizedBox(height: 16),
          _UsersPanel(
            key: _usersKey,
            users: _filterUsers(overview.users),
            total: overview.users.length,
          ),
        ],
      ),
    );
  }
}

class _LiveBadge extends StatelessWidget {
  const _LiveBadge();

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(right: 4),
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
    decoration: BoxDecoration(
      color: _brandSoft,
      borderRadius: BorderRadius.circular(20),
    ),
    child: const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.circle, size: 7, color: _brand),
        SizedBox(width: 6),
        Text(
          'EN DIRECT',
          style: TextStyle(
            color: _brand,
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.6,
          ),
        ),
      ],
    ),
  );
}

class _DashboardIntro extends StatelessWidget {
  const _DashboardIntro({
    super.key,
    required this.controller,
    required this.query,
    required this.onQueryChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final String query;
  final ValueChanged<String> onQueryChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final headings = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Vue d’ensemble',
          style: Theme.of(context).textTheme.headlineSmall
              ?.copyWith(fontWeight: FontWeight.w800, color: _ink),
        ),
        const SizedBox(height: 4),
        const Text(
          'Suivez l’activité, modérez les annonces et surveillez les comptes en temps réel.',
          style: TextStyle(color: _muted, fontSize: 13),
        ),
      ],
    );
    final search = SizedBox(
      width: 320,
      child: TextField(
        controller: controller,
        onChanged: onQueryChanged,
        decoration: InputDecoration(
          hintText: 'Rechercher un compte, une annonce…',
          prefixIcon: const Icon(Icons.search, size: 20),
          suffixIcon: query.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  tooltip: 'Effacer',
                  onPressed: onClear,
                ),
          isDense: true,
        ),
      ),
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 760) {
          return Row(
            children: [
              Expanded(child: headings),
              const SizedBox(width: 24),
              search,
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [headings, const SizedBox(height: 14), search],
        );
      },
    );
  }
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.overview});

  final AdminOverview overview;

  @override
  Widget build(BuildContext context) {
    final metrics = <Widget>[
      _Metric(
        label: 'Comptes',
        value: overview.userCount,
        icon: Icons.people_outline,
        tone: const _Tone(_brandSoft, _brand),
      ),
      _Metric(
        label: 'Annonces',
        value: overview.itemCount,
        icon: Icons.inventory_2_outlined,
        tone: const _Tone(Color(0xffe9f1fb), Color(0xff2563a6)),
      ),
      _Metric(
        label: 'Réclamations',
        value: overview.claimCount,
        icon: Icons.assignment_turned_in_outlined,
        tone: const _Tone(_warningSoft, _warning),
      ),
      _Metric(
        label: 'En attente',
        value: overview.pendingClaimCount,
        icon: Icons.hourglass_top_outlined,
        tone: const _Tone(_dangerSoft, _danger),
      ),
      _Metric(
        label: 'Comptes aujourd’hui',
        value: overview.newUsersToday,
        icon: Icons.person_add_alt_1_outlined,
        tone: const _Tone(Color(0xfff0ebfa), Color(0xff6b45a8)),
      ),
      _Metric(
        label: 'Actions aujourd’hui',
        value: overview.actionsToday,
        icon: Icons.bolt_outlined,
        tone: const _Tone(_brandSoft, _brand),
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth >= 900
            ? 3
            : constraints.maxWidth >= 560
            ? 2
            : 1;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: metrics.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 2.1,
          ),
          itemBuilder: (context, index) => metrics[index],
        );
      },
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.label,
    required this.value,
    required this.icon,
    required this.tone,
  });

  final String label;
  final int value;
  final IconData icon;
  final _Tone tone;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(15),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: tone.background,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: tone.foreground, size: 21),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: const TextStyle(color: _muted, fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '$value',
                  style: const TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.w800,
                    color: _ink,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _Panel extends StatelessWidget {
  const _Panel({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.child,
    this.action,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Widget child;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _brandSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: _brand, size: 19),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(color: _muted, fontSize: 11),
                    ),
                  ],
                ),
              ),
              ?action,
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    ),
  );
}

class _ActivityPanel extends StatelessWidget {
  const _ActivityPanel({super.key, required this.state});

  final ModerationState state;

  @override
  Widget build(BuildContext context) => _Panel(
    icon: Icons.timeline_outlined,
    title: 'Activité récente',
    subtitle: 'Journal des actions du plateau',
    action: state.activityLoading
        ? const SizedBox.square(
            dimension: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : null,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 7,
          runSpacing: 4,
          children: [
            for (final entry in _activityFilters.entries)
              ChoiceChip(
                label: Text(entry.value),
                selected: state.activityType == entry.key,
                visualDensity: VisualDensity.compact,
                onSelected: (_) => context.read<ModerationBloc>().add(
                  AdminActivityRequested(type: entry.key),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (state.activityFailure != null && state.activityPage == null)
          _InlineMessage(
            message: state.activityFailure!.message,
            icon: Icons.error_outline,
          )
        else if (state.activityPage?.items.isEmpty ?? true)
          const _InlineMessage(
            message: 'Aucune activité enregistrée pour ce filtre.',
            icon: Icons.history_toggle_off_outlined,
          )
        else
          Column(
            children: [
              for (final activity in state.activityPage!.items)
                _ActivityRow(activity: activity),
            ],
          ),
        if ((state.activityPage?.totalPages ?? 0) >
            (state.activityPage?.page ?? 0))
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: state.activityLoading
                  ? null
                  : () => context.read<ModerationBloc>().add(
                      AdminActivityRequested(
                        page: (state.activityPage?.page ?? 1) + 1,
                        type: state.activityType,
                      ),
                    ),
              icon: const Icon(Icons.expand_more),
              label: const Text('Voir plus'),
            ),
          ),
      ],
    ),
  );
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.activity});

  final AdminActivity activity;

  @override
  Widget build(BuildContext context) {
    final tone = _activityTone(activity.type);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 3,
            height: 44,
            decoration: BoxDecoration(
              color: tone.foreground,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 10),
          CircleAvatar(
            radius: 17,
            backgroundColor: tone.background,
            child: Icon(
              _activityIcon(activity.type),
              color: tone.foreground,
              size: 17,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.summary,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${activity.actorName} · ${_formatDate(activity.createdAt)}',
                  style: const TextStyle(color: _muted, fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: _SmallChip(
              label: _activityLabel(activity.type),
              background: tone.background,
              foreground: tone.foreground,
            ),
          ),
        ],
      ),
    );
  }
}

class _ModerationPanel extends StatelessWidget {
  const _ModerationPanel({
    super.key,
    required this.items,
    required this.busyItemId,
  });

  final List<AdminItemSummary> items;
  final String? busyItemId;

  @override
  Widget build(BuildContext context) => _Panel(
    icon: Icons.inventory_2_outlined,
    title: 'Annonces à modérer',
    subtitle: '${items.length} annonce(s) suivie(s)',
    child: items.isEmpty
        ? const _InlineMessage(
            message: 'Aucune annonce ne correspond à la recherche.',
            icon: Icons.check_circle_outline,
          )
        : Column(
            children: [
              for (final item in items)
                _ItemRow(item: item, busy: busyItemId == item.id),
            ],
          ),
  );
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({required this.item, required this.busy});

  final AdminItemSummary item;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final tone = _statusTone(item.isRemoved);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _thumbnail(imageData: item.imageData),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    _SmallChip(
                      label: item.isRemoved ? 'Masquée' : 'Visible',
                      background: tone.background,
                      foreground: tone.foreground,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  item.description,
                  style: const TextStyle(color: _muted, fontSize: 12),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${item.ownerName} · ${item.location}',
                  style: const TextStyle(color: _muted, fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (item.moderationReason != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Motif : ${item.moderationReason}',
                    style: const TextStyle(color: _danger, fontSize: 11),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          busy
              ? const SizedBox.square(
                  dimension: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : IconButton(
                  tooltip: item.isRemoved
                      ? 'Rétablir l’annonce'
                      : 'Masquer l’annonce',
                  icon: Icon(
                    item.isRemoved
                        ? Icons.restore
                        : Icons.visibility_off_outlined,
                    color: item.isRemoved ? _brand : _danger,
                  ),
                  onPressed: () => item.isRemoved
                      ? context.read<ModerationBloc>().add(
                          AdminItemModerationChanged(
                            itemId: item.id,
                            isRemoved: false,
                          ),
                        )
                      : _requestRemoval(context, item),
                ),
        ],
      ),
    );
  }
}

Widget _thumbnail({required String? imageData}) {
  final placeholder = Container(
    width: 54,
    height: 54,
    decoration: BoxDecoration(
      color: _surface,
      borderRadius: BorderRadius.circular(12),
    ),
    child: const Icon(Icons.image_outlined, color: _muted, size: 20),
  );
  if (imageData == null || imageData.isEmpty) return placeholder;
  try {
    final bytes = base64Decode(imageData.split(',').last);
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.memory(
        bytes,
        width: 54,
        height: 54,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => placeholder,
      ),
    );
  } catch (_) {
    return placeholder;
  }
}

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

class _UsersPanel extends StatelessWidget {
  const _UsersPanel({super.key, required this.users, required this.total});

  final List<AdminUserSummary> users;
  final int total;

  @override
  Widget build(BuildContext context) => _Panel(
    icon: Icons.people_outline,
    title: 'Comptes inscrits',
    subtitle: '${users.length} affiché(s) sur $total',
    child: users.isEmpty
        ? const _InlineMessage(
            message: 'Aucun compte ne correspond à la recherche.',
            icon: Icons.person_off_outlined,
          )
        : Column(children: [for (final user in users) _UserRow(user: user)]),
  );
}

class _UserRow extends StatelessWidget {
  const _UserRow({required this.user});

  final AdminUserSummary user;

  @override
  Widget build(BuildContext context) {
    final tone = _roleTone(user.role);
    return LayoutBuilder(
      builder: (context, constraints) {
        final detailed = constraints.maxWidth >= 620;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 7),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: _brandSoft,
                child: Text(
                  user.name.isEmpty ? '?' : user.name[0].toUpperCase(),
                  style: const TextStyle(
                    color: _brand,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      user.email,
                      style: const TextStyle(color: _muted, fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (detailed) ...[
                const SizedBox(width: 12),
                SizedBox(
                  width: 100,
                  child: Text(
                    user.matricule,
                    style: const TextStyle(color: _muted, fontSize: 11),
                  ),
                ),
              ],
              _SmallChip(
                label: user.role == 'admin' ? 'Admin' : 'Étudiant',
                background: tone.background,
                foreground: tone.foreground,
              ),
              if (detailed && user.createdAt != null) ...[
                const SizedBox(width: 12),
                SizedBox(
                  width: 118,
                  child: Text(
                    _formatDate(user.createdAt!),
                    style: const TextStyle(color: _muted, fontSize: 11),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _SmallChip extends StatelessWidget {
  const _SmallChip({
    required this.label,
    required this.background,
    required this.foreground,
  });

  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      label,
      style: TextStyle(
        color: foreground,
        fontSize: 10,
        fontWeight: FontWeight.w700,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    ),
  );
}

class _InlineMessage extends StatelessWidget {
  const _InlineMessage({required this.message, required this.icon});

  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: _surface,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      children: [
        Icon(icon, color: _muted, size: 26),
        const SizedBox(height: 8),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: _muted, fontSize: 12),
        ),
      ],
    ),
  );
}
