// lib/features/friends/data/services/friends_service.dart

import 'package:flutter/foundation.dart';
import 'package:musilingo/app/data/models/user_profile_model.dart';
import 'package:musilingo/main.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Enum para representar o estado da amizade do ponto de vista do utilizador atual
enum FriendshipStatus { friends, requestSent, requestReceived, none }

class FriendsService {
  /// Procura por utilizadores pelo nome, excluindo o próprio utilizador.
  Future<List<UserProfile>> searchUsers(String query) async {
    final currentUser = supabase.auth.currentUser;
    if (query.trim().isEmpty || currentUser == null) {
      return [];
    }
    try {
      final response = await supabase
          .from('profiles')
          .select()
          .ilike('full_name', '%${query.trim()}%')
          .not('id', 'eq', currentUser.id)
          .limit(10);
      return response.map((data) => UserProfile.fromMap(data)).toList();
    } catch (e) {
      debugPrint('Erro ao procurar utilizadores: $e');
      return [];
    }
  }

  /// Envia um pedido de amizade.
  Future<void> sendFriendRequest(String friendId) async {
    final currentUser = supabase.auth.currentUser;
    if (currentUser == null) throw 'Utilizador não autenticado.';

    final userOneId =
        currentUser.id.compareTo(friendId) < 0 ? currentUser.id : friendId;
    final userTwoId =
        currentUser.id.compareTo(friendId) < 0 ? friendId : currentUser.id;

    try {
      await supabase.from('friend_relationships').insert({
        'user_one_id': userOneId,
        'user_two_id': userTwoId,
        'status': 'pending',
        'action_user_id': currentUser.id,
      });
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        throw 'Já existe um pedido de amizade ou vocês já são amigos.';
      }
      rethrow;
    }
  }

  /// Aceita um pedido de amizade.
  Future<void> acceptFriendRequest(String friendId) async {
    final currentUser = supabase.auth.currentUser;
    if (currentUser == null) throw 'Utilizador não autenticado.';

    await _updateFriendshipStatus(currentUser.id, friendId, 'accepted');
  }

  /// Recusa ou remove uma amizade.
  Future<void> removeOrDeclineFriend(String friendId) async {
    final currentUser = supabase.auth.currentUser;
    if (currentUser == null) throw 'Utilizador não autenticado.';

    final userOneId =
        currentUser.id.compareTo(friendId) < 0 ? currentUser.id : friendId;
    final userTwoId =
        currentUser.id.compareTo(friendId) < 0 ? friendId : currentUser.id;

    await supabase
        .from('friend_relationships')
        .delete()
        .eq('user_one_id', userOneId)
        .eq('user_two_id', userTwoId);
  }

  /// Método privado para atualizar o estado de uma amizade.
  Future<void> _updateFriendshipStatus(
      String userId, String friendId, String status) async {
    final userOneId = userId.compareTo(friendId) < 0 ? userId : friendId;
    final userTwoId = userId.compareTo(friendId) < 0 ? friendId : userId;

    await supabase
        .from('friend_relationships')
        .update({
          'status': status,
          'action_user_id': userId,
        })
        .eq('user_one_id', userOneId)
        .eq('user_two_id', userTwoId);
  }

  /// Obtém a lista de amigos (amizades aceites).
  Future<List<UserProfile>> getFriends() async {
    return _getFriendshipsByStatus('accepted');
  }

  /// Obtém a lista de pedidos de amizade pendentes recebidos.
  Future<List<UserProfile>> getPendingRequests() async {
    return _getFriendshipsByStatus('pending', received: true);
  }

  /// Função base para obter amizades com um determinado estado.
  Future<List<UserProfile>> _getFriendshipsByStatus(String status,
      {bool received = false}) async {
    final currentUser = supabase.auth.currentUser;
    if (currentUser == null) return [];

    try {
      var query = supabase
          .from('friend_relationships')
          .select('user_one_id, user_two_id, action_user_id')
          .eq('status', status)
          .or('user_one_id.eq.${currentUser.id},user_two_id.eq.${currentUser.id}');

      // Para pedidos recebidos, o action_user_id não pode ser o do utilizador atual
      if (received) {
        query = query.not('action_user_id', 'eq', currentUser.id);
      }

      final response = await query;

      final friendIds = response.map((rel) {
        return rel['user_one_id'] == currentUser.id
            ? rel['user_two_id']
            : rel['user_one_id'];
      }).toList();

      if (friendIds.isEmpty) return [];

      final profilesResponse =
          await supabase.from('profiles').select().inFilter('id', friendIds);

      return profilesResponse.map((data) => UserProfile.fromMap(data)).toList();
    } catch (e) {
      debugPrint('Erro ao obter amizades ($status): $e');
      return [];
    }
  }
}
