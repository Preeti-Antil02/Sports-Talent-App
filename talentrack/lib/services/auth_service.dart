import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talenttrack/models/user_model.dart';
import 'package:talenttrack/services/storage_service.dart';

class AuthService {
  static const String _isLoggedInKey = 'is_logged_in';
  static const String _currentUserKey = 'current_user';
  static const String _otpKey = 'otp_code';

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isLoggedInKey) ?? false;
  }

  static Future<UserModel?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_currentUserKey);
    if (userJson != null) {
      return UserModel.fromMap(StorageService.jsonDecode(userJson));
    }
    return null;
  }

  static Future<String> generateOTP(String phoneNumber) async {
    final otp = (100000 + Random().nextInt(900000)).toString();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('${_otpKey}_$phoneNumber', otp);

    // In a real app, you would send this OTP via SMS
    // For demo purposes, we'll just return it
    return otp;
  }

  static Future<bool> verifyOTP(String phoneNumber, String otp, String name, String email, UserType userType) async {
    final prefs = await SharedPreferences.getInstance();
    final storedOTP = prefs.getString('${_otpKey}_$phoneNumber');

    if (storedOTP == otp) {
      // Create user
      final user = UserModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        phoneNumber: phoneNumber,
        name: name,
        email: email,
        userType: userType,
        createdAt: DateTime.now(),
        badges: _getInitialBadges(),
        totalScore: 0,
        skillScores: {},
      );

      // Save user
      await prefs.setBool(_isLoggedInKey, true);
      await prefs.setString(_currentUserKey, StorageService.jsonEncode(user.toMap()));
      await prefs.remove('${_otpKey}_$phoneNumber');

      return true;
    }
    return false;
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isLoggedInKey, false);
    await prefs.remove(_currentUserKey);
  }

  static List<String> _getInitialBadges() => [
    'Welcome to TalentTrack!',
    'First Steps',
  ];

  // Demo users for testing
  static final List<UserModel> demoUsers = [
    UserModel(
      id: 'user1',
      phoneNumber: '+1234567890',
      name: 'Alex Johnson',
      email: 'alex@example.com',
      userType: UserType.athlete,
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      badges: ['Speed Demon', 'Strength Master', 'Consistency King'],
      totalScore: 2850,
      skillScores: {'speed': 95, 'strength': 88, 'agility': 82, 'stamina': 76},
    ),
    UserModel(
      id: 'user2',
      phoneNumber: '+1234567891',
      name: 'Sarah Chen',
      email: 'sarah@example.com',
      userType: UserType.athlete,
      createdAt: DateTime.now().subtract(const Duration(days: 45)),
      badges: ['Flexibility Queen', 'Endurance Elite', 'Rising Star'],
      totalScore: 2720,
      skillScores: {'flexibility': 92, 'stamina': 85, 'coordination': 79, 'speed': 71},
    ),
    UserModel(
      id: 'user3',
      phoneNumber: '+1234567892',
      name: 'Marcus Rodriguez',
      email: 'marcus@example.com',
      userType: UserType.athlete,
      createdAt: DateTime.now().subtract(const Duration(days: 15)),
      badges: ['Agility Expert', 'Quick Learner'],
      totalScore: 2640,
      skillScores: {'agility': 89, 'coordination': 84, 'strength': 78, 'flexibility': 73},
    ),
  ];
}