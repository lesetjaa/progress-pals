import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:progress_pals/core/theme/app_colors.dart';
import 'package:progress_pals/core/theme/theme_extensions.dart';
import 'package:progress_pals/presentation/widgets/app_button.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: screenHeight * 0.04, vertical: screenHeight * 0.02),
          child: Container(
            height: screenHeight,
            width: screenWidth,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: screenHeight * 0.05),
            
                // 1. Header Text
                Center(
                  child: Text(
                    'PROGRESS PALS!',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primary,
                      height: 1.1,
                      letterSpacing: -1.0,
                    ),
                  ),
                ),
            
                SizedBox(height: screenHeight * 0.02),
            
                // 2. Illustration
                Center(
                  child: SvgPicture.asset(
                    'assets/images/Login_page_image.svg',
                    height: screenHeight * 0.5,
                    fit: BoxFit.cover,
                  ),
                ),
            
                SizedBox(height: screenHeight * 0.05),

                 Center(
                  child: Text(
                    'Track Your Habits!',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                SizedBox(height: screenHeight * 0.01),
            
                Center(
                  child: Text(
                    'Complete, Connect, and Conquer Your Weekly Goals with Progress Pals!',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: context.themeTextDisabled
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                SizedBox(height: screenHeight * 0.03),

                AppButton(
                  text: 'Get Started',
                  type: ButtonType.primary,
                  onPressed: () {
                    context.push('/sign-in');
                  },
                ),

            
                SizedBox(height: screenHeight * 0.01),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
