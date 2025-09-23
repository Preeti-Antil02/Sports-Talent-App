import 'package:flutter/material.dart';
import 'package:talenttrack/theme.dart';
import 'package:talenttrack/screens/auth/otp_login_screen.dart';
import 'package:talenttrack/screens/main_navigation_screen.dart';
import 'package:talenttrack/services/auth_service.dart';
import 'screens/live_metrics_page.dart';
void main() {
  runApp(const TalentTrackApp());
}

class TalentTrackApp extends StatelessWidget {
  const TalentTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TalentTrack',
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: ThemeMode.system,
      home: LiveMetricsPage(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: AuthService.isLoggedIn(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.data == true) {
          return const MainNavigationScreen();
        } else {
          return const OTPLoginScreen();
        }
      },
    );
  }
}
