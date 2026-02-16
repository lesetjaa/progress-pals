import 'package:flutter/material.dart';
import 'package:progress_pals/core/theme/theme_extensions.dart';
import 'package:progress_pals/data/datasources/local/database_service.dart';
import 'package:progress_pals/data/datasources/remote/firebase_service.dart';
import 'package:progress_pals/data/models/friend_model.dart';
import 'package:progress_pals/presentation/widgets/app_button.dart';
import 'package:uuid/uuid.dart';

class AddFriendScreen extends StatefulWidget {
  final FriendModel? friend;

  const AddFriendScreen({super.key, this.friend});

  @override
  State<AddFriendScreen> createState() => _AddFriendScreenState();
}

class _AddFriendScreenState extends State<AddFriendScreen> {
  final DatabaseService _databaseService = DatabaseService();
  final FirebaseService _firebaseService = FirebaseService();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  final _formKey = GlobalKey<FormState>();
  FriendModel? _editingFriend;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();

    // Check if we're editing a friend
    if (widget.friend != null) {
      _editingFriend = widget.friend;
      _nameController.text = widget.friend!.name;
      _emailController.text = widget.friend!.email;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void onAddFriendPressed() async {
    // Validate form first
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final emailToFind = _emailController.text.trim().toLowerCase();

    // 1. SEARCH FIRST
    final foundUserData = await _firebaseService.getUserByEmail(emailToFind);

    if (foundUserData == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User not found! Check the email.')),
        );
      }
      return;
    }

    final newFriend = FriendModel(
      id: const Uuid().v4(),
      userId: foundUserData['userId'],
      email: foundUserData['email'],
      name: foundUserData['displayName'] ?? 'Unknown',
      addedDate: DateTime.now(),
    );

    try {
      // Save to local database
      await _databaseService.insertFriend(newFriend);
      // Sync to Firebase
      await _firebaseService.addFriendToUser(newFriend);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${newFriend.name} added as friend!')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error adding friend: $e')));
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
          _editingFriend != null ? 'Edit Friend' : 'Add New Friend',
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
                // Email Field
                _buildFormLabel('Friend\'s Email'),
                const SizedBox(height: 8),
                _buildTextFormField(
                  controller: _emailController,
                  hintText: 'e.g., john@example.com',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter an email';
                    }
                    if (!RegExp(
                      r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
                    ).hasMatch(value)) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),

                // Submit Button
                AppButton(
                  text: _editingFriend != null ? 'Update Friend' : 'Add Friend',
                  onPressed: onAddFriendPressed,
                ),
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
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
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
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
