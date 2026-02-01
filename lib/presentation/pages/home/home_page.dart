import 'package:dot_navigation_bar/dot_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:progress_pals/core/theme/app_colors.dart';
import 'package:progress_pals/core/theme/theme_extensions.dart';
import 'package:progress_pals/presentation/pages/home/home_content.dart';
import 'package:progress_pals/presentation/pages/friends/friends_page.dart';
import 'package:progress_pals/presentation/pages/analytics/analytics_page.dart';
import 'package:progress_pals/presentation/pages/profile/profile_page.dart';
import 'package:progress_pals/presentation/viewmodels/home_viewmodel.dart';
import 'package:provider/provider.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  static final List<Widget> _pages = [
    const HomeContent(),
    const FriendsPage(),
    const AnalyticsPage(),
    const ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    final homeViewModel = Provider.of<HomeViewModel>(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: context.themeTextDisabled,
      body: _pages[homeViewModel.selectedIndex],
      extendBody: true,
      bottomNavigationBar: DotNavigationBar(
        backgroundColor: AppColors.primary.withValues(alpha: 0.1),
        itemPadding: EdgeInsets.only(
          left: screenWidth * 0.04,
          right: screenWidth * 0.04,
          top: screenHeight * 0.017,
          bottom: screenHeight * 0.017,
        ),
        margin: const EdgeInsets.all(0),
        marginR: EdgeInsets.symmetric(horizontal: screenHeight * 0.05),
        paddingR: const EdgeInsets.all(0),
        currentIndex: homeViewModel.selectedIndex,
        onTap: homeViewModel.setIndex,
        items: [
          DotNavigationBarItem(
            icon: Icon(Icons.home),
            selectedColor: AppColors.primary,
            unselectedColor: context.themeTextSecondary,
          ),
          DotNavigationBarItem(
            icon: Icon(Icons.people),
            selectedColor: AppColors.primary,
            unselectedColor: context.themeTextSecondary,
          ),
          DotNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            selectedColor: AppColors.primary,
            unselectedColor: context.themeTextSecondary,
          ),
          DotNavigationBarItem(
            icon: Icon(Icons.person),
            selectedColor: AppColors.primary,
            unselectedColor: context.themeTextSecondary,
          ),
        ],
      ),
    );
  }
}
