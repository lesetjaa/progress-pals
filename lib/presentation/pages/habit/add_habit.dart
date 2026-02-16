import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:logger/web.dart';
import 'package:progress_pals/core/theme/theme_extensions.dart';
import 'package:progress_pals/data/datasources/local/database_service.dart';
import 'package:progress_pals/data/datasources/remote/firebase_service.dart';
import 'package:progress_pals/data/models/habit_model.dart';
import 'package:progress_pals/presentation/viewmodels/home_viewmodel.dart';
import 'package:progress_pals/presentation/widgets/app_button.dart';
import 'package:provider/provider.dart';

class AddHabitScreen extends StatefulWidget {
  final HabitModel? habit;

  const AddHabitScreen({super.key, this.habit});

  @override
  State<AddHabitScreen> createState() => _AddHabitScreenState();
}

class _AddHabitScreenState extends State<AddHabitScreen> {
  final DatabaseService _databaseService = DatabaseService();
  final FirebaseService _firebaseService = FirebaseService();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _shareWithController;
  int _repeatPerWeek = 1;
  final _formKey = GlobalKey<FormState>();
  HabitModel? _editingHabit;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _descriptionController = TextEditingController();
    _shareWithController = TextEditingController();

    // Check if we're editing a habit
    if (widget.habit != null) {
      _editingHabit = widget.habit;
      _nameController.text = widget.habit!.name;
      _descriptionController.text = widget.habit!.description;
      _repeatPerWeek = widget.habit!.repeatPerWeek;

      if (widget.habit!.sharedWith.isNotEmpty) {
        _shareWithController.text = widget.habit!.sharedWith.first;
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _shareWithController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (_formKey.currentState!.validate()) {
      final User? currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser == null) {
        Logger().e("Error: No user logged in!");
        return;
      }

      List<String> sharedWithList = [];
      final emailInput = _shareWithController.text.trim().toLowerCase();
      
      if (emailInput.isNotEmpty) {
        sharedWithList.add(emailInput);
      }

      if (_editingHabit != null) {
        // Update existing habit
        final updatedHabit = HabitModel(
          id: _editingHabit!.id,
          userId: _editingHabit!.userId,
          name: _nameController.text,
          description: _descriptionController.text,
          repeatPerWeek: _repeatPerWeek,
          completedCount: _editingHabit!.completedCount,
          lastCompletedDate: _editingHabit!.lastCompletedDate,
          lastResetDate: _editingHabit!.lastResetDate,
          sharedWith: sharedWithList,
          isSynced: false,
        );
        await _databaseService.updateHabit(updatedHabit);
      } else {
        // Create new habit
        final HabitModel habit = HabitModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          userId: currentUser.uid,
          name: _nameController.text,
          description: _descriptionController.text,
          repeatPerWeek: _repeatPerWeek,
          completedCount: 0,
          sharedWith: sharedWithList,
        );
        await _databaseService.insertHabit(habit);
        await _firebaseService.addHabit(habit);
        
      }

      // Refresh the habits list in HomeViewModel
      if (mounted) {
        final homeViewModel = context.read<HomeViewModel>();
        await homeViewModel.fetchHabits();
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.themeBackground,
      appBar: AppBar(
        backgroundColor: context.themeBackground,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.themeTextPrimary),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          _editingHabit != null ? 'Edit Habit' : 'Add New Habit',
          style: TextStyle(
            color: context.themeTextPrimary,
            fontSize: 28,
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name Field
                _buildFormLabel('Habit Name'),
                const SizedBox(height: 8),
                _buildTextFormField(
                  controller: _nameController,
                  hintText: 'e.g., Morning Meditation',
                  icon: Icons.lightbulb_outline,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a habit name';
                    }
                    if (value.length < 3) {
                      return 'Habit name must be at least 3 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Description Field
                _buildFormLabel('Description'),
                const SizedBox(height: 8),
                _buildTextFormField(
                  controller: _descriptionController,
                  hintText: 'What is this habit about?',
                  icon: Icons.description_outlined,
                  maxLines: 4,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a description';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Repeat Per Week Field
                _buildFormLabel('Repeat per Week'),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: context.themeSurface,
                    border: Border.all(color: context.themeDivider, width: 1.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.repeat, color: context.themeTextPrimary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButton<int>(
                          value: _repeatPerWeek,
                          isExpanded: true,
                          underline: const SizedBox(),
                          style: TextStyle(
                            color: context.themeTextPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                          items: List.generate(7, (index) => index + 1)
                              .map(
                                (day) => DropdownMenuItem(
                                  value: day,
                                  child: Text(
                                    '$day day${day > 1 ? 's' : ''} per week',
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            setState(() {
                              _repeatPerWeek = value ?? 1;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Share With Field
                _buildFormLabel('Share With (Optional)'),
                const SizedBox(height: 8),
                _buildTextFormField(
                  controller: _shareWithController,
                  hintText: 'Enter friend\'s email',
                  icon: Icons.person_add_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      // Simple email validation
                      if (!RegExp(
                        r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
                      ).hasMatch(value)) {
                        return 'Please enter a valid email';
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),

                // Submit Button
                AppButton(text: 'Create Habit', onPressed: _handleSubmit),
                const SizedBox(height: 16),

                // Cancel Button
                AppButton(
                  text: 'Cancel',
                  type: ButtonType.outline,
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormLabel(String label) {
    return Text(
      label,
      style: TextStyle(
        color: context.themeTextPrimary,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: context.themeTextDisabled),
        prefixIcon: Icon(icon, color: context.themeTextPrimary),
        filled: true,
        fillColor: context.themeSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: context.themeDivider, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: context.themeDivider, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: context.themeTextPrimary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: context.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: context.error, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        errorStyle: TextStyle(
          color: context.error,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
      style: TextStyle(color: context.themeTextPrimary, fontSize: 16),
    );
  }
}
