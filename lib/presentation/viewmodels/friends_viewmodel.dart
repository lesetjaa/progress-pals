import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:logger/web.dart';
import 'package:progress_pals/data/models/friend_model.dart';
import 'package:progress_pals/data/datasources/remote/firebase_service.dart';
import 'package:progress_pals/data/datasources/local/database_service.dart';

class FriendsViewModel extends ChangeNotifier {
  final FirebaseService _firebaseService;
  final DatabaseService _databaseService = DatabaseService();
  List<FriendModel> _friends = [];
  bool _isLoading = false;

  List<FriendModel> get friends => _friends;
  bool get isLoading => _isLoading;

  FriendsViewModel(this._firebaseService) {
    _loadFriends();
  }

  Future<void> _loadFriends() async {
    _isLoading = true;
    notifyListeners();
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        // Load from local database first
        _friends = await _databaseService.getFriends(userId: userId);
        notifyListeners();

        // Sync from cloud in background
        await _databaseService.syncFriendsFromCloud(userId);

        // Reload after sync
        _friends = await _databaseService.getFriends(userId: userId);
        notifyListeners();
      }
    } catch (e) {
      Logger().e('Error loading friends: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> refreshFriends() async {
    await _loadFriends();
  }

  Future<void> removeFriend(FriendModel friend) async {
    try {
      await _firebaseService.removeFriend(friend.id);
      await _loadFriends();
    } catch (e) {
      Logger().e('Error removing friend: $e');
    }
  }

  Future<void> addFriend(FriendModel friend) async {
    try {
      await _firebaseService.addFriendToUser(friend);
      await _loadFriends();
    } catch (e) {
      Logger().e('Error adding friend: $e');
    }
  }

  Future<void> updateFriend(FriendModel friend) async {
    try {
      await _firebaseService.updateFriend(friend);
      await _loadFriends();
    } catch (e) {
      Logger().e('Error updating friend: $e');
    }
  }

  Future<void> refresh() async {
    await _loadFriends();
  }
}
