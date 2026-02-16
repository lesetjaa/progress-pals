import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:logger/web.dart';
import 'package:progress_pals/core/theme/theme_extensions.dart';
import 'package:progress_pals/core/theme/theme_provider.dart';
import 'package:progress_pals/data/datasources/local/database_service.dart';
import 'package:progress_pals/data/datasources/remote/firebase_service.dart';
import 'package:progress_pals/presentation/widgets/app_button.dart';
import 'package:provider/provider.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late User? _currentUser;
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _currentUser = FirebaseAuth.instance.currentUser;
  }

  Future<void> _syncData() async {
    setState(() => _isSyncing = true);
    try {
      final userId = _currentUser?.uid;
      if (userId != null) {
        final databaseService = context.read<DatabaseService>();
        await databaseService.syncAllData(userId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Data synced successfully!')),
          );
        }
      }
    } catch (e) {
      Logger().e('Error syncing data: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Sync failed: $e')));
      }
    }
    setState(() => _isSyncing = false);
  }

  Future<void> _updateDisplayName() async {
    final controller = TextEditingController(text: _currentUser?.displayName);

    final newName = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Update Display Name'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(labelText: 'Display Name'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (newName != null && newName.isNotEmpty) {
      try {
        await FirebaseService().updateUserDisplayName(newName);
        setState(() {
          _currentUser = FirebaseAuth.instance.currentUser;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Display name updated!')),
          );
        }
      } catch (e) {
        Logger().e('Error updating display name: $e');
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }

  Future<void> _logout() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                try {
                  final userId = _currentUser?.uid;
                  await FirebaseAuth.instance.signOut();

                  // Clear local data for this user
                  if (userId != null && mounted) {
                    final databaseService = context.read<DatabaseService>();
                    await databaseService.clearUserData(userId);
                  }

                  if (mounted) {
                    context.pushReplacement('/');
                  }
                } catch (e) {
                  Logger().e('Error logging out: $e');
                }
              },
              child: Text('Logout', style: TextStyle(color: context.error)),
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
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Profile Avatar
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: context.themeTextPrimary,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      _currentUser?.displayName?.isNotEmpty == true
                          ? _currentUser!.displayName![0].toUpperCase()
                          : _currentUser?.email?[0].toUpperCase() ?? 'U',
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color:context.themeTextPrimary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
        
                // User Email
                Text(
                  _currentUser?.email ?? 'No email',
                  style: TextStyle(
                    color: context.themeTextPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _currentUser?.displayName ?? 'User',
                      style: TextStyle(
                        color: context.themeTextSecondary,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.edit, size: 16),
                      onPressed: _updateDisplayName,
                      constraints: const BoxConstraints(
                        minHeight: 24,
                        minWidth: 24,
                      ),
                      padding: EdgeInsets.zero,
                    ),
                  ],
                ),
                const SizedBox(height: 32),
        
                // Account Info Section
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: context.themeSurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: context.themeDivider, width: 1.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                       Text(
                        'Account Information',
                        style: TextStyle(
                          color: context.themeTextPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildInfoRow(
                        'Email Verified',
                        _currentUser?.emailVerified == true ? 'Yes' : 'No',
                      ),
                      const SizedBox(height: 12),
                      _buildInfoRow(
                        'Account Created',
                        _currentUser?.metadata.creationTime?.toString().split(
                              ' ',
                            )[0] ??
                            'N/A',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
        
                // Preferences Section
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: context.themeSurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: context.themeDivider, width: 1.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Preferences',
                        style: TextStyle(
                          color: context.themeTextPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Dark Mode',
                            style: TextStyle(
                              color: context.themeTextPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Consumer<ThemeProvider>(
                            builder: (context, themeProvider, _) {
                              return Switch(
                                inactiveTrackColor: context.themeTextDisabled,
                                inactiveThumbColor: context.themeTextSecondary,
                                value: themeProvider.themeMode == ThemeMode.dark,
                                onChanged: (value) async {
                                  await themeProvider.setThemeMode(
                                    value ? ThemeMode.dark : ThemeMode.light,
                                  );
                                },
                                activeThumbColor: context.themeTextPrimary,
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
        
                // Sync Button
                _isSyncing
                    ? const Center(child: CircularProgressIndicator())
                    : AppButton(
                        text: 'Sync Data with Cloud',
                        onPressed: _syncData,
                      ),
                const SizedBox(height: 16),
        
                // Logout Button
                AppButton(
                  text: 'Logout',
                  type: ButtonType.outline,
                  onPressed: _logout,
                ),
                const SizedBox(height: 16),
        
                // Version Info
                Text(
                  'Version 1.0.0',
                  style: TextStyle(color: context.themeTextSecondary, fontSize: 12),
                ),
        
                // SizedBox(height: screenHeight * 0.15),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(color: context.themeTextSecondary, fontSize: 13),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              color: context.themeTextPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
