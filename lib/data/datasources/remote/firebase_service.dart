import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logger/logger.dart';
import 'package:progress_pals/data/models/friend_model.dart';
import 'package:progress_pals/data/models/habit_model.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Logger _logger = Logger();

  Future<void> addHabit(HabitModel habit) async {
    try {
      final habitRef = _firestore.collection('habits').doc(habit.id);

      final habitData = habit.toMap();
      habitData['sharedWith'] = habit.sharedWith;

      await habitRef.set(habitData);
      _logger.i('Habit added to Firestore: ${habit.name}');
    } catch (e) {
      _logger.e('Error adding habit: $e');
      rethrow;
    }
  }

  Future<List<HabitModel>> getHabits(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('habits')
          .where('userId', isEqualTo: userId)
          .get();
          
      return snapshot.docs
          .map((doc) => HabitModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      _logger.e('Error fetching habits: $e');
      return [];
    }
  }

  Future<void> updateHabit(HabitModel habit) async {
    try {
      final habitData = habit.toMap();
      habitData['sharedWith'] = habit.sharedWith;

      await _firestore
          .collection('habits')
          .where('userId', isEqualTo: habit.userId)
          .where('id', isEqualTo: habit.id)
          .get()
          .then((snapshot) {
            if (snapshot.docs.isNotEmpty) {
              snapshot.docs.first.reference.update(habitData);
            }
          });

      _logger.i('Habit updated in Firestore: ${habit.name}');
    } catch (e) {
      _logger.e('Error updating habit: $e');
      rethrow;
    }
  }

  Future<void> deleteHabit(HabitModel habit) async {
    try {
      await _firestore.collection('habits').where('id', isEqualTo: habit.id).where('userId', isEqualTo: habit.userId).get().then((snapshot) {
        if (snapshot.docs.isNotEmpty) {
          snapshot.docs.first.reference.delete();
        }
      });
      _logger.i('Habit deleted from Firestore');
    } catch (e) {
      _logger.e('Error deleting habit: $e');
      rethrow;
    }
  }

  Future<List<HabitModel>> getSharedHabitsFromFriend(String friendUserId) async {
    try {
      _logger.f("Fetching Shared Habits (Flat Structure)");
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || user.email == null) {
        _logger.e('Error: User not logged in or has no email');
        return [];
      }

      final myEmail = user.email!.trim().toLowerCase();
      _logger.i("Looking for habits shared with: $myEmail");

      // Changed: Query the root 'habits' collection for the friend's ID
      final snapshot = await _firestore
          .collection('habits')
          .where('userId', isEqualTo: friendUserId)
          .get(); 

      _logger.i("Found ${snapshot.docs.length} total habits for friend. Filtering now...");

      List<HabitModel> matchingHabits = [];

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final rawSharedWith = data['sharedWith'];
        bool isShared = false;

        if (rawSharedWith is List) {
          final cleanedList = rawSharedWith.map((e) {
            return e.toString().toLowerCase().trim()
                .replaceAll("'", "").replaceAll('"', "")
                .replaceAll("[", "").replaceAll("]", "");
          }).toList();

          for (final item in cleanedList) {
            if (item == myEmail) {
              isShared = true;
              break;
            }
          }
        } else if (rawSharedWith is String) {
          final cleanString = rawSharedWith.toLowerCase().trim()
              .replaceAll("'", "").replaceAll('"', "");
          if (cleanString.contains(myEmail)) {
            isShared = true;
          }
        }

        if (isShared) {
          matchingHabits.add(HabitModel.fromMap(data));
        }
      }

      _logger.i("Final Result: ${matchingHabits.length} habits shared with me.");
      return matchingHabits;
    } catch (e) {
      _logger.e('Error fetching shared habits: $e');
      return [];
    }
  }

  Future<void> addFriendToUser(FriendModel friend) async {
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;
    await _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('friends')
        .doc(friend.userId)
        .set(friend.toMap());
  }

  Future<List<FriendModel>> getFriends(String userId) async {
    try {
      final snapshot = await _firestore
          .collection("users")
          .doc(userId)
          .collection('friends')
          .get();
      return snapshot.docs.map((doc) => FriendModel.fromMap(doc.data())).toList();
    } catch (e) {
      _logger.e('Error fetching friends: $e');
      return [];
    }
  }

  Future<void> updateFriend(FriendModel friend) async {
    try {
      // FIX: Ensure this targets the subcollection, not a root 'friends' collection
      final currentUserId = FirebaseAuth.instance.currentUser!.uid;
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('friends')
          .doc(friend.id)
          .update(friend.toMap());
      _logger.i('Friend updated in Firestore: ${friend.name}');
    } catch (e) {
      _logger.e('Error updating friend: $e');
      rethrow;
    }
  }

  Future<void> removeFriend(String friendId) async {
    try {
      // FIX: Ensure this targets the subcollection, not a root 'friends' collection
      final currentUserId = FirebaseAuth.instance.currentUser!.uid;
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('friends')
          .doc(friendId)
          .delete();
      _logger.i('Friend deleted from Firestore');
    } catch (e) {
      _logger.e('Error removing friend: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;

      final doc = snapshot.docs.first;
      final data = doc.data();
      data['userId'] = doc.id;
      return data;
    } catch (e) {
      _logger.e('Error searching for user: $e');
      return null;
    }
  }

  Future<void> saveUserToFirestore(User user) async {
    try {
      final userDoc = _firestore.collection('users').doc(user.uid);
      await userDoc.set({
        'userId': user.uid,
        'email': user.email?.toLowerCase(),
        'displayName': user.displayName ?? 'Unknown',
        'lastSeen': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      _logger.i('User data synced to Firestore: ${user.email}');
    } catch (e) {
      _logger.e('Error saving user to Firestore: $e');
    }
  }

  Future<void> updateUserDisplayName(String displayName) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _logger.e('No user logged in');
        return;
      }

      await user.updateDisplayName(displayName);
      await user.reload();

      await _firestore.collection('users').doc(user.uid).update({
        'displayName': displayName,
      });
      _logger.i('Display name updated: $displayName');
    } catch (e) {
      _logger.e('Error updating display name: $e');
      rethrow;
    }
  }
}