// lib/features/friends/presentation/view/friends_screen.dart

import 'package:flutter/material.dart';
import 'package:musilingo/app/core/theme/app_colors.dart';
import 'package:musilingo/app/data/models/user_profile_model.dart';
import 'package:musilingo/app/presentation/widgets/gradient_background.dart';
import 'package:musilingo/features/friends/data/services/friends_service.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen>
    with TickerProviderStateMixin {
  final FriendsService _friendsService = FriendsService();
  late final TabController _tabController;

  // As listas agora usam UserProfileModel
  List<UserProfile> _friends = [];
  List<UserProfile> _pendingRequests = [];
  List<UserProfile> _searchResults = [];

  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchFriendsData();
  }

  // A lógica para buscar os dados agora chama os novos métodos
  Future<void> _fetchFriendsData() async {
    setState(() => _isLoading = true);
    // Usamos Future.wait para carregar amigos e pedidos em paralelo
    final results = await Future.wait([
      _friendsService.getFriends(),
      _friendsService.getPendingRequests(),
    ]);

    if (mounted) {
      setState(() {
        _friends = results[0];
        _pendingRequests = results[1];
        _isLoading = false;
      });
    }
  }

  Future<void> _searchUsers(String query) async {
    if (query.trim().isEmpty) {
      if (mounted) setState(() => _searchResults = []);
      return;
    }
    final results = await _friendsService.searchUsers(query);
    if (mounted) setState(() => _searchResults = results);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Amigos'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: AppColors.accent,
            tabs: const <Widget>[
              Tab(text: 'Amigos', icon: Icon(Icons.people)),
              Tab(text: 'Pedidos', icon: Icon(Icons.person_add)),
              Tab(text: 'Adicionar', icon: Icon(Icons.search)),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.accent))
            : TabBarView(
                controller: _tabController,
                children: <Widget>[
                  _buildFriendsListTab(),
                  _buildPendingRequestsTab(),
                  _buildAddFriendTab(),
                ],
              ),
      ),
    );
  }

  Widget _buildFriendsListTab() {
    if (_friends.isEmpty) {
      return const Center(
          child: Text('Você ainda não tem amigos.',
              style: TextStyle(color: AppColors.textSecondary)));
    }
    return RefreshIndicator(
      onRefresh: _fetchFriendsData,
      child: ListView.builder(
        padding: const EdgeInsets.all(8.0),
        itemCount: _friends.length,
        itemBuilder: (context, index) {
          final friend = _friends[index];
          return _buildUserCard(
            user: friend,
            trailing: IconButton(
              icon: const Icon(Icons.person_remove, color: Colors.redAccent),
              tooltip: 'Remover amigo',
              onPressed: () async {
                await _friendsService.removeOrDeclineFriend(friend.id);
                _fetchFriendsData();
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildPendingRequestsTab() {
    if (_pendingRequests.isEmpty) {
      return const Center(
          child: Text('Nenhum pedido pendente.',
              style: TextStyle(color: AppColors.textSecondary)));
    }
    return RefreshIndicator(
      onRefresh: _fetchFriendsData,
      child: ListView.builder(
        padding: const EdgeInsets.all(8.0),
        itemCount: _pendingRequests.length,
        itemBuilder: (context, index) {
          final request = _pendingRequests[index];
          return _buildUserCard(
            user: request,
            subtitle: 'Enviou um pedido de amizade',
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.check_circle,
                      color: AppColors.completed),
                  tooltip: 'Aceitar',
                  onPressed: () async {
                    await _friendsService.acceptFriendRequest(request.id);
                    _fetchFriendsData();
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.cancel, color: Colors.redAccent),
                  tooltip: 'Recusar',
                  onPressed: () async {
                    await _friendsService.removeOrDeclineFriend(request.id);
                    _fetchFriendsData();
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAddFriendTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Procurar por nome',
              labelStyle: const TextStyle(color: AppColors.textSecondary),
              suffixIcon:
                  const Icon(Icons.search, color: AppColors.textSecondary),
              filled: true,
              fillColor: AppColors.card.withAlpha(200),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: _searchUsers,
          ),
          const SizedBox(height: 20),
          Expanded(
            child: _searchResults.isEmpty && _searchController.text.isNotEmpty
                ? const Center(
                    child: Text('Nenhum utilizador encontrado.',
                        style: TextStyle(color: AppColors.textSecondary)))
                : ListView.builder(
                    itemCount: _searchResults.length,
                    itemBuilder: (context, index) {
                      final user = _searchResults[index];
                      return _buildUserCard(
                        user: user,
                        trailing: IconButton(
                          icon: const Icon(Icons.person_add_alt_1,
                              color: AppColors.accent),
                          tooltip: 'Adicionar amigo',
                          onPressed: () async {
                            try {
                              await _friendsService.sendFriendRequest(user.id);
                              // ignore: use_build_context_synchronously
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      'Pedido enviado para ${user.fullName}'),
                                  backgroundColor: AppColors.completed,
                                ),
                              );
                            } catch (e) {
                              // ignore: use_build_context_synchronously
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(e.toString()),
                                  backgroundColor:
                                      // ignore: use_build_context_synchronously
                                      Theme.of(context).colorScheme.error,
                                ),
                              );
                            }
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // Widget reutilizável para mostrar um utilizador numa lista
  Widget _buildUserCard({
    required UserProfile user,
    Widget? trailing,
    String? subtitle,
  }) {
    return Card(
      color: AppColors.card.withAlpha(200),
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage:
              user.avatarUrl != null ? NetworkImage(user.avatarUrl!) : null,
          child: user.avatarUrl == null
              ? Text(user.fullName[0].toUpperCase())
              : null,
        ),
        title: Text(user.fullName, style: const TextStyle(color: Colors.white)),
        subtitle: subtitle != null
            ? Text(subtitle,
                style: const TextStyle(color: AppColors.textSecondary))
            : null,
        trailing: trailing,
      ),
    );
  }
}
