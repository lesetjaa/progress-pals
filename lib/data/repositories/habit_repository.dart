import 'package:progress_pals/data/datasources/local/database_service.dart';
import 'package:progress_pals/data/models/habit_model.dart';

abstract class IHabitRepository {
  Future<List<HabitModel>> getHabits();
  Future<void> addHabit(HabitModel habit);
  Future<void> updateHabit(HabitModel habit);
  Future<void> deleteHabit(String id);
  Future<void> completeHabit(String id);
}

class HabitRepository implements IHabitRepository {
  final DatabaseService _databaseService;

  HabitRepository(this._databaseService);

  @override
  Future<List<HabitModel>> getHabits() async {
    return await _databaseService.getHabits();
  }

  @override
  Future<void> addHabit(HabitModel habit) async {
    await _databaseService.insertHabit(habit);
  }

  @override
  Future<void> updateHabit(HabitModel habit) async {
    await _databaseService.updateHabit(habit);
  }

  @override
  Future<void> deleteHabit(String id) async {
    await _databaseService.deleteHabit(id);
  }

  @override
  Future<void> completeHabit(String id) async {
    final habits = await _databaseService.getHabits();
    final habit = habits.firstWhere((h) => h.id == id);

    // Check if we need to reset the count (if last reset was before this week's Monday)
    final today = DateTime.now();
    final currentMonday = today.subtract(Duration(days: today.weekday - 1));
    final lastReset = habit.lastResetDate;
    final needsReset =
        lastReset == null ||
        lastReset.isBefore(
          DateTime(currentMonday.year, currentMonday.month, currentMonday.day),
        );

    // Check if habit was already completed today
    final lastCompleted = habit.lastCompletedDate;
    final isCompletedToday =
        lastCompleted != null &&
        lastCompleted.year == today.year &&
        lastCompleted.month == today.month &&
        lastCompleted.day == today.day;

    // Toggle: if completed today, uncomplete it; otherwise complete it
    // Prepare completionDates list and update accordingly
    final currentDates = habit.completionDates != null
        ? List<DateTime>.from(habit.completionDates!)
        : <DateTime>[];

    if (needsReset) {
      // remove dates before current week
      currentDates.removeWhere((d) => d.isBefore(currentMonday));
    }

    if (isCompletedToday) {
      // remove today's entry
      currentDates.removeWhere(
        (d) =>
            d.year == today.year &&
            d.month == today.month &&
            d.day == today.day,
      );
    } else {
      currentDates.add(today);
    }

    final updatedHabit = HabitModel(
      id: habit.id,
      userId: habit.userId,
      name: habit.name,
      description: habit.description,
      repeatPerWeek: habit.repeatPerWeek,
      completedCount: needsReset
          ? (isCompletedToday ? 0 : 1)
          : (isCompletedToday
                ? (habit.completedCount - 1).clamp(0, habit.repeatPerWeek)
                : habit.completedCount + 1),
      lastCompletedDate: isCompletedToday ? null : DateTime.now(),
      lastResetDate: needsReset ? DateTime.now() : habit.lastResetDate,
      completionDates: currentDates,
      sharedWith: habit.sharedWith,
      isSynced: false,
    );

    await _databaseService.updateHabit(updatedHabit);
  }
}
