import 'package:flutter/material.dart';

/// Splash screen that displays the app logo while the app initializes
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color backgroundColor = isDark ? Colors.grey.shade900 : Colors.white;
    final Color primaryColor = isDark ? Colors.green.shade400 : Colors.green.shade700;
    final Color containerColor =
        isDark ? Colors.green.shade900.withOpacity(0.3) : Colors.green.shade50;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App logo
            Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                color: containerColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.2),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/icon/gersha.png',
                  width: 150,
                  height: 150,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    // Fallback if image doesn't exist - show app icon
                    return Container(
                      decoration: BoxDecoration(
                        color: containerColor,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.favorite,
                        size: 80,
                        color: primaryColor,
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 32),
            // App name
            Text(
              'GERSHA',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                    letterSpacing: 2,
                  ),
            ),
            const SizedBox(height: 24),
            // Loading indicator
            SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
