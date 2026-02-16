import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:logger/logger.dart';
import 'package:progress_pals/data/datasources/remote/firebase_service.dart';
import 'package:progress_pals/data/models/habit_model.dart';
import 'package:progress_pals/data/models/friend_model.dart';
import 'package:progress_pals/presentation/pages/auth/welcome_page.dart';
import 'package:progress_pals/presentation/pages/habit/add_habit.dart';
import 'package:progress_pals/presentation/pages/habit/habit_detail_page.dart';
import 'package:progress_pals/presentation/pages/friends/add_friend.dart';
import 'package:progress_pals/presentation/pages/home/home_page.dart';
import 'package:progress_pals/presentation/pages/analytics/friend_analytics_page.dart';
import 'package:progress_pals/presentation/pages/profile/profile_page.dart';

final appRouter = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const WelcomePage(),
      routes: [
        GoRoute(
          path: 'sign-in',
          builder: (context, state) {
            return SignInScreen(
              providers: [EmailAuthProvider()],
              actions: [
                ForgotPasswordAction(((context, email) {
                  final uri = Uri(
                    path: '/sign-in/forgot-password',
                    queryParameters: <String, String?>{'email': email},
                  );
                  context.push(uri.toString());
                })),

                AuthStateChangeAction(((context, state) async {
                  final user = switch (state) {
                    SignedIn state => state.user,
                    UserCreated state => state.credential.user,
                    _ => null,
                  };
                  if (user == null) {
                    return;
                  }

                  // Ask for displayName if not set
                  if (user.displayName == null || user.displayName!.isEmpty) {
                    if (context.mounted) {
                      final displayName = await showDialog<String>(
                        context: context,
                        barrierDismissible: false,
                        builder: (BuildContext dialogContext) {
                          final controller = TextEditingController();
                          return AlertDialog(
                            title: const Text('Complete Your Profile'),
                            content: TextField(
                              controller: controller,
                              decoration: const InputDecoration(
                                hintText: 'Enter your name',
                                labelText: 'Display Name',
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(
                                  dialogContext,
                                  controller.text,
                                ),
                                child: const Text('Continue'),
                              ),
                            ],
                          );
                        },
                      );

                      if (displayName != null && displayName.isNotEmpty) {
                        await user.updateDisplayName(displayName);
                        await user.reload();
                      }
                    }
                  }

                  await FirebaseService().saveUserToFirestore(user);

                  // if (!user.emailVerified) {
                  //   // user.sendEmailVerification();
                  //   const snackBar = SnackBar(
                  //     content: Text(
                  //       'Please check your email to verify your email address',
                  //     ),
                  //   );
                  //   ScaffoldMessenger.of(context).showSnackBar(snackBar);
                  // }

                  if (context.mounted) {
                    context.pushReplacement('/home');
                  }
                })),
              ],
            );
          },
          routes: [
            GoRoute(
              path: 'forgot-password',
              builder: (context, state) {
                final arguments = state.uri.queryParameters;
                return ForgotPasswordScreen(
                  email: arguments['email'],
                  headerMaxExtent: 200,
                );
              },
            ),
          ],
        ),
        GoRoute(
          path: 'profile',
          builder: (context, state) {
            return ProfileScreen(
              providers: const [],
              actions: [
                SignedOutAction((context) {
                  context.pushReplacement('/');
                }),
              ],
            );
          },
        ),
        GoRoute(
          path: 'home',
          builder: (context, state) {
            return HomePage();
          },
          routes: [
            GoRoute(
              path: 'add-habit',
              builder: (context, state) {
                final habit = state.extra as HabitModel?;
                return AddHabitScreen(habit: habit);
              },
            ),
            GoRoute(
              path: 'add-friend',
              builder: (context, state) {
                final friend = state.extra as FriendModel?;
                return AddFriendScreen(friend: friend);
              },
            ),
            GoRoute(
              path: 'friend-analytics',
              builder: (context, state) {
                final friend = state.extra as FriendModel?;
                Logger().f(
                  "Navigating to analytics for friend: ${friend?.name}, ID: ${friend?.id}, userId: ${friend?.userId}",
                );
                return FriendAnalyticsPage(friend: friend);
              },
            ),
            GoRoute(
              path: 'habit',
              builder: (context, state) {
                final habit = state.extra as HabitModel?;
                return HabitDetailPage(habit: habit);
              },
            ),
            GoRoute(
              path: 'profile',
              builder: (context, state) {
                return const ProfilePage();
              },
            ),
          ],
        ),
      ],
    ),
  ],
);

// end of GoRouter configuration
