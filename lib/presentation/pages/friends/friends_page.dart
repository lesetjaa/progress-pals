import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:logger/web.dart';
import 'package:progress_pals/core/theme/app_colors.dart';
import 'package:progress_pals/core/theme/theme_extensions.dart';
import 'package:progress_pals/data/datasources/local/database_service.dart';
import 'package:progress_pals/data/datasources/remote/firebase_service.dart';
import 'package:progress_pals/data/models/friend_model.dart';
import 'package:progress_pals/presentation/viewmodels/friends_viewmodel.dart';
import 'package:provider/provider.dart';

class FriendsPage extends StatefulWidget {
  const FriendsPage({super.key});

  @override
  State<FriendsPage> createState() => _FriendsPageState();
}

class _FriendsPageState extends State<FriendsPage> with WidgetsBindingObserver {
  final DatabaseService _databaseService = DatabaseService();
  final FirebaseService _firebaseService = FirebaseService();

  List<FriendModel> _friends = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadFriends();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Refresh when coming back from background
      final viewModel = Provider.of<FriendsViewModel>(context, listen: false);
      viewModel.refreshFriends();
    }
  }

  Future<void> _loadFriends() async {
    setState(() => _isLoading = true);
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        var localFriends = await _databaseService.getFriends(userId: userId);
        setState(() => _friends = localFriends);

        await _databaseService.syncFriendsFromCloud(userId);

        if (mounted) {
          setState(() {
            _friends = localFriends;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      Logger().e('Error loading friends: $e');
    }
    setState(() => _isLoading = false);
  }

  Future<void> _removeFriend(FriendModel friend) async {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Remove Friend'),
          content: Text('Are you sure you want to remove ${friend.name}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final friendName = friend.name;
                final friendId = friend.id;
                Navigator.pop(dialogContext);
                try {
                  await _databaseService.deleteFriend(friendId);
                  await _firebaseService.removeFriend(friendId);
                  await _loadFriends();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('$friendName removed!')),
                    );
                  }
                } catch (e) {
                  Logger().e('Error removing friend: $e');
                }
              },
              child: const Text('Remove', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.themeBackground,
      appBar: AppBar(
        toolbarHeight: 100,
        backgroundColor: context.themeBackground,
        elevation: 0,
        title: Text(
          'Friends',
          style: TextStyle(
            color: context.themeTextPrimary,
            fontSize: 28,
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              Logger().i("Add a friend");
              final result = await context.push('/home/add-friend');
              if (result == true) {
                await _loadFriends();
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Friends List Section
              Text(
                'Your Friends',
                style: TextStyle(
                  color: context.themeTextPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _friends.isEmpty
                  ? Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.people_outline,
                            size: 64,
                            color: context.themeTextDisabled,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No friends added yet',
                            style: TextStyle(
                              color: context.themeTextSecondary,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _friends.length,
                      itemBuilder: (context, index) {
                        final friend = _friends[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppColors.primary,
                              child: Text(
                                friend.name[0].toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              friend.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(friend.email),
                            trailing: SizedBox(
                              width: 100,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.edit,
                                      color: AppColors.primary,
                                    ),
                                    onPressed: () async {
                                      Logger().i("Edit friend: ${friend.name}");
                                      final result = await context.push(
                                        '/home/add-friend',
                                        extra: friend,
                                      );
                                      if (result == true) {
                                        await _loadFriends();
                                      }
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                    ),
                                    onPressed: () async {
                                      await _removeFriend(friend);
                                    },
                                  ),
                                ],
                              ),
                            ),
                            onTap: () {
                              Logger().d("View analytics for: ${friend.name}");
                              context.push(
                                '/home/friend-analytics',
                                extra: friend,
                              );
                            },
                          ),
                        );
                      },
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
