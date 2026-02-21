import 'package:firebase_auth/firebase_auth.dart';
import 'package:logger/web.dart';
import 'package:progress_pals/data/models/friend_model.dart';
import 'package:progress_pals/data/models/habit_model.dart';
import 'package:progress_pals/data/datasources/remote/firebase_service.dart';
import 'package:sqflite/sqflite.dart';

abstract class AppDatabase {
  Future<Database> initDatabase();
  Future<void> closeDatabase();
}

class DatabaseService implements AppDatabase {
  static Database? _database;
  final FirebaseService _firebaseService = FirebaseService();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await initDatabase();
    return _database!;
  }

  @override
  Future<Database> initDatabase() async {
    _database = await openDatabase(
      "habits.db",
      version: 6,
      onCreate: (db, version) async {
        await db.execute('''
            CREATE TABLE IF NOT EXISTS Habits (
              id TEXT PRIMARY KEY, 
              userId TEXT,
              name TEXT, 
              description TEXT, 
              repeatPerWeek INTEGER, 
              completedCount INTEGER, 
              lastCompletedDate TEXT, 
              lastResetDate TEXT,
              completionDates TEXT,
              sharedWith TEXT,
              isSynced INTEGER
            )
          ''');
        await db.execute('''
          CREATE TABLE IF NOT EXISTS Friends (
            id TEXT PRIMARY KEY,
            userId TEXT,
            email TEXT,
            name TEXT,
            addedDate TEXT
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE Habits ADD COLUMN userId TEXT');
        }
        if (oldVersion < 3) {
          await db.execute('ALTER TABLE Habits ADD COLUMN lastResetDate TEXT');
        }
        if (oldVersion < 6) {
          try {
            await db.execute(
              'ALTER TABLE Habits ADD COLUMN completionDates TEXT',
            );
          } catch (_) {}
        }
        if (oldVersion < 4) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS Friends (
              id TEXT PRIMARY KEY,
              userId TEXT,
              email TEXT,
              name TEXT,
              addedDate TEXT
            )
          ''');
        }
        if (oldVersion < 5) {
          // Version 5 upgrade - no schema changes needed
        }
      },
    );
    syncAllData(FirebaseAuth.instance.currentUser?.uid ?? '');
    return _database!;
  }

  // Clear all data for a specific user
  Future<void> clearUserData(String userId) async {
    final db = await database;
    await db.delete('Habits', where: 'userId = ?', whereArgs: [userId]);
    await db.delete('Friends', where: 'userId = ?', whereArgs: [userId]);
    Logger().i('Cleared data for user: $userId');
  }

  @override
  Future<void> closeDatabase() async {
    await _database?.close();
    _database = null;
  }

  Future<void> insertHabit(HabitModel habit) async {
    final db = await database;
    await db.insert(
      'Habits',
      habit.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    Logger().i('Habit inserted: $habit');

    // Sync to Firebase
    try {
      await _firebaseService.addHabit(habit);
    } catch (e) {
      Logger().w('Failed to sync habit to Firebase: $e');
    }
  }

  Future<List<HabitModel>> getHabits({String? userId}) async {
    final db = await database;
    final currentUserId = userId ?? FirebaseAuth.instance.currentUser?.uid;

    if (currentUserId == null) return [];

    final List<Map<String, dynamic>> maps = await db.query(
      'Habits',
      where: 'userId = ?',
      whereArgs: [currentUserId],
    );
    return List.generate(maps.length, (i) {
      return HabitModel.fromMap(maps[i]);
    });
  }

  Future<void> updateHabit(HabitModel habit) async {
    final db = await database;
    await db.update(
      'Habits',
      habit.toMap(),
      where: 'id = ?',
      whereArgs: [habit.id],
    );
    Logger().i('Habit updated locally');

    // Sync to Firebase
    try {
      await _firebaseService.updateHabit(habit);
    } catch (e) {
      Logger().w('Failed to sync habit update to Firebase: $e');
    }
  }

  Future<void> deleteHabit(HabitModel habit) async {
    final db = await database;

    final List<Map<String, dynamic>> maps = await db.query(
      'Habits',
      where: 'id = ?',
      whereArgs: [habit.id],
      limit: 1,
    );

    // Delete the habit locally.
    await db.delete('Habits', where: 'id = ?', whereArgs: [habit.id]);
    Logger().i('Habit deleted locally');

    // If the habit existed locally, sync the deletion to Firebase.
    if (maps.isNotEmpty) {
      final habit = HabitModel.fromMap(maps.first);
      try {
        await _firebaseService.deleteHabit(habit);
      } catch (e) {
        Logger().w('Failed to sync habit deletion to Firebase: $e');
      }
    }
  }

  Future<void> insertFriend(FriendModel friend) async {
    final db = await database;
    await db.insert(
      'Friends',
      friend.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    Logger().i('Friend added: ${friend.name}');

    // Sync to Firebase
    try {
      await _firebaseService.addFriendToUser(friend);
    } catch (e) {
      Logger().w('Failed to sync friend to Firebase: $e');
    }
  }

  Future<List<FriendModel>> getFriends({String? userId}) async {
    final db = await database;
    final currentUserId = userId ?? FirebaseAuth.instance.currentUser?.uid;

    if (currentUserId == null) return [];

    final List<Map<String, dynamic>> maps = await db.query(
      'Friends',
      where: 'userId = ?',
      whereArgs: [currentUserId],
    );
    return List.generate(maps.length, (i) {
      return FriendModel.fromMap(maps[i]);
    });
  }

  Future<void> deleteFriend(String friendId) async {
    final db = await database;
    await db.delete('Friends', where: 'id = ?', whereArgs: [friendId]);
    Logger().i('Friend removed');

    // Sync deletion to Firebase
    try {
      await _firebaseService.removeFriend(friendId);
    } catch (e) {
      Logger().w('Failed to sync friend deletion to Firebase: $e');
    }
  }

  Future<void> updateFriend(FriendModel updatedFriend) async {
    final db = await database;
    await db.update(
      'Friends',
      updatedFriend.toMap(),
      where: 'id = ?',
      whereArgs: [updatedFriend.id],
    );
    Logger().i('Friend updated locally');

    // Sync to Firebase
    try {
      await _firebaseService.updateFriend(updatedFriend);
    } catch (e) {
      Logger().w('Failed to sync friend update to Firebase: $e');
    }
  }

  // Sync methods
  Future<void> syncHabitsFromCloud(String userId) async {
    try {
      final cloudHabits = await _firebaseService.getHabits(userId);
      final db = await database;

      for (final habit in cloudHabits) {
        await db.insert(
          'Habits',
          habit.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      Logger().i('Synced ${cloudHabits.length} habits from cloud');
    } catch (e) {
      Logger().e('Error syncing habits from cloud: $e');
    }
  }

  Future<void> syncFriendsFromCloud(String userId) async {
    try {
      final cloudFriends = await _firebaseService.getFriends(userId);
      final db = await database;

      for (final friend in cloudFriends) {
        await db.insert(
          'Friends',
          friend.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      Logger().i('Synced ${cloudFriends.length} friends from cloud');
    } catch (e) {
      Logger().e('Error syncing friends from cloud: $e');
    }
  }

  Future<void> syncAllData(String userId) async {
    await syncHabitsFromCloud(userId);
    await syncFriendsFromCloud(userId);
    Logger().i('All data synced from cloud');
  }

  Future<void> deleteAllData(String userId) async {
    await clearUserData(userId);
    try {
      await _firebaseService.deleteUserData(userId);
      Logger().i('All user data deleted from Firebase for user: $userId');
    } catch (e) {
      Logger().e('Error deleting user data from Firebase: $e');
    }
  }
}
