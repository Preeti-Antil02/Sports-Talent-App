import 'package:flutter/material.dart';
import 'theme.dart';
import 'screens/auth/otp_login_screen.dart';
import 'screens/main_navigation_screen.dart';
import 'services/auth_service.dart';

void main() {
  runApp(TalentTrackApp());
}

class TalentTrackApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TalentTrack',
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: ThemeMode.system,
      home: AuthWrapper(),   // ✅ show login OR main screen
    );
  }
}

class AuthWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: AuthService.isLoggedIn(), // 👈 check if user logged in
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        } else if (snapshot.hasData && snapshot.data == true) {
          return MainNavigationScreen(); // ✅ logged in
        } else {
          return OTPLoginScreen(); // ✅ not logged in
        }
      },
    );
  }
}
