import 'package:flutter/material.dart';
import 'package:logger/web.dart';
import 'package:progress_pals/data/models/habit_model.dart';
import 'package:progress_pals/data/repositories/habit_repository.dart';

class HomeViewModel extends ChangeNotifier {
  int _selectedIndex = 0;
  int get selectedIndex => _selectedIndex;

  int _currentDayIndex = 0;
  final List<String> _weekDays = ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'];

  List<String> get weekDays => _weekDays;
  int get currentDayIndex => _currentDayIndex;

  final IHabitRepository _habitRepository;
  List<HabitModel> _habits = [];
  bool _isLoading = false;

  List<HabitModel> get habits => _habits;
  bool get isLoading => _isLoading;

  HomeViewModel(this._habitRepository) {
    _init();
  }

  Future<void> _init() async {
    _setupDate();
    await fetchHabits();
  }

  void _setupDate() {
    _currentDayIndex = DateTime.now().weekday - 1;
    notifyListeners();
  }

  Future<void> fetchHabits() async {
    _isLoading = true;
    notifyListeners();
    try {
      _habits = await _habitRepository.getHabits();
    } catch (e) {
      Logger().e('Error fetching habits: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> completeHabit(String habitId) async {
    try {
      await _habitRepository.completeHabit(habitId);
      await fetchHabits();
    } catch (e) {
      Logger().e('Error completing habit: $e');
    }
  }

  Future<void> deleteHabit(HabitModel habit) async {
    try {
      await _habitRepository.deleteHabit(habit);
      await fetchHabits();
    } catch (e) {
      Logger().e('Error deleting habit: $e');
    }
  }

  void setIndex(int index) {
    _selectedIndex = index;
    notifyListeners();
  }
}
