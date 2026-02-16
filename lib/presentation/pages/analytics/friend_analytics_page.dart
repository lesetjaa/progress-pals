import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:logger/web.dart';
import 'package:progress_pals/core/theme/app_colors.dart';
import 'package:go_router/go_router.dart';
import 'package:progress_pals/data/datasources/remote/firebase_service.dart';
import 'package:progress_pals/data/models/friend_model.dart';
import 'package:progress_pals/data/models/habit_model.dart';

class FriendAnalyticsPage extends StatefulWidget {
  final FriendModel? friend;

  const FriendAnalyticsPage({Key? key, this.friend}) : super(key: key);

  @override
  State<FriendAnalyticsPage> createState() => _FriendAnalyticsPageState();
}

class _FriendAnalyticsPageState extends State<FriendAnalyticsPage> {
  List<HabitModel> _friendHabits = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.friend != null) {
      _loadFriendHabits();
    }
  }

  Future<void> _loadFriendHabits() async {
    setState(() => _isLoading = true);

    try {
      if (widget.friend == null) return;

      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser?.email == null) return;

      // Load only habits shared with current user
      final firebaseService = FirebaseService();

      firebaseService.debugFriendHabits(widget.friend!.userId);
      Logger().f(widget.friend!.toMap());
      final friendHabits = await firebaseService.getSharedHabitsFromFriend(
        widget.friend!.userId,
      );

      setState(() => _friendHabits = friendHabits);

      Logger().i(
        'Loaded ${friendHabits.length} shared habits for friend from cloud',
      );
    } catch (e) {
      Logger().e('Error loading friend habits: $e');
    }
    setState(() => _isLoading = false);
  }

  int _getTotalCompletedThisWeek() {
    return _friendHabits.fold(0, (sum, habit) => sum + habit.completedCount);
  }

  int _getCompletionPercentage() {
    if (_friendHabits.isEmpty) return 0;
    final totalTarget = _friendHabits.fold<int>(
      0,
      (sum, habit) => sum + habit.repeatPerWeek,
    );
    final totalCompleted = _getTotalCompletedThisWeek();
    return totalTarget > 0 ? ((totalCompleted / totalTarget) * 100).toInt() : 0;
  }

  HabitModel? _getBestHabitThisWeek() {
    if (_friendHabits.isEmpty) return null;
    return _friendHabits.reduce(
      (a, b) => a.completedCount > b.completedCount ? a : b,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.friend == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Friend Analytics')),
        body: const Center(child: Text('No friend data available')),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '${widget.friend!.name} Analytics',
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _friendHabits.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.analytics_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No habits shared yet',
                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Friend Info Card
                    Card(
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppColors.primary.withValues(alpha: 0.1),
                              AppColors.primary.withValues(alpha: 0.05),
                            ],
                          ),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: AppColors.primary,
                              radius: 30,
                              child: Text(
                                widget.friend!.name[0].toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.friend!.name,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    widget.friend!.email,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Stats Cards
                    _buildStatCard(
                      'Weekly Completion',
                      '${_getCompletionPercentage()}%',
                      AppColors.primary,
                      Icons.trending_up,
                    ),
                    const SizedBox(height: 16),
                    _buildStatCard(
                      'Completed This Week',
                      '${_getTotalCompletedThisWeek()}',
                      Colors.green,
                      Icons.check_circle,
                    ),
                    const SizedBox(height: 24),

                    // Best Habit
                    const Text(
                      'Best Habit This Week',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _getBestHabitThisWeek() != null
                        ? _buildHabitCard(_getBestHabitThisWeek()!)
                        : const SizedBox.shrink(),
                    const SizedBox(height: 24),

                    // All Habits
                    const Text(
                      'All Habits',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ..._friendHabits
                        .map(
                          (habit) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _buildHabitProgressCard(habit),
                          ),
                        )
                        .toList(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    return Card(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withValues(alpha: 0.1),
              color.withValues(alpha: 0.05),
            ],
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
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

  Widget _buildHabitCard(HabitModel habit) {
    return Card(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primary.withValues(alpha: 0.1),
              AppColors.primary.withValues(alpha: 0.05),
            ],
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.star, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    habit.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${habit.completedCount}/${habit.repeatPerWeek} completions',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
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

  Widget _buildHabitProgressCard(HabitModel habit) {
    final progress = habit.repeatPerWeek > 0
        ? (habit.completedCount / habit.repeatPerWeek).clamp(0.0, 1.0)
        : 0.0;

    return InkWell(
      onTap: () => context.push('/home/habit', extra: habit),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      habit.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    '${habit.completedCount}/${habit.repeatPerWeek}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    progress >= 1.0 ? Colors.green : AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
