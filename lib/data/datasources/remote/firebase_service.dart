import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logger/logger.dart';
import 'package:progress_pals/data/models/friend_model.dart';
import 'package:progress_pals/data/models/habit_model.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Logger _logger = Logger();

  // Habits
  Future<void> addHabit(HabitModel habit) async {
    try {
      final habitRef = _firestore
          .collection('users')
          .doc(habit.userId)
          .collection('habits')
          .doc(habit.id);

      // 1. Get the map (which has 'sharedWith' as a String for SQLite)
      final habitData = habit.toMap();

      // 2. THE FIX: Overwrite fields for Firestore-friendly types
      habitData['sharedWith'] = habit.sharedWith;
      habitData['completionDates'] = habit.completionDates
          ?.map((d) => d.toIso8601String())
          .toList();

      await habitRef.set(habitData);
      _logger.i('Habit added to Firestore: ${habit.name}');
    } catch (e) {
      _logger.e('Error adding habit: $e');
      rethrow;
    }
  }

  Stream<List<HabitModel>> getHabits(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('habits')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return HabitModel.fromMap(doc.data());
          }).toList();
        });
  }

  Future<List<HabitModel>> getHabitsOnce(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('habits')
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
      // 1. Get the map
      final habitData = habit.toMap();

      // 2. THE FIX: Overwrite with Firestore-friendly types
      habitData['sharedWith'] = habit.sharedWith;
      habitData['completionDates'] = habit.completionDates
          ?.map((d) => d.toIso8601String())
          .toList();

      await _firestore
          .collection('users')
          .doc(habit.userId)
          .collection('habits')
          .doc(habit.id)
          .update(habitData);

      _logger.i('Habit updated in Firestore: ${habit.name}');
    } catch (e) {
      _logger.e('Error updating habit: $e');
      rethrow;
    }
  }

  Future<void> deleteHabit(String habitId, String userId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('habits')
          .doc(habitId)
          .delete();
      _logger.i('Habit deleted from Firestore');
    } catch (e) {
      _logger.e('Error deleting habit: $e');
      rethrow;
    }
  }

  Future<List<FriendModel>> getFriendsOnce(String userId) async {
    try {
      final snapshot = await _firestore
          .collection("users")
          .doc(userId)
          // .where('userId', isEqualTo: userId)
          .collection('friends')
          .get();
      return snapshot.docs
          .map((doc) => FriendModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      _logger.e('Error fetching friends: $e');
      return [];
    }
  }

  Future<void> updateFriend(FriendModel friend) async {
    try {
      await _firestore
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
      await _firestore.collection('friends').doc(friendId).delete();
      _logger.i('Friend deleted from Firestore');
    } catch (e) {
      _logger.e('Error removing friend: $e');
      rethrow;
    }
  }

  Future<void> debugFriendHabits(String friendUserId) async {
    final myEmail = FirebaseAuth.instance.currentUser?.email;

    _logger.i("--- STARTING DEBUG ---");
    _logger.i("1. Looking for Friend ID: $friendUserId");
    _logger.i(
      "2. My Email is: '$myEmail'",
    ); // Check for spaces or capitalization!

    _logger.t(friendUserId);

    try {
      // STEP 1: Fetch EVERYTHING in that friend's habit folder (No Filters)
      final allHabitsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(friendUserId)
          .collection('habits')
          .get();

      _logger.i(
        "3. Found ${allHabitsSnapshot.docs.length} total habits for this friend.",
      );

      if (allHabitsSnapshot.docs.isEmpty) {
        _logger.w(
          "!! PROBLEM: This friend has no habits at all in the database, or the friendID is wrong.",
        );
        return;
      }

      // STEP 2: Loop through them and inspect the 'sharedWith' field manually
      for (var doc in allHabitsSnapshot.docs) {
        final data = doc.data();
        final name = data['name'];
        final sharedWith = data['sharedWith'];

        _logger.i("   - Habit: '$name'");
        _logger.i("     Actual 'sharedWith' value in DB: $sharedWith");
        _logger.i("     Type of sharedWith: ${sharedWith.runtimeType}");

        // Check if our email is actually in there
        if (sharedWith is List && sharedWith.contains(myEmail)) {
          _logger.i("     [MATCH] This habit SHOULD show up!");
        } else {
          _logger.w(
            "     [NO MATCH] My email '$myEmail' is NOT in $sharedWith",
          );
        }
      }
    } catch (e) {
      _logger.e("CRITICAL ERROR: $e");
    }
    _logger.i("--- END DEBUG ---");
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

  // 2. GET FRIENDS (Fix this to match the Add function)
  Stream<List<FriendModel>> getFriends(String userId) {
    return _firestore
        .collection('users') // <--- Start at users
        .doc(userId) // <--- Go to YOUR document
        .collection('friends') // <--- Read from the SAME sub-collection
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => FriendModel.fromMap(doc.data()))
              .toList();
        });
  }

  // New helper to find a user's real ID based on their email
  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: email) // Search by email
          .limit(1) // We only expect one user
          .get();

      if (snapshot.docs.isEmpty) {
        return null; // User not found
      }

      // Return the data AND the document ID (which is the real userId)
      final doc = snapshot.docs.first;
      final data = doc.data();
      data['userId'] = doc.id; // Ensure the ID is attached
      return data;
    } catch (e) {
      _logger.e('Error searching for user: $e');
      return null;
    }
  }

  // NEW: Call this immediately after Login/Sign-up
  Future<void> saveUserToFirestore(User user) async {
    try {
      // Reference to the user's document
      final userDoc = _firestore.collection('users').doc(user.uid);

      // We use set with SetOptions(merge: true)
      // This creates the doc if missing, or updates it if it exists
      // effectively "healing" any missing data like 'email'
      await userDoc.set({
        'userId': user.uid,
        'email': user.email?.toLowerCase(), // CRITICAL for search
        'displayName': user.displayName ?? 'Unknown',
        'lastSeen': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      _logger.i('User data synced to Firestore: ${user.email}');
    } catch (e) {
      _logger.e('Error saving user to Firestore: $e');
      // Don't rethrow here, we don't want to block login if this fails
    }
  }

  // Update displayName in both Firebase Auth and Firestore
  Future<void> updateUserDisplayName(String displayName) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _logger.e('No user logged in');
        return;
      }

      // Update in Firebase Auth
      await user.updateDisplayName(displayName);
      await user.reload();

      // Update in Firestore
      await _firestore.collection('users').doc(user.uid).update({
        'displayName': displayName,
      });

      _logger.i('Display name updated: $displayName');
    } catch (e) {
      _logger.e('Error updating display name: $e');
      rethrow;
    }
  }

  // Future<List<HabitModel>> getSharedHabitsFromFriend(
  //   String friendUserId,
  // ) async {
  //   try {
  //     final user = FirebaseAuth.instance.currentUser;

  //     if (user == null || user.email == null) {
  //       _logger.e('Error: User not logged in or has no email');
  //       return [];
  //     }

  //     // FIX: Force lowercase.
  //     // If Auth gives "User@Gmail.com", we must search for "user@gmail.com"
  //     final myEmail = user.email!.toLowerCase();

  //     _logger.i("Searching for habits shared with: $myEmail");

  //     final snapshot = await _firestore
  //         .collection('users')
  //         .doc(friendUserId)
  //         .collection('habits')
  //         .where(
  //           'sharedWith',
  //           arrayContains: myEmail,
  //         ) // This fails if DB field is a String
  //         .get();

  //     return snapshot.docs
  //         .map((doc) => HabitModel.fromMap(doc.data()))
  //         .toList();
  //   } catch (e) {
  //     _logger.e('Error fetching shared habits: $e');
  //     return [];
  //   }
  // }

  Future<List<HabitModel>> getSharedHabitsFromFriend(
    String friendUserId,
  ) async {
    try {
      _logger.f("Her We Gooooooooooooo");
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || user.email == null) {
        _logger.e('Error: User not logged in or has no email');
        return [];
      }

      final myEmail = user.email!.trim().toLowerCase();
      _logger.i("Looking for habits shared with: $myEmail");

      // STRATEGY: Fetch ALL habits for this friend, then filter manually.
      // This bypasses the "String vs Array" query crash.
      final snapshot = await _firestore
          .collection('users')
          .doc(friendUserId)
          .collection('habits')
          .get(); // <--- Notice: NO .where() filter here!

      _logger.i(
        "Found ${snapshot.docs.length} total habits for friend. Filtering now...",
      );

      List<HabitModel> matchingHabits = [];
      _logger.i(friendUserId);

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final rawSharedWith = data['sharedWith'];
        _logger.d(rawSharedWith);
        bool isShared = false;

        // CHECK 1: Is it a List?
        if (rawSharedWith is List) {
          // NUCLEAR CLEANUP:
          // 1. toString() -> ensure it's text
          // 2. toLowerCase() -> ignore case
          // 3. trim() -> remove spaces
          // 4. replaceAll -> remove accidental quotes or brackets saved in the text
          final cleanedList = rawSharedWith.map((e) {
            return e
                .toString()
                .toLowerCase()
                .trim()
                .replaceAll("'", "") // Remove single quotes
                .replaceAll('"', "") // Remove double quotes
                .replaceAll("[", "") // Remove open bracket
                .replaceAll("]", ""); // Remove close bracket
          }).toList();

          _logger.f(
            "Checking: '$myEmail' vs Cleaned List: $cleanedList",
          ); // Debug print

          // if (cleanedList.contains(myEmail)) {
          //   isShared = true;
          // }

          for (final item in cleanedList) {
            _logger.d("Comparing item: '$item' with '$myEmail'");
            if (item == myEmail) {
              isShared = true;
              break;
            }
          }
        }
        // CHECK 2: Is it a String? (Legacy support)
        else if (rawSharedWith is String) {
          // Same cleanup for string mode
          final cleanString = rawSharedWith
              .toLowerCase()
              .trim()
              .replaceAll("'", "")
              .replaceAll('"', "");

          if (cleanString.contains(myEmail)) {
            isShared = true;
          }
        }

        if (isShared) {
          matchingHabits.add(HabitModel.fromMap(data));
        }
      }

      _logger.i(
        "Final Result: ${matchingHabits.length} habits shared with me.",
      );
      return matchingHabits;
    } catch (e) {
      _logger.e('Error fetching shared habits: $e');
      return [];
    }
  }
}
